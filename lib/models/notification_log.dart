// lib/models/notification_log.dart
import 'package:intl/intl.dart';

class NotificationLog {
  final String id;
  final String title;
  final String body;
  final String method;
  final bool success;
  final int logTimestamp; // Timestamp của access log gốc
  final int notificationTimestamp; // Timestamp khi thông báo được gửi

  NotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.method,
    required this.success,
    required this.logTimestamp,
    required this.notificationTimestamp,
  });

  factory NotificationLog.fromMap(String id, Map<dynamic, dynamic> map) {
    return NotificationLog(
      id: id,
      title: map['title'] as String? ?? 'Thông báo',
      body: map['body'] as String? ?? 'Nội dung trống',
      method: map['method'] as String? ?? 'N/A',
      success: map['success'] as bool? ?? false,
      logTimestamp: map['logTimestamp'] as int? ?? 0,
      notificationTimestamp: map['notificationTimestamp'] as int? ?? 0,
    );
  }

  // Hàm tiện ích để định dạng thời gian
  String get formattedNotificationTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(notificationTimestamp);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  String get formattedLogTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(logTimestamp);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }
}