import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  static String formatCountdown(int expireAt) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remainingSeconds = expireAt - now;
    if (remainingSeconds <= 0) return 'Hết hạn';
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}