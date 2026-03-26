import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/model_router.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final _controller = TextEditingController();
  final _router = ModelRouter();
  final List<_GeneratedVideo> _videos = [];
  bool _isGenerating = false;
  String? _error;

  Future<void> _generate() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final bytes = await _router.generateVideo(prompt: prompt);
      // Save to temp file for playback
      final dir = await getApplicationDocumentsDirectory();
      final name = 'shadow_vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _videos.insert(0, _GeneratedVideo(prompt: prompt, filePath: file.path, bytes: bytes));
          _isGenerating = false;
        });
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
        title: Text('Video Generation', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Video generation uses ModelsLab API. Sign up free at modelslab.com, get your API key, and add it in Settings.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Videos list
          Expanded(
            child: _videos.isEmpty && !_isGenerating
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _videos.length + (_isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isGenerating && index == 0) return _buildLoadingCard();
                      final vid = _videos[_isGenerating ? index - 1 : index];
                      return _buildVideoCard(vid);
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
                        hintText: 'Describe the video scene...',
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
                          : Icon(Icons.movie_creation_outlined, color: AppTheme.accent),
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
            child: Icon(Icons.movie_outlined, color: AppTheme.accent, size: 36),
          ),
          SizedBox(height: 16),
          Text('Generate Videos', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Describe a scene and the AI\nwill generate a short video clip.', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            SizedBox(height: 14),
            Text('Generating video...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(height: 4),
            Text('This may take up to 60 seconds', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(_GeneratedVideo vid) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.videocam, color: AppTheme.accent, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vid.prompt, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2),
                      Text('Saved: ${vid.filePath.split('/').last}',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.online, size: 16),
                SizedBox(width: 6),
                Text('Video saved to device', style: TextStyle(color: AppTheme.online, fontSize: 12, fontWeight: FontWeight.w500)),
                Spacer(),
                Text('${(vid.bytes.length / 1024).toStringAsFixed(0)} KB',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedVideo {
  final String prompt;
  final String filePath;
  final Uint8List bytes;
  _GeneratedVideo({required this.prompt, required this.filePath, required this.bytes});
}
