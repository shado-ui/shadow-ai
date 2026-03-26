import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final VoidCallback? onAttachFile;
  final VoidCallback? onMicTap;
  final bool isListening;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.onAttachFile,
    this.onMicTap,
    this.isListening = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border.withOpacity(0.5)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // + attach button
                Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 4),
                  child: IconButton(
                    icon: Icon(Icons.add, color: AppTheme.textSecondary, size: 22),
                    onPressed: widget.onAttachFile,
                    tooltip: 'Attach',
                    splashRadius: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
                // Text field
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _handleSend();
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLines: 6,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.fromLTRB(4, 14, 4, 14),
                      ),
                    ),
                  ),
                ),
                // Right side icons
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    final hasText = value.text.trim().isNotEmpty;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hasText) ...[
                            IconButton(
                              icon: Icon(Icons.attach_file, color: AppTheme.textSecondary, size: 20),
                              onPressed: widget.onAttachFile,
                              splashRadius: 18,
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(minWidth: 34, minHeight: 34),
                              tooltip: 'Attach file',
                            ),
                            IconButton(
                              icon: Icon(
                                widget.isListening ? Icons.stop_circle : Icons.mic_none,
                                color: widget.isListening ? Colors.red : AppTheme.textSecondary,
                                size: 20,
                              ),
                              onPressed: widget.onMicTap,
                              splashRadius: 18,
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(minWidth: 34, minHeight: 34),
                              tooltip: 'Voice input',
                            ),
                          ],
                          // Send button
                          Container(
                            decoration: BoxDecoration(
                              gradient: hasText && widget.enabled
                                  ? AppTheme.getAccentGradient()
                                  : null,
                              color: hasText && widget.enabled ? null : AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: hasText && widget.enabled ? [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: hasText && widget.enabled ? _handleSend : null,
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: hasText && widget.enabled
                                        ? Colors.white
                                        : AppTheme.textSecondary.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Disclaimer
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'AI can make mistakes. Check important info.',
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
