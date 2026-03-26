import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onFavorite;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const MessageBubble({
    super.key,
    required this.message,
    this.onFavorite,
    this.onSpeak,
    this.isSpeaking = false,
  });

  static const _modelNames = <String, String>{
    'auto': 'Shadow AI',
    // Fast & Reliable
    'openrouter:google/gemma-3n-e2b-it:free': 'Gemma 3n 2B',
    'openrouter:google/gemma-3n-e4b-it:free': 'Gemma 3n 4B',
    'openrouter:google/gemma-3-4b-it:free': 'Gemma 3 4B',
    'openrouter:liquid/lfm-2.5-1.2b-instruct:free': 'LiquidAI LFM',
    'openrouter:nvidia/nemotron-nano-9b-v2:free': 'Nemotron Nano 9B',
    // General
    'openrouter:arcee-ai/trinity-mini:free': 'Trinity Mini',
    'openrouter:nvidia/nemotron-3-nano-30b-a3b:free': 'Nemotron 3 Nano 30B',
    'openrouter:z-ai/glm-4.5-air:free': 'GLM 4.5 Air',
    'openrouter:google/gemma-3-12b-it:free': 'Gemma 3 12B',
    'openrouter:google/gemma-3-27b-it:free': 'Gemma 3 27B',
    'openrouter:mistralai/mistral-small-3.1-24b-instruct:free': 'Mistral 3.1',
    'openrouter:qwen/qwen3-4b:free': 'Qwen3 4B',
    // Powerful
    'openrouter:meta-llama/llama-3.3-70b-instruct:free': 'Llama 3.3 70B',
    'openrouter:qwen/qwen3-next-80b-a3b-instruct:free': 'Qwen3 Next 80B',
    'openrouter:nvidia/nemotron-3-super-120b-a12b:free': 'Nemotron 3 Super 120B',
    'openrouter:stepfun/step-3.5-flash:free': 'Step 3.5 Flash',
    'openrouter:arcee-ai/trinity-large-preview:free': 'Trinity Large',
    'openrouter:nousresearch/hermes-3-llama-3.1-405b:free': 'Hermes 3 405B',
    // Coding
    'openrouter:qwen/qwen3-coder:free': 'Qwen3 Coder',
    // Vision
    'openrouter:nvidia/nemotron-nano-12b-v2-vl:free': 'Nemotron 12B Vision',
    // Auto Router
    'openrouter:openrouter/free': 'Auto Router',
    // Unlimited
    'pollinations:openai': 'Pollinations',
  };

  String _getModelName() {
    final mid = message.modelId ?? 'auto';
    if (_modelNames.containsKey(mid)) return _modelNames[mid]!;
    if (mid.contains('offline')) {
      final parts = mid.replaceFirst('offline:', '').split(RegExp(r'[/\\]'));
      final filename = parts.last.replaceAll('.gguf', '').replaceAll('-', ' ').replaceAll('_', ' ');
      return filename.length > 20 ? '${filename.substring(0, 17)}...' : filename;
    }
    return 'AI';
  }

  IconData _getModelIcon() {
    final mid = message.modelId ?? 'auto';
    if (mid == 'auto') return Icons.auto_awesome;
    if (mid.contains('offline')) return Icons.download_done;
    if (mid.contains('hermes')) return Icons.shield;
    if (mid.contains('liquid') || mid.contains('lfm')) return Icons.water_drop;
    if (mid.contains('llama')) return Icons.local_fire_department;
    if (mid.contains('mistral')) return Icons.air;
    if (mid.contains('step-3.5') || mid.contains('stepfun')) return Icons.flash_on;
    if (mid.contains('glm')) return Icons.language;
    if (mid.contains('gemma-3n')) return Icons.bolt;
    if (mid.contains('gemma-3-27b')) return Icons.diamond;
    if (mid.contains('gemma')) return Icons.blur_on;
    if (mid.contains('nemotron-nano-12b') && mid.contains('vl')) return Icons.visibility;
    if (mid.contains('nemotron-nano') || mid.contains('nemotron-3-nano')) return Icons.speed;
    if (mid.contains('nemotron')) return Icons.memory;
    if (mid.contains('coder')) return Icons.terminal;
    if (mid.contains('qwen3-next')) return Icons.rocket_launch;
    if (mid.contains('qwen3-4b')) return Icons.electric_bolt;
    if (mid.contains('trinity-large')) return Icons.diamond_outlined;
    if (mid.contains('trinity')) return Icons.change_history;
    if (mid.contains('pollinations')) return Icons.eco;
    if (mid.contains('openrouter/free')) return Icons.shuffle;
    return Icons.smart_toy;
  }

  Color _getModelColor() {
    final mid = message.modelId ?? 'auto';
    if (mid == 'auto') return const Color(0xFF8B5CF6);
    if (mid.contains('offline')) return const Color(0xFF6B7280);
    if (mid.contains('hermes')) return const Color(0xFF6D28D9);
    if (mid.contains('liquid') || mid.contains('lfm')) return const Color(0xFF00BCD4);
    if (mid.contains('llama')) return const Color(0xFF3B82F6);
    if (mid.contains('mistral')) return const Color(0xFFF97316);
    if (mid.contains('step-3.5') || mid.contains('stepfun')) return const Color(0xFF00C9FF);
    if (mid.contains('glm')) return const Color(0xFF00B4D8);
    if (mid.contains('gemma-3n')) return const Color(0xFF4CAF50);
    if (mid.contains('gemma-3-27b')) return const Color(0xFF4285F4);
    if (mid.contains('gemma')) return const Color(0xFF34A853);
    if (mid.contains('nemotron-nano-12b') && mid.contains('vl')) return const Color(0xFF00E676);
    if (mid.contains('nemotron-nano') || mid.contains('nemotron-3-nano')) return const Color(0xFF9ACD32);
    if (mid.contains('nemotron')) return const Color(0xFF76B900);
    if (mid.contains('coder')) return const Color(0xFFEC4899);
    if (mid.contains('qwen3-next')) return const Color(0xFF7C3AED);
    if (mid.contains('qwen3-4b')) return const Color(0xFF6366F1);
    if (mid.contains('trinity-large')) return const Color(0xFFDC2626);
    if (mid.contains('trinity')) return const Color(0xFFEF4444);
    if (mid.contains('pollinations')) return const Color(0xFF22C55E);
    if (mid.contains('openrouter/free')) return const Color(0xFF06B6D4);
    return const Color(0xFF64748B);
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Copied to clipboard'),
        ]),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _shareMessage() {
    Share.share(message.content, subject: 'Shadow AI Response');
  }

  bool _isImageMessage() {
    return message.content.startsWith('![') && message.content.contains('](');
  }

  String? _extractImagePath() {
    if (!_isImageMessage()) return null;
    final start = message.content.indexOf('](') + 2;
    final end = message.content.indexOf(')', start);
    if (start < 2 || end < 0) return null;
    return message.content.substring(start, end);
  }

  Widget _buildMessageContent(bool isUser) {
    final imagePath = _extractImagePath();
    final isImage = imagePath != null && File(imagePath).existsSync();

    if (isImage) {
      // Render image message
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              padding: EdgeInsets.all(16),
              color: AppTheme.surfaceAlt,
              child: Row(
                children: [
                  Icon(Icons.broken_image, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text('Image not found', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Normal text message
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [AppTheme.accent.withOpacity(0.15), AppTheme.accent.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser ? null : AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 18 : 4),
          topRight: Radius.circular(isUser ? 4 : 18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: isUser ? AppTheme.accent.withOpacity(0.3) : AppTheme.border,
          width: isUser ? 1.5 : 1,
        ),
        boxShadow: isUser
            ? [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: MarkdownBody(
        data: message.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.6),
          code: TextStyle(
            backgroundColor: AppTheme.surfaceAlt,
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppTheme.accent,
          ),
          codeblockDecoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          codeblockPadding: EdgeInsets.all(12),
          h1: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          h2: TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.bold),
          h3: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          listBullet: TextStyle(color: AppTheme.textSecondary),
          blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: AppTheme.accent, width: 3)),
            color: AppTheme.surfaceAlt,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getModelColor(), _getModelColor().withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getModelIcon(), color: Colors.white, size: 16),
            ),
            SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      _getModelName(),
                      style: TextStyle(
                        color: _getModelColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // Attachment indicator
                if (message.attachment != null) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: 6),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 14, color: AppTheme.accent),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.attachment!,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Message bubble
                _buildMessageContent(isUser),
                // Action buttons row for AI replies
                if (!isUser) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionBtn(icon: Icons.copy_rounded, label: 'Copy', onTap: () => _copyToClipboard(context)),
                        SizedBox(width: 2),
                        _ActionBtn(
                          icon: isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                          label: isSpeaking ? 'Stop' : 'Read',
                          onTap: onSpeak,
                          isActive: isSpeaking,
                        ),
                        SizedBox(width: 2),
                        _ActionBtn(icon: Icons.share_rounded, label: 'Share', onTap: _shareMessage),
                        SizedBox(width: 2),
                        if (onFavorite != null)
                          _ActionBtn(icon: Icons.star_border_rounded, label: 'Save', onTap: onFavorite!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ActionBtn({required this.icon, required this.label, this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isActive ? AppTheme.accent : AppTheme.textSecondary.withOpacity(0.7)),
              SizedBox(width: 3),
              Text(label, style: TextStyle(
                fontSize: 11,
                color: isActive ? AppTheme.accent : AppTheme.textSecondary.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
