import 'package:flutter/material.dart';
import '../models/access_log.dart';
import '../utils/date_utils.dart';

class OtpHistoryCard extends StatelessWidget {
  final List<OtpLog> otpLogs;

  const OtpHistoryCard({
    super.key,
    required this.otpLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch sử OTP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: otpLogs.isEmpty
                  ? const Center(child: Text('Chưa có OTP nào', style: TextStyle(fontSize: 14)))
                  : ListView.separated(
                itemCount: otpLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final otp = otpLogs[index];
                  final isExpired = (DateTime.now().millisecondsSinceEpoch ~/ 1000) > otp.expireAt;

                  // Xác định trạng thái: Ưu tiên "Đã dùng" nếu OTP đã được sử dụng
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
                    title: Text('Mã OTP: ${otp.code}'),
                    subtitle: Text(
                        'Tạo lúc: ${AppDateUtils.formatTimestamp(otp.createdAt)}\nHiệu lực: ${AppDateUtils.formatCountdown(otp.expireAt, isUsed: otp.used)}'),
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