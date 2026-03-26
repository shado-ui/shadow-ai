import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ModeSelector extends StatelessWidget {
  final AIMode selected;
  final ValueChanged<AIMode> onChanged;

  const ModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ModeChip(
            label: 'Auto',
            icon: Icons.bolt,
            mode: AIMode.auto,
            color: AppTheme.auto_,
            selected: selected == AIMode.auto,
            onTap: () => onChanged(AIMode.auto),
          ),
          SizedBox(width: 8),
          _ModeChip(
            label: 'Online',
            icon: Icons.wifi,
            mode: AIMode.online,
            color: AppTheme.online,
            selected: selected == AIMode.online,
            onTap: () => onChanged(AIMode.online),
          ),
          SizedBox(width: 8),
          _ModeChip(
            label: 'Offline',
            icon: Icons.wifi_off,
            mode: AIMode.offline,
            color: AppTheme.offline,
            selected: selected == AIMode.offline,
            onTap: () => onChanged(AIMode.offline),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final AIMode mode;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.mode,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 14),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
