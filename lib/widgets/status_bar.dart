import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  final bool isOnline;
  final AIMode selectedMode;

  const StatusBar({
    super.key,
    required this.isOnline,
    required this.selectedMode,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedMode == AIMode.offline) return SizedBox.shrink();
    if (isOnline && selectedMode == AIMode.online) return SizedBox.shrink();
    if (isOnline && selectedMode == AIMode.auto) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 4),
      color: AppTheme.offline.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 12, color: AppTheme.offline),
          SizedBox(width: 6),
          Text(
            'Offline Mode — Using Local LLM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.offline,
            ),
          )
        ],
      ),
    );
  }
}
