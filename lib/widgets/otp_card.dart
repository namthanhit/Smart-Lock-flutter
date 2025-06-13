import 'package:flutter/material.dart';

class OtpCard extends StatelessWidget {
  final TextEditingController otpController;
  final double otpDuration;
  final Function(double) onDurationChanged;
  final VoidCallback onCreateOtp;
  final bool isLoading;

  const OtpCard({
    super.key,
    required this.otpController,
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
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'OTP (1 lần)',
                hintText: 'Nhập mã OTP',
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
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