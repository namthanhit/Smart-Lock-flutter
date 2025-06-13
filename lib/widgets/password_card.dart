import 'package:flutter/material.dart';

class PasswordCard extends StatelessWidget {
  final TextEditingController mainPassController;
  final TextEditingController newPassConfirmController;
  final VoidCallback onUpdatePassword;
  final bool isLoading;

  const PasswordCard({
    super.key,
    required this.mainPassController,
    required this.newPassConfirmController,
    required this.onUpdatePassword,
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
            const Text('Đổi mật khẩu chính', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: mainPassController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu chính mới',
                hintText: 'Nhập mật khẩu mới',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassConfirmController,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                hintText: 'Nhập lại mật khẩu mới',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : onUpdatePassword,
                child: const Text('Cập nhật mật khẩu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}