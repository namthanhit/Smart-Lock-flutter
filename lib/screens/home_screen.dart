// lib/screens/home_screen.dart (Cập nhật file này)
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/access_log.dart';
import '../services/firebase_service.dart';
import '../widgets/away_mode_card.dart';
import '../widgets/otp_card.dart';
import '../widgets/otp_history_card.dart';
import '../widgets/password_card.dart';
import '../widgets/logs_section.dart';
import '../widgets/card_management_section.dart';
import '../screens/notification_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _mainPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _newPassConfirmCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _awayMode = false;
  bool _isLoading = false;
  List<OtpLog> _otpLogs = [];
  double _otpDuration = 5;
  Timer? _timer;

  // Stream subscriptions
  StreamSubscription? _awayModeSubscription;
  StreamSubscription? _otpLogsSubscription;
  StreamSubscription? _logsSubscription;


  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _listenToAccessLogs();
    _loadInitialOtpLogs();
  }

  @override
  void dispose() {
    _mainPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _newPassConfirmCtrl.dispose();
    _timer?.cancel();
    _awayModeSubscription?.cancel();
    _otpLogsSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }

  void _initializeStreams() {
    _awayModeSubscription = _firebaseService.getAwayModeStream().listen(
          (awayMode) {
        if (mounted) {
          setState(() => _awayMode = awayMode);
        }
      },
      onError: (error) {
        _showSnackBar('Lỗi kết nối away mode: $error', isError: true);
      },
    );

    _otpLogsSubscription = _firebaseService.getOtpLogsStream().listen(
          (otpLogs) {
        if (mounted) {
          setState(() => _otpLogs = otpLogs);
        }
      },
      onError: (error) {
        _showSnackBar('Lỗi kết nối OTP logs: $error', isError: true);
      },
    );
  }

  void _listenToAccessLogs() {
    _logsSubscription = _firebaseService.getLogsStream().listen((logs) {
      if (logs.isNotEmpty && mounted) {
        final AccessLog latestLog = logs.first;
        print('New Access Log detected (for UI): Method: ${latestLog.method}, Success: ${latestLog.success}, AwayMode: $_awayMode, Timestamp: ${latestLog.timestamp}');
      }
    }, onError: (error) {
      _showSnackBar('Lỗi kết nối Access logs: $error', isError: true);
    });
  }

  Future<void> _loadInitialOtpLogs() async {
    try {
      final otpLogs = await _firebaseService.getOtpLogs();
      if (mounted) {
        setState(() => _otpLogs = otpLogs);
      }
    } catch (e) {
      _showSnackBar('Lỗi tải OTP logs: $e', isError: true);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _loadInitialOtpLogs();
      _showSnackBar('Đã làm mới dữ liệu');
    } catch (e) {
      _showSnackBar('Lỗi làm mới: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
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
    if (!await _verifyMasterPassword(context)) {
      _showSnackBar('Mật khẩu chính không đúng', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final expire = now.add(Duration(minutes: _otpDuration.toInt()));
      final timestamp = expire.millisecondsSinceEpoch ~/ 1000;

      await _firebaseService.createRandomOtp(timestamp);
      _showSnackBar('OTP đã được tạo ngẫu nhiên, hiệu lực ${_otpDuration.toInt()} phút');
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
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firebaseService.setAwayMode(value);
      _showSnackBar('Chế độ vắng nhà ${value ? 'bật' : 'tắt'}');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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
        actions: [
          // MỚI: Biểu tượng thông báo
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationHistoryScreen()),
              );
            },
            tooltip: 'Lịch sử thông báo',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<bool>(
                stream: _firebaseService.getConnectionStream(),
                builder: (context, snapshot) {
                  final isConnected = snapshot.data ?? true;
                  if (isConnected) return const SizedBox.shrink();

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mất kết nối - Dữ liệu có thể không cập nhật',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              AwayModeCard(
                awayMode: _awayMode,
                onChanged: _toggleAwayMode,
              ),
              const SizedBox(height: 16),
              OtpCard(
                otpDuration: _otpDuration,
                onDurationChanged: (value) => setState(() => _otpDuration = value),
                onCreateOtp: _createOTP,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              OtpHistoryCard(otpLogs: _otpLogs),
              const SizedBox(height: 16),
              CardManagementSection(), // THÊM WIDGET QUẢN LÝ THẺ MỚI VÀO ĐÂY
              const SizedBox(height: 16),
              PasswordCard(
                mainPassController: _mainPassCtrl,
                newPassConfirmController: _newPassConfirmCtrl,
                onUpdatePassword: _updateMainPassword,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              const LogsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}