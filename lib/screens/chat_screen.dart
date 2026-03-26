import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../models/chat_message.dart';
import '../services/model_router.dart';
import '../services/connectivity_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/status_bar.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../models/app_state.dart';
import '../services/file_reader_service.dart';
import '../services/background_task_service.dart';

class ChatScreen extends StatefulWidget {
  final String projectId;
  const ChatScreen({super.key, this.projectId = 'default'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _router = ModelRouter();
  final _db = DatabaseService();
  final _connectivity = ConnectivityService();
  final _scrollController = ScrollController();
  final _uuid = Uuid();
  final _tts = TtsService();
  final _stt = SttService();
  final _bgService = BackgroundTaskService();

  List<ChatMessage> _messages = [];
  String _selectedModelId = 'auto';
  bool _isOnline = false;
  bool _isTyping = false;
  bool _isLoadingHistory = true;
  String? _errorMessage;
  String _memoryContext = '';
  Map<String, String> _downloadedOfflineModels = {};
  String? _activeMode; // quick action mode prefix
  bool _isListening = false;
  String? _speakingMsgId;
  List<PlatformFile> _pendingFiles = [];
  bool _chatRenamed = false;

  AIMode get _computedMode {
    if (_selectedModelId == 'auto') return AIMode.auto;
    if (_selectedModelId.contains('offline')) return AIMode.offline;
    return AIMode.online;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkConnectivity();
    _initTts();
    _scanDownloadedModels();
    _registerBackgroundCallbacks();
    _connectivity.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    _router.onModeChange = (from, to, reason) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reason),
            backgroundColor: AppTheme.surfaceAlt,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    };
  }

  void _registerBackgroundCallbacks() {
    _bgService.onTaskComplete = (projectId, message) {
      if (mounted && widget.projectId == projectId) {
        setState(() {
          _messages.add(message);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    };
    _bgService.onTaskError = (projectId, error) {
      if (mounted && widget.projectId == projectId) {
        setState(() {
          _isTyping = false;
          _errorMessage = error;
        });
      }
    };
  }

  void _initTts() {
    _stt.initialize();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _scrollController.dispose();
    // Don't clear callbacks — let background tasks finish and save to DB
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _isLoadingHistory = true);
    
    final projects = await _db.getProjects();
    final proj = projects.firstWhere((p) => p['id'] == widget.projectId, orElse: () => {'memory': ''});
    _memoryContext = proj['memory'] ?? '';

    final maps = await _db.getMessages(widget.projectId);
    final history = maps.map((m) => ChatMessage(
      id: m['id'],
      content: m['content'],
      role: m['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      mode: m['mode'] == 'online' ? AIMode.online : (m['mode'] == 'offline' ? AIMode.offline : AIMode.auto),
      timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp']),
      modelId: m['model_used'] as String?,
    )).toList();

    // Re-register callbacks for this project
    _registerBackgroundCallbacks();
    final hasPending = _bgService.hasPendingTask(widget.projectId);

    if (mounted) {
      setState(() {
        _messages = history;
        _chatRenamed = history.isNotEmpty;
        _isLoadingHistory = false;
        _isTyping = hasPending;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final online = await _connectivity.isOnline();
    if (mounted) setState(() => _isOnline = online);
  }

  // --- Attachment Options ---
  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
              ),
              Text('Attach', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Color(0xFF3B82F6),
                    onTap: () { Navigator.pop(ctx); _pickImage(fromCamera: true); },
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Photos',
                    color: Color(0xFF10B981),
                    onTap: () { Navigator.pop(ctx); _pickImage(fromCamera: false); },
                  ),
                  _AttachOption(
                    icon: Icons.description_rounded,
                    label: 'Document',
                    color: Color(0xFFF59E0B),
                    onTap: () { Navigator.pop(ctx); _pickDocument(); },
                  ),
                  _AttachOption(
                    icon: Icons.folder_rounded,
                    label: 'File',
                    color: Color(0xFF8B5CF6),
                    onTap: () { Navigator.pop(ctx); _pickAnyFile(); },
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() => _pendingFiles = result.files);
      }
    } catch (_) {
      // Not available
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'csv', 'xlsx', 'pptx', 'rtf'],
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() => _pendingFiles = result.files);
      }
    } catch (_) {
      // Not available
    }
  }

  Future<void> _pickAnyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() => _pendingFiles = result.files);
      }
    } catch (_) {
      // Not available
    }
  }

  // --- Speech to Text ---
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_stt.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input available on Android/iOS'),
            backgroundColor: AppTheme.surfaceAlt,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
      return;
    }
    setState(() => _isListening = true);
    await _stt.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          _sendMessage(text);
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  // --- Text to Speech ---
  Future<void> _toggleSpeak(ChatMessage msg) async {
    if (_speakingMsgId == msg.id) {
      await _tts.stop();
      if (mounted) setState(() => _speakingMsgId = null);
    } else {
      if (mounted) setState(() => _speakingMsgId = msg.id);
      await _tts.speak(msg.content);
      // After speech completes, reset state
      if (mounted) setState(() => _speakingMsgId = null);
    }
  }

  // --- Send Message ---
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Build the prompt with mode prefix and file context
    String prompt = text.trim();
    String? attachmentName;

    // Attach file content — read actual content from PDF, DOCX, XLSX, PPTX, images, text, etc.
    String? imageBase64;
    String? imageMime;
    if (_pendingFiles.isNotEmpty) {
      final file = _pendingFiles.first;
      attachmentName = file.name;
      final ext = file.extension?.toLowerCase() ?? '';
      final isImage = const {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'}.contains(ext);
      if (isImage && file.path != null) {
        // Image: encode as base64 for vision model analysis
        try {
          final bytes = await File(file.path!).readAsBytes();
          imageBase64 = base64Encode(bytes);
          imageMime = ext == 'png' ? 'image/png' : ext == 'gif' ? 'image/gif' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
        } catch (_) {
          prompt = '[Attached image: ${file.name} — could not read file]\n\n$prompt';
        }
      } else if (file.path != null) {
        // Document: extract text content
        final content = await FileReaderService.extractText(file.path!, ext);
        if (content != null && content.isNotEmpty) {
          final truncated = content.length > 8000 ? '${content.substring(0, 8000)}\n...(truncated, ${content.length} chars total)' : content;
          prompt = 'I have attached a file named "${file.name}":\n\n```\n$truncated\n```\n\n$prompt';
        } else {
          prompt = '[Attached file: ${file.name} (${ext.toUpperCase()}, ${(file.size / 1024).toStringAsFixed(1)} KB) — could not extract text content]\n\n$prompt';
        }
      } else {
        prompt = '[Attached file: ${file.name} (${ext.toUpperCase()}, ${(file.size / 1024).toStringAsFixed(1)} KB)]\n\n$prompt';
      }
      _pendingFiles = [];
    }

    // Add mode prefix for quick actions
    if (_activeMode != null) {
      prompt = '$_activeMode\n\n$prompt';
      _activeMode = null;
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text.trim(),
      role: MessageRole.user,
      mode: _computedMode,
      timestamp: DateTime.now(),
      attachment: attachmentName,
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    // Auto-rename chat based on first message
    if (!_chatRenamed && widget.projectId != 'default') {
      _chatRenamed = true;
      final title = text.trim().length > 40 ? '${text.trim().substring(0, 40)}...' : text.trim();
      await _db.updateProjectTitle(widget.projectId, title);
    }

    await _db.insertMessage({
      'id': userMsg.id,
      'project_id': widget.projectId,
      'content': userMsg.content,
      'role': 'user',
      'mode': _computedMode.name,
      'timestamp': userMsg.timestamp.millisecondsSinceEpoch,
    });

    // Capture values for background task (survives chat switch)
    final projectId = widget.projectId;
    final modelId = _selectedModelId;
    final mode = _computedMode;
    final memoryCtx = _memoryContext;

    // Check if this is an image generation request
    final lowerPrompt = prompt.toLowerCase();
    final isImageRequest = lowerPrompt.startsWith('image ');

    if (isImageRequest) {
      final imagePrompt = prompt.substring(6).trim();
      _bgService.generateImage(projectId: projectId, prompt: imagePrompt, modelId: modelId);
    } else if (imageBase64 != null && imageMime != null) {
      _bgService.analyzeImage(
        projectId: projectId,
        base64Image: imageBase64!,
        mimeType: imageMime!,
        userPrompt: prompt,
        modelId: modelId,
      );
    } else {
      var rawHistory = _messages.where((m) => !m.isLoading).take(_messages.length - 1).toList();
      var historyMessages = rawHistory.reversed.take(20).toList().reversed.toList();
      while (historyMessages.isNotEmpty && historyMessages.first.role == MessageRole.assistant) {
        historyMessages.removeAt(0);
      }
      final history = historyMessages.map((m) => {'role': m.role.name, 'content': m.content}).toList();

      _bgService.generateText(
        projectId: projectId,
        prompt: prompt,
        history: history,
        modelId: modelId,
        mode: mode,
        memoryContext: memoryCtx,
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearHistory() async {
    await _tts.stop();
    await _db.clearHistory(widget.projectId);
    setState(() {
      _messages.clear();
      _speakingMsgId = null;
      _chatRenamed = false;
    });
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          StatusBar(isOnline: _isOnline, selectedMode: _computedMode),
          Expanded(child: _buildMessageList()),
          if (_errorMessage != null) _buildErrorBanner(),
          if (_pendingFiles.isNotEmpty) _buildPendingFileBar(),
          ChatInput(
            onSend: _sendMessage,
            enabled: !_isTyping,
            onAttachFile: _showAttachMenu,
            onMicTap: _toggleListening,
            isListening: _isListening,
          ),
        ],
      ),
    );
  }

  static const _baseModels = <String, String>{
    'auto': 'Shadow AI (Auto)',
    // --- Fast & Reliable (confirmed working, low rate limits) ---
    'openrouter:google/gemma-3n-e2b-it:free': 'Gemma 3n 2B ⚡ (Free)',
    'openrouter:google/gemma-3n-e4b-it:free': 'Gemma 3n 4B (Free)',
    'openrouter:google/gemma-3-4b-it:free': 'Gemma 3 4B (Free)',
    'openrouter:liquid/lfm-2.5-1.2b-instruct:free': 'LiquidAI LFM 1.2B ⚡ (Free)',
    'openrouter:nvidia/nemotron-nano-9b-v2:free': 'Nemotron Nano 9B (Free)',
    // --- General Purpose ---
    'openrouter:arcee-ai/trinity-mini:free': 'Trinity Mini 26B (Free)',
    'openrouter:nvidia/nemotron-3-nano-30b-a3b:free': 'Nemotron 3 Nano 30B (Free)',
    'openrouter:z-ai/glm-4.5-air:free': 'GLM 4.5 Air (Free)',
    'openrouter:google/gemma-3-12b-it:free': 'Gemma 3 12B (Free)',
    'openrouter:google/gemma-3-27b-it:free': 'Gemma 3 27B (Free)',
    'openrouter:mistralai/mistral-small-3.1-24b-instruct:free': 'Mistral Small 3.1 (Free)',
    'openrouter:qwen/qwen3-4b:free': 'Qwen3 4B (Free)',
    // --- Powerful (larger, smarter) ---
    'openrouter:meta-llama/llama-3.3-70b-instruct:free': 'Llama 3.3 70B (Free)',
    'openrouter:qwen/qwen3-next-80b-a3b-instruct:free': 'Qwen3 Next 80B (Free)',
    'openrouter:nvidia/nemotron-3-super-120b-a12b:free': 'Nemotron 3 Super 120B (Free)',
    'openrouter:stepfun/step-3.5-flash:free': 'Step 3.5 Flash 196B (Free)',
    'openrouter:arcee-ai/trinity-large-preview:free': 'Trinity Large 400B (Free)',
    'openrouter:nousresearch/hermes-3-llama-3.1-405b:free': 'Hermes 3 405B (Free)',
    // --- Coding ---
    'openrouter:qwen/qwen3-coder:free': 'Qwen3 Coder (Free)',
    // --- Vision ---
    'openrouter:nvidia/nemotron-nano-12b-v2-vl:free': 'Nemotron 12B Vision (Free)',
    // --- Auto Router ---
    'openrouter:openrouter/free': 'Auto Router (Free)',
    // --- Unlimited ---
    'pollinations:openai': 'Pollinations (Unlimited)',
  };

  Map<String, String> get _models {
    final m = Map<String, String>.from(_baseModels);
    m.addAll(_downloadedOfflineModels);
    return m;
  }

  Future<void> _scanDownloadedModels() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final modelsDir = Directory('${appDir.path}${Platform.pathSeparator}models');
      if (!await modelsDir.exists()) return;
      final files = modelsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.gguf')).toList();
      if (files.isEmpty) return;
      final downloaded = <String, String>{};
      for (final f in files) {
        final name = f.uri.pathSegments.last.replaceAll('.gguf', '').replaceAll('_', ' ').replaceAll('-', ' ');
        final shortName = name.length > 30 ? '${name.substring(0, 27)}...' : name;
        downloaded['offline:${f.path}'] = '$shortName (Offline)';
      }
      if (mounted) setState(() => _downloadedOfflineModels = downloaded);
    } catch (_) {}
  }

  IconData _modelIcon(String key) {
    if (key == 'auto') return Icons.auto_awesome;
    if (key.contains('offline')) return Icons.download_done;
    if (key.contains('hermes')) return Icons.shield;
    if (key.contains('liquid') || key.contains('lfm')) return Icons.water_drop;
    if (key.contains('llama')) return Icons.local_fire_department;
    if (key.contains('mistral')) return Icons.air;
    if (key.contains('step-3.5') || key.contains('stepfun')) return Icons.flash_on;
    if (key.contains('glm')) return Icons.language;
    if (key.contains('gemma-3n')) return Icons.bolt;
    if (key.contains('gemma-3-27b')) return Icons.diamond;
    if (key.contains('gemma')) return Icons.blur_on;
    if (key.contains('nemotron-nano-12b') && key.contains('vl')) return Icons.visibility;
    if (key.contains('nemotron-nano') || key.contains('nemotron-3-nano')) return Icons.speed;
    if (key.contains('nemotron')) return Icons.memory;
    if (key.contains('coder')) return Icons.terminal;
    if (key.contains('qwen3-next')) return Icons.rocket_launch;
    if (key.contains('qwen3-4b')) return Icons.electric_bolt;
    if (key.contains('trinity-large')) return Icons.diamond_outlined;
    if (key.contains('trinity')) return Icons.change_history;
    if (key.contains('pollinations')) return Icons.eco;
    if (key.contains('openrouter/free')) return Icons.shuffle;
    return Icons.cloud_outlined;
  }

  Color _modelColor(String key) {
    if (key == 'auto') return const Color(0xFF8B5CF6);
    if (key.contains('offline')) return const Color(0xFF6B7280);
    if (key.contains('hermes')) return const Color(0xFF6D28D9);
    if (key.contains('liquid') || key.contains('lfm')) return const Color(0xFF00BCD4);
    if (key.contains('llama')) return const Color(0xFF3B82F6);
    if (key.contains('mistral')) return const Color(0xFFF97316);
    if (key.contains('step-3.5') || key.contains('stepfun')) return const Color(0xFF00C9FF);
    if (key.contains('glm')) return const Color(0xFF00B4D8);
    if (key.contains('gemma-3n')) return const Color(0xFF4CAF50);
    if (key.contains('gemma-3-27b')) return const Color(0xFF4285F4);
    if (key.contains('gemma')) return const Color(0xFF34A853);
    if (key.contains('nemotron-nano-12b') && key.contains('vl')) return const Color(0xFF00E676);
    if (key.contains('nemotron-nano') || key.contains('nemotron-3-nano')) return const Color(0xFF9ACD32);
    if (key.contains('nemotron')) return const Color(0xFF76B900);
    if (key.contains('coder')) return const Color(0xFFEC4899);
    if (key.contains('qwen3-next')) return const Color(0xFF7C3AED);
    if (key.contains('qwen3-4b')) return const Color(0xFF6366F1);
    if (key.contains('trinity-large')) return const Color(0xFFDC2626);
    if (key.contains('trinity')) return const Color(0xFFEF4444);
    if (key.contains('pollinations')) return const Color(0xFF22C55E);
    if (key.contains('openrouter/free')) return const Color(0xFF06B6D4);
    return const Color(0xFF64748B);
  }

  Widget _modelAvatar(String key) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _modelColor(key),
            _modelColor(key).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_modelIcon(key), size: 18, color: Colors.white),
    );
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      enableDrag: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.65,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 40, height: 4,
                    margin: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Select Model', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: ListView(
                    children: _models.entries.map((e) {
                      final isSelected = _selectedModelId == e.key;
                      return ListTile(
                        leading: _modelAvatar(e.key),
                        title: Text(e.value, style: TextStyle(
                          color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14,
                        )),
                        trailing: isSelected ? Icon(Icons.check_circle, color: AppTheme.accent, size: 20) : null,
                        onTap: () {
                          setState(() => _selectedModelId = e.key);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    final modelLabel = _models[_selectedModelId] ?? 'Shadow AI';
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: GestureDetector(
        onTap: _showModelPicker,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: AppTheme.online, shape: BoxShape.circle),
            ),
            SizedBox(width: 8),
            Text(modelLabel, style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 20),
            tooltip: 'Clear chat',
            onPressed: _clearHistory,
          ),
        IconButton(
          icon: Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 20),
          onPressed: () {},
        ),
        SizedBox(width: 4),
      ],
    );
  }

  Widget _buildPendingFileBar() {
    final file = _pendingFiles.first;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 18, color: AppTheme.accent),
          SizedBox(width: 8),
          Expanded(child: Text(file.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Text('${(file.size / 1024).toStringAsFixed(1)} KB', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _pendingFiles.clear()),
            child: Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoadingHistory) {
      return SizedBox.shrink();
    }
    if (_messages.isEmpty && !_isTyping) {
      return _buildWelcomeScreen();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return TypingIndicator();
        }
        final msg = _messages[index];
        return MessageBubble(
          message: msg,
          onSpeak: msg.role == MessageRole.assistant ? () => _toggleSpeak(msg) : null,
          isSpeaking: _speakingMsgId == msg.id,
          onFavorite: msg.role == MessageRole.assistant ? () {} : null,
        );
      },
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Shadow';
    if (hour < 17) return 'Good afternoon, Shadow';
    return 'Good evening, Shadow';
  }

  // --- ChatGPT-style welcome screen ---
  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // Sparkle icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              ),
              SizedBox(height: 24),
              Text(_greeting, style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold,
              )),
              SizedBox(height: 8),
              Text('How can I help you today?', style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 16,
              )),
              SizedBox(height: 40),

              // Quick Actions - 2 column grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2,
                children: [
                  _buildQuickChip(Icons.travel_explore, 'Deep Research',
                    'You are a deep research assistant. Analyze this topic thoroughly with multiple perspectives, detailed reasoning, and cite sources where possible:'),
                  _buildQuickChip(Icons.search, 'Web Search',
                    'You are a web search assistant. Provide up-to-date, factual information. Include relevant details, dates, and sources:'),
                  _buildQuickChip(Icons.school_outlined, 'Study & Learn',
                    'You are a study tutor. Explain this topic clearly with examples, key concepts, and memory aids:'),
                  _buildQuickChip(Icons.quiz_outlined, 'Quiz Me',
                    'You are a quiz master. Create a 5-question quiz about the following topic with multiple choice answers:'),
                  _buildQuickChip(Icons.code, 'Code Help',
                    'You are an expert programmer. Help with the following coding task. Provide clean, well-commented code:'),
                  _buildQuickChip(Icons.edit_note, 'Write',
                    'You are a skilled writer. Write the following with engaging prose, proper structure, and creative flair:'),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionDialog(String label, IconData icon, String systemPrompt) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppTheme.accent),
            ),
            SizedBox(width: 10),
            Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Enter your topic or question...',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.accent)),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              Navigator.pop(ctx);
              _activeMode = systemPrompt;
              _sendMessage(val.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _activeMode = systemPrompt;
                _sendMessage(controller.text.trim());
              }
            },
            child: Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(IconData icon, String label, String systemPrompt) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showQuickActionDialog(label, icon, systemPrompt),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 10),
              Expanded(child: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.offline.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.offline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.offline, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.offline, fontSize: 13))),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close, color: AppTheme.offline, size: 16),
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
