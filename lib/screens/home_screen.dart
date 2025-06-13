import 'package:flutter/material.dart';
import 'dart:async';
import '../models/access_log.dart';
import '../services/firebase_service.dart';
import '../widgets/away_mode_card.dart';
import '../widgets/otp_card.dart';
import '../widgets/otp_history_card.dart';
import '../widgets/password_card.dart';
import '../widgets/logs_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _otpCtrl = TextEditingController();
  final _mainPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _newPassConfirmCtrl = TextEditingController();

  bool _awayMode = false;
  bool _isLoading = false;
  List<AccessLog> _logs = [];
  List<OtpLog> _otpLogs = [];
  double _otpDuration = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Khởi tạo timer để cập nhật đếm ngược mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {}); // Cập nhật UI để hiển thị thời gian đếm ngược
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _mainPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _newPassConfirmCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadAwayMode(),
        _loadLogs(),
        _loadOtpLogs(),
      ]);
    } catch (e) {
      _showSnackBar('Lỗi tải dữ liệu: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAwayMode() async {
    try {
      final awayMode = await _firebaseService.getAwayMode();
      setState(() => _awayMode = awayMode);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _firebaseService.getLogs();
      setState(() => _logs = logs);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _loadOtpLogs() async {
    try {
      final otpLogs = await _firebaseService.getOtpLogs();
      setState(() => _otpLogs = otpLogs);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<bool> _verifyMasterPassword(BuildContext context) async {
    try {
      final masterPass = await _firebaseService.getMasterPassword();
      final enteredPass = await _showPasswordDialog(context);
      return enteredPass == masterPass;
    } catch (e) {
      _showSnackBar('Lỗi xác thực: $e', isError: true);
      return false;
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận mật khẩu chính'),
        content: TextField(
          controller: _confirmPassCtrl,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu chính',
            hintText: 'Nhập mật khẩu chính hiện tại',
          ),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final pass = _confirmPassCtrl.text;
              _confirmPassCtrl.clear();
              Navigator.pop(context, pass.isNotEmpty ? pass : null);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOTP() async {
    if (_otpCtrl.text.isEmpty) {
      _showSnackBar('Vui lòng nhập OTP', isError: true);
      return;
    }
    if (!await _verifyMasterPassword(context)) {
      _showSnackBar('Mật khẩu chính không đúng', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final expire = now.add(Duration(minutes: _otpDuration.toInt()));
      final timestamp = expire.millisecondsSinceEpoch ~/ 1000;

      await _firebaseService.createOtp(_otpCtrl.text, timestamp);
      _showSnackBar('OTP đã được tạo, hiệu lực ${_otpDuration.toInt()} phút');
      _otpCtrl.clear();
      await _loadOtpLogs();
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMainPassword() async {
    if (_mainPassCtrl.text.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu chính mới', isError: true);
      return;
    }
    if (_mainPassCtrl.text != _newPassConfirmCtrl.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }
    if (!await _verifyMasterPassword(context)) {
      _showSnackBar('Mật khẩu chính hiện tại không đúng', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firebaseService.setMasterPassword(_mainPassCtrl.text);
      _showSnackBar('Đã đổi mật khẩu chính');
      _mainPassCtrl.clear();
      _newPassConfirmCtrl.clear();
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAwayMode(bool value) async {
    if (!await _verifyMasterPassword(context)) {
      _showSnackBar('Mật khẩu chính không đúng', isError: true);
      setState(() => _awayMode = !value);
      return;
    }

    setState(() => _isLoading = true);
    try {
      setState(() => _awayMode = value);
      await _firebaseService.setAwayMode(value);
      _showSnackBar('Chế độ vắng nhà ${_awayMode ? 'bật' : 'tắt'}');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
      setState(() => _awayMode = !value);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Lock Control'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AwayModeCard(
                awayMode: _awayMode,
                onChanged: _toggleAwayMode,
              ),
              const SizedBox(height: 16),
              OtpCard(
                otpController: _otpCtrl,
                otpDuration: _otpDuration,
                onDurationChanged: (value) => setState(() => _otpDuration = value),
                onCreateOtp: _createOTP,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              OtpHistoryCard(otpLogs: _otpLogs),
              const SizedBox(height: 16),
              PasswordCard(
                mainPassController: _mainPassCtrl,
                newPassConfirmController: _newPassConfirmCtrl,
                onUpdatePassword: _updateMainPassword,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              LogsSection(logs: _logs),
            ],
          ),
        ),
      ),
    );
  }
}