import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _OfflineModel {
  final String id;
  final String name;
  final String description;
  final String size;
  final String ramNeeded;
  final String url;
  final String filename;
  final IconData icon;
  final Color color;
  final List<String> tags;

  const _OfflineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.size,
    required this.ramNeeded,
    required this.url,
    required this.filename,
    required this.icon,
    required this.color,
    required this.tags,
  });
}

class _ModelsScreenState extends State<ModelsScreen> {
  final _db = DatabaseService();
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadedModels = {};
  String? _activeModelPath;
  String _selectedCategory = 'All';

  static const _models = <_OfflineModel>[
    _OfflineModel(
      id: 'tinyllama-1.1b',
      name: 'TinyLlama 1.1B',
      description: 'Ultra-lightweight model. Fast responses, low RAM. Great for basic Q&A and simple tasks.',
      size: '670 MB',
      ramNeeded: '2 GB RAM',
      url: 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
      filename: 'tinyllama-1.1b-chat-Q4_K_M.gguf',
      icon: Icons.bolt,
      color: Color(0xFF10B981),
      tags: ['Tiny', 'Fast', 'Chat'],
    ),
    _OfflineModel(
      id: 'phi-3-mini',
      name: 'Phi-3 Mini 3.8B',
      description: 'Microsoft\'s compact powerhouse. Excellent reasoning for its size. Best quality-to-size ratio.',
      size: '2.3 GB',
      ramNeeded: '4 GB RAM',
      url: 'https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF/resolve/main/Phi-3-mini-4k-instruct-Q4_K_M.gguf',
      filename: 'phi-3-mini-4k-instruct-Q4_K_M.gguf',
      icon: Icons.psychology,
      color: Color(0xFF6366F1),
      tags: ['Compact', 'Smart', 'Reasoning'],
    ),
    _OfflineModel(
      id: 'gemma-2-2b',
      name: 'Gemma 2 2B',
      description: 'Google\'s efficient model. Strong at following instructions and generating clean responses.',
      size: '1.5 GB',
      ramNeeded: '3 GB RAM',
      url: 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf',
      filename: 'gemma-2-2b-it-Q4_K_M.gguf',
      icon: Icons.auto_awesome,
      color: Color(0xFF3B82F6),
      tags: ['Google', 'Compact', 'Chat'],
    ),
    _OfflineModel(
      id: 'llama-3.2-3b',
      name: 'Llama 3.2 3B',
      description: 'Meta\'s latest compact model. Great balance of speed and intelligence. Recommended starter.',
      size: '2.0 GB',
      ramNeeded: '4 GB RAM',
      url: 'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
      filename: 'llama-3.2-3b-instruct-Q4_K_M.gguf',
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444),
      tags: ['Meta', 'Recommended', 'Chat'],
    ),
    _OfflineModel(
      id: 'mistral-7b',
      name: 'Mistral 7B v0.3',
      description: 'Speed demon. 20% faster than Llama with similar quality. Great for quick queries and creative writing.',
      size: '4.4 GB',
      ramNeeded: '8 GB RAM',
      url: 'https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf',
      filename: 'mistral-7b-instruct-v0.3-Q4_K_M.gguf',
      icon: Icons.speed,
      color: Color(0xFFF59E0B),
      tags: ['Fast', 'Creative', '7B'],
    ),
    _OfflineModel(
      id: 'qwen-2.5-7b',
      name: 'Qwen 2.5 7B',
      description: 'Alibaba\'s multilingual model. Supports English, Chinese, Spanish & more. Strong reasoning.',
      size: '4.7 GB',
      ramNeeded: '8 GB RAM',
      url: 'https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf',
      filename: 'qwen-2.5-7b-instruct-Q4_K_M.gguf',
      icon: Icons.translate,
      color: Color(0xFF8B5CF6),
      tags: ['Multilingual', 'Smart', '7B'],
    ),
    _OfflineModel(
      id: 'deepseek-coder-6.7b',
      name: 'DeepSeek Coder 6.7B',
      description: 'Specialized coding assistant. Supports 30+ programming languages. Great for dev work offline.',
      size: '3.8 GB',
      ramNeeded: '8 GB RAM',
      url: 'https://huggingface.co/TheBloke/deepseek-coder-6.7B-instruct-GGUF/resolve/main/deepseek-coder-6.7b-instruct.Q4_K_M.gguf',
      filename: 'deepseek-coder-6.7b-instruct-Q4_K_M.gguf',
      icon: Icons.code,
      color: Color(0xFFEC4899),
      tags: ['Coding', 'Developer', '7B'],
    ),
    _OfflineModel(
      id: 'llama-3.3-8b',
      name: 'Llama 3.3 8B',
      description: 'The gold standard. Most consistently useful answers. Replaces ChatGPT for most tasks.',
      size: '4.9 GB',
      ramNeeded: '8 GB RAM',
      url: 'https://huggingface.co/bartowski/Meta-Llama-3.3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.3-8B-Instruct-Q4_K_M.gguf',
      filename: 'llama-3.3-8b-instruct-Q4_K_M.gguf',
      icon: Icons.star,
      color: Color(0xFFD946EF),
      tags: ['Best', 'Meta', '8B'],
    ),
    _OfflineModel(
      id: 'dolphin-2.6-7b',
      name: 'Dolphin 2.6 7B',
      description: 'Creative and open assistant. Handles all topics freely with no restrictions. Great for roleplay & writing.',
      size: '4.4 GB',
      ramNeeded: '8 GB RAM',
      url: 'https://huggingface.co/TheBloke/dolphin-2.6-mistral-7B-GGUF/resolve/main/dolphin-2.6-mistral-7b.Q4_K_M.gguf',
      filename: 'dolphin-2.6-mistral-7b-Q4_K_M.gguf',
      icon: Icons.water,
      color: Color(0xFFE11D48),
      tags: ['Creative', '7B', 'Chat'],
    ),
  ];

  static const _categories = ['All', 'Tiny', 'Compact', '7B', '8B', 'Coding', 'Creative'];

  @override
  void initState() {
    super.initState();
    _checkDownloaded();
    _loadActiveModel();
  }

  Future<String> get _modelsDir async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}${Platform.pathSeparator}models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> _loadActiveModel() async {
    final path = await _db.getSetting('local_gguf_path');
    if (mounted) setState(() => _activeModelPath = path);
  }

  Future<void> _checkDownloaded() async {
    final dir = await _modelsDir;
    for (final model in _models) {
      final file = File('$dir${Platform.pathSeparator}${model.filename}');
      if (await file.exists()) {
        if (mounted) setState(() => _downloadedModels[model.id] = true);
      }
    }
  }

  Future<void> _downloadModel(_OfflineModel model) async {
    if (_downloadProgress.containsKey(model.id)) return; // Already downloading

    setState(() => _downloadProgress[model.id] = 0.0);

    try {
      final dir = await _modelsDir;
      final filePath = '$dir${Platform.pathSeparator}${model.filename}';
      final file = File(filePath);

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(model.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() => _downloadProgress[model.id] = receivedBytes / totalBytes);
        }
      }
      await sink.close();
      client.close();

      if (mounted) {
        setState(() {
          _downloadProgress.remove(model.id);
          _downloadedModels[model.id] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} downloaded successfully!'),
            backgroundColor: AppTheme.online,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(model.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: AppTheme.offline,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _activateModel(_OfflineModel model) async {
    final dir = await _modelsDir;
    final filePath = '$dir${Platform.pathSeparator}${model.filename}';
    await _db.saveSetting('local_gguf_path', filePath);
    if (mounted) {
      setState(() => _activeModelPath = filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${model.name} set as active offline model'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _deleteModel(_OfflineModel model) async {
    final dir = await _modelsDir;
    final filePath = '$dir${Platform.pathSeparator}${model.filename}';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    if (_activeModelPath == filePath) {
      await _db.saveSetting('local_gguf_path', '');
      _activeModelPath = null;
    }
    if (mounted) {
      setState(() => _downloadedModels.remove(model.id));
    }
  }

  List<_OfflineModel> get _filteredModels {
    List<_OfflineModel> list;
    if (_selectedCategory == 'All') {
      list = List.of(_models);
    } else {
      list = _models.where((m) => m.tags.any((t) => t.toLowerCase().contains(_selectedCategory.toLowerCase()))).toList();
    }
    // Downloaded models always appear at the top
    list.sort((a, b) {
      final aDown = _downloadedModels[a.id] == true ? 0 : 1;
      final bDown = _downloadedModels[b.id] == true ? 0 : 1;
      return aDown.compareTo(bDown);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Offline Models', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_downloadedModels.length} downloaded',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) {
                final isActive = _selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat, style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w500,
                    )),
                    selected: isActive,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.accent,
                    side: BorderSide(color: isActive ? AppTheme.accent : AppTheme.border),
                    showCheckmark: false,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 8),

          // Info banner
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download GGUF models to chat offline without internet. Models are stored locally on your device.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          // Model list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredModels.length,
              itemBuilder: (context, index) => _buildModelCard(_filteredModels[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(_OfflineModel model) {
    final isDownloaded = _downloadedModels[model.id] == true;
    final isDownloading = _downloadProgress.containsKey(model.id);
    final progress = _downloadProgress[model.id] ?? 0.0;
    final isActive = _activeModelPath?.contains(model.filename) == true;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: model.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(model.icon, size: 20, color: model.color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(model.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          if (isActive) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(4)),
                              child: Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Text(model.size, style: TextStyle(color: model.color, fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('  •  ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          Text(model.ramNeeded, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action button
                if (isDownloading)
                  SizedBox(
                    width: 38, height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
                          color: AppTheme.accent,
                          backgroundColor: AppTheme.border,
                        ),
                        Text('${(progress * 100).toInt()}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else if (isDownloaded)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
                    color: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'activate') _activateModel(model);
                      if (val == 'delete') _deleteModel(model);
                    },
                    itemBuilder: (ctx) => [
                      if (!isActive)
                        PopupMenuItem(value: 'activate', child: Row(children: [
                          Icon(Icons.play_arrow, size: 18, color: AppTheme.accent), SizedBox(width: 8),
                          Text('Set Active', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        ])),
                      PopupMenuItem(value: 'delete', child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ])),
                    ],
                  )
                else
                  Material(
                    color: model.color,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _downloadModel(model),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Get', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(model.description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
            SizedBox(height: 8),
            // Tags
            Wrap(
              spacing: 6,
              children: model.tags.map((tag) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              )).toList(),
            ),
            // Download progress bar
            if (isDownloading) ...[
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.border,
                ),
              ),
              SizedBox(height: 4),
              Text('Downloading... ${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
            // Downloaded indicator
            if (isDownloaded && !isDownloading) ...[
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppTheme.online),
                  SizedBox(width: 4),
                  Text('Downloaded', style: TextStyle(color: AppTheme.online, fontSize: 11, fontWeight: FontWeight.w500)),
                  if (isActive) ...[
                    Text('  •  ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text('Currently active', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
