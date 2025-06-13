import 'package:flutter/material.dart';
import '../models/access_log.dart';
import '../utils/date_utils.dart';

class LogsSection extends StatelessWidget {
  final List<AccessLog> logs;

  const LogsSection({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch sử truy cập', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: logs.isEmpty
                  ? const Center(child: Text('Chưa có log truy cập nào', style: TextStyle(fontSize: 14)))
                  : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: Icon(
                      log.success ? Icons.lock_open : Icons.lock,
                      color: log.success ? Colors.green : Colors.red,
                    ),
                    title: Text('Log: ${log.method}'),
                    subtitle: Text('Lúc: ${AppDateUtils.formatTimestamp(log.timestamp)}'),
                    trailing: Text(log.success ? '✔️' : '❌'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}