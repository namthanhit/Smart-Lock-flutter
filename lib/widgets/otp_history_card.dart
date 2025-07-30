// lib/widgets/otp_history_card.dart
import 'package:flutter/material.dart';
import '../models/access_log.dart'; // Sử dụng đúng file này chứa OtpLog
import '../utils/date_utils.dart'; // Sử dụng file tiện ích ngày tháng của bạn
import 'dart:async'; // Cần import này cho Timer

// Chuyển OtpHistoryCard từ StatelessWidget sang StatefulWidget
class OtpHistoryCard extends StatefulWidget {
  final List<OtpLog> otpLogs;

  const OtpHistoryCard({
    super.key,
    required this.otpLogs,
  });

  @override
  State<OtpHistoryCard> createState() => _OtpHistoryCardState();
}

class _OtpHistoryCardState extends State<OtpHistoryCard> {
  Timer? _countdownTimer; // Đổi tên timer để rõ ràng hơn

  @override
  void initState() {
    super.initState();
    // Khởi tạo timer để cập nhật UI mỗi giây
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) { // Đảm bảo widget vẫn còn trên cây widget và có thể setState
        setState(() {
          // Chỉ cần gọi setState để hàm build được gọi lại,
          // và `AppDateUtils.formatCountdown` sẽ tính toán thời gian mới nhất.
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Hủy timer khi widget bị loại bỏ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử OTP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              height: 200,
              child: widget.otpLogs.isEmpty
                  ? const Center(child: Text('Chưa có OTP nào', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)))
                  : ListView.separated(
                itemCount: widget.otpLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final otp = widget.otpLogs[index];

                  final isExpired = (DateTime.now().millisecondsSinceEpoch ~/ 1000) > otp.expireAt;

                  String status;
                  Color iconColor;
                  IconData iconData;

                  if (otp.used) {
                    status = 'Đã dùng';
                    iconColor = Colors.green;
                    iconData = Icons.check_circle;
                  } else if (isExpired) {
                    status = 'Hết hạn';
                    iconColor = Colors.red;
                    iconData = Icons.cancel;
                  } else {
                    status = 'Còn hiệu lực';
                    iconColor = Colors.blue;
                    iconData = Icons.timer;
                  }

                  return ListTile(
                    leading: Icon(
                      iconData,
                      color: iconColor,
                    ),
                    title: Text(
                      'Mã OTP: ${otp.code}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, // Giữ đậm
                      ),
                    ),
                    subtitle: Text(
                        'Tạo lúc: ${AppDateUtils.formatTimestamp(otp.createdAt)}\nHiệu lực: ${AppDateUtils.formatCountdown(otp.expireAt, isUsed: otp.used)}'
                    ),
                    trailing: Text(status),
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