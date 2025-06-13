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
                  return ListTile(
                    leading: Icon(
                      otp.used
                          ? Icons.check_circle
                          : isExpired
                          ? Icons.cancel
                          : Icons.timer,
                      color: otp.used
                          ? Colors.green
                          : isExpired
                          ? Colors.red
                          : Colors.blue,
                    ),
                    title: Text('Mã OTP: ${otp.code}'),
                    subtitle: Text(
                        'Tạo lúc: ${AppDateUtils.formatTimestamp(otp.createdAt)}\nHiệu lực: ${AppDateUtils.formatCountdown(otp.expireAt)}'),
                    trailing: Text(otp.used ? 'Đã dùng' : isExpired ? 'Hết hạn' : 'Còn hiệu lực'),
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