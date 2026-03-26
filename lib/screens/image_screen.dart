import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../services/model_router.dart';
import '../services/database_service.dart';
import '../models/app_state.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final _controller = TextEditingController();
  final _router = ModelRouter();
  final _db = DatabaseService();
  final _uuid = const Uuid();
  final List<_GeneratedImage> _images = [];
  bool _isGenerating = false;
  String? _error;

  final _styles = [
    'photorealistic',
    'digital art',
    'oil painting',
    'watercolor',
    'anime',
    '3D render',
    'pixel art',
    'sketch',
  ];
  String _selectedStyle = 'photorealistic';

  Future<void> _generate() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final styledPrompt = '$prompt, $_selectedStyle style, high quality, detailed';
      final bytes = await _router.generateImage(prompt: styledPrompt);
      if (mounted) {
        setState(() {
          _images.insert(0, _GeneratedImage(prompt: prompt, style: _selectedStyle, bytes: bytes));
          _isGenerating = false;
        });
        // Create a new chat with this image
        await _createChatWithImage(prompt, bytes);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _saveImage(Uint8List bytes, String prompt) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = 'shadow_hub_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createChatWithImage(String prompt, Uint8List bytes) async {
    try {
      // Save image to disk
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'ai_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Create new chat project
      final newId = _uuid.v4();
      final title = prompt.length > 40 ? '🎨 ${prompt.substring(0, 37)}...' : '🎨 $prompt';
      await _db.createProject(newId, title);

      // Insert user message (the prompt)
      await _db.insertMessage({
        'id': _uuid.v4(),
        'project_id': newId,
        'content': 'Generate image: $prompt ($_selectedStyle style)',
        'role': 'user',
        'mode': 'online',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Insert assistant message with image path
      await _db.insertMessage({
        'id': _uuid.v4(),
        'project_id': newId,
        'content': '![Generated Image](${file.path})',
        'role': 'assistant',
        'mode': 'online',
        'timestamp': DateTime.now().millisecondsSinceEpoch + 1,
        'model_used': 'image-gen',
      });

      // Navigate to the new chat
      AppState().activeProjectId.value = newId;
      AppState().currentTab.value = 0;
      AppState().refreshProjects();
    } catch (_) {
      // Silently fail — image is still shown in the grid
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Image Generation', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Style chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _styles.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final style = _styles[index];
                final isSelected = _selectedStyle == style;
                return ChoiceChip(
                  label: Text(style),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedStyle = style),
                  selectedColor: AppTheme.accent.withOpacity(0.2),
                  backgroundColor: AppTheme.surfaceAlt,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),
          SizedBox(height: 8),

          // Image grid
          Expanded(
            child: _images.isEmpty && !_isGenerating
                ? _buildEmptyState()
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _images.length + (_isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isGenerating && index == 0) {
                        return _buildLoadingTile();
                      }
                      final img = _images[_isGenerating ? index - 1 : index];
                      return _buildImageTile(img);
                    },
                  ),
          ),

          // Error
          if (_error != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12))),
                  GestureDetector(
                    onTap: () => setState(() => _error = null),
                    child: Icon(Icons.close, color: Colors.red, size: 14),
                  ),
                ],
              ),
            ),

          // Prompt input
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isGenerating,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Describe the image you want...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => _generate(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: IconButton(
                      icon: _isGenerating
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                          : Icon(Icons.auto_awesome, color: AppTheme.accent),
                      onPressed: _isGenerating ? null : _generate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [AppTheme.accentGlow, Colors.transparent]),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(Icons.image_outlined, color: AppTheme.accent, size: 36),
          ),
          SizedBox(height: 16),
          Text('Generate Images', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Describe what you want to see\nand pick a style above.', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            SizedBox(height: 12),
            Text('Generating...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(_GeneratedImage img) {
    return GestureDetector(
      onTap: () => _showFullImage(img),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
          image: DecorationImage(
            image: MemoryImage(img.bytes),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent.withOpacity(0.9), AppTheme.accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.open_in_full, color: Colors.white, size: 14),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(_GeneratedImage img) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.memory(img.bytes, fit: BoxFit.contain),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(img.prompt, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14), textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(img.style, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _saveImage(img.bytes, img.prompt),
                        icon: Icon(Icons.save_alt, size: 18),
                        label: Text('Save'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                      ),
                      SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Close'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedImage {
  final String prompt;
  final String style;
  final Uint8List bytes;
  _GeneratedImage({required this.prompt, required this.style, required this.bytes});
}
