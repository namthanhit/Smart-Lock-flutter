import 'package:flutter/material.dart';

class OtpCard extends StatelessWidget {
  // final TextEditingController otpController; // KHÔNG CẦN NỮA
  final double otpDuration;
  final Function(double) onDurationChanged;
  final VoidCallback onCreateOtp;
  final bool isLoading;

  const OtpCard({
    super.key,
    // required this.otpController, // KHÔNG CẦN NỮA
    required this.otpDuration,
    required this.onDurationChanged,
    required this.onCreateOtp,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tạo OTP', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // TextField đã bị loại bỏ
            const Text(
              'Mã OTP sẽ được tạo ngẫu nhiên 6 chữ số.', // Thông báo cho người dùng
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Thời gian hiệu lực: '),
                Expanded(
                  child: Slider(
                    value: otpDuration,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${otpDuration.toInt()} phút',
                    onChanged: onDurationChanged,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : onCreateOtp,
                child: const Text('Tạo OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}