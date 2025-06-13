import 'package:flutter/material.dart';

class AwayModeCard extends StatelessWidget {
  final bool awayMode;
  final Function(bool) onChanged;

  const AwayModeCard({
    super.key,
    required this.awayMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SwitchListTile(
          value: awayMode,
          onChanged: onChanged,
          title: const Text('Chế độ vắng nhà', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(awayMode ? 'Đang bật' : 'Đang tắt'),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}