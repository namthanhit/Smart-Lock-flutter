import 'package:flutter/material.dart';
import 'dart:async';
import '../models/access_log.dart';
import '../services/firebase_service.dart';
import '../widgets/away_mode_card.dart';
import '../widgets/otp_card.dart';
import '../widgets/otp_history_card.dart';
import '../widgets/password_card.dart'; // Vẫn cần import vì nó sẽ được dùng ở tab Trang chủ
import '../widgets/logs_section.dart'; // Vẫn cần import vì nó sẽ được dùng ở tab Lịch sử
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
  bool _isDoorOpen = false; // NEW: Trạng thái cửa đang mở hay đóng

  StreamSubscription? _awayModeSubscription;
  StreamSubscription? _otpLogsSubscription;
  StreamSubscription? _logsSubscription;
  StreamSubscription? _lockStatusSubscription; // NEW: Subscription cho trạng thái khóa

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _listenToAccessLogs();
    _loadInitialOtpLogs();
    _listenToLockStatus(); // NEW: Khởi tạo lắng nghe trạng thái khóa
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
    _lockStatusSubscription?.cancel(); // NEW: Hủy bỏ subscription trạng thái khóa
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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

  // NEW: Lắng nghe trạng thái khóa từ Firebase
  void _listenToLockStatus() {
    _lockStatusSubscription = _firebaseService.getLockStatusStream().listen(
          (isOpen) {
        if (mounted) {
          setState(() => _isDoorOpen = isOpen);
        }
      },
      onError: (error) {
        _showSnackBar('Lỗi kết nối trạng thái khóa: $error', isError: true);
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

  // Hàm để đóng/mở khóa cửa
  Future<void> _toggleLock() async {
    if (!await _verifyMasterPassword(context)) {
      _showSnackBar('Mật khẩu chính không đúng', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firebaseService.setLockStatus(!_isDoorOpen); // Đảo ngược trạng thái hiện tại
      _showSnackBar('Đã ${!_isDoorOpen ? 'mở' : 'đóng'} khóa cửa');
    } catch (e) {
      _showSnackBar('Lỗi điều khiển khóa: $e', isError: true);
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
      body: _buildSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Thẻ'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'OTP'),
        ],
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 0: // Trang chủ
        return _buildHomeSection();
      case 1: // Lịch sử (Chỉ Access Logs)
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: const Column( // Đã loại bỏ OtpHistoryCard ở đây
              children: [
                LogsSection(), // Giữ lại LogsSection
              ],
            ),
          ),
        );
      case 2: // Thẻ
        return const CardManagementSection();
      case 3: // OTP (bao gồm tạo OTP và lịch sử OTP)
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              OtpCard(
                otpDuration: _otpDuration,
                onDurationChanged: (value) => setState(() => _otpDuration = value),
                onCreateOtp: _createOTP,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              // ĐÃ LOẠI BỎ PASSWORDCARD KHỎI TAB NÀY
              // PasswordCard(
              //   mainPassController: _mainPassCtrl,
              //   newPassConfirmController: _newPassConfirmCtrl,
              //   onUpdatePassword: _updateMainPassword,
              //   isLoading: _isLoading,
              // ),
              // const SizedBox(height: 16),
              OtpHistoryCard(otpLogs: _otpLogs), // OtpHistoryCard được di chuyển từ Lịch sử sang đây
            ],
          ),
        );
      default:
        return const Center(child: Text('Không tìm thấy trang'));
    }
  }

  Widget _buildHomeSection() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
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
            const SizedBox(height: 16), // Khoảng cách giữa AwayMode và PasswordCard
            // PasswordCard được giữ lại ở Trang chủ
            PasswordCard(
              mainPassController: _mainPassCtrl,
              newPassConfirmController: _newPassConfirmCtrl,
              onUpdatePassword: _updateMainPassword,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16), // Khoảng cách giữa PasswordCard và nút khóa
            // Nút điều khiển khóa cửa chính
            ElevatedButton(
              onPressed: _isLoading ? null : _toggleLock, // Vô hiệu hóa khi đang tải
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(40), // Kích thước nút lớn hơn
                backgroundColor: _isDoorOpen ? Colors.green.shade700 : Colors.red.shade700, // Màu sắc theo trạng thái
                foregroundColor: Colors.white,
                elevation: 5,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Icon(
                _isDoorOpen ? Icons.lock_open : Icons.lock, // Icon theo trạng thái
                size: 60, // Kích thước icon lớn
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isDoorOpen ? 'Cửa đang MỞ' : 'Cửa đang ĐÓNG',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _isDoorOpen ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32), // Khoảng cách dưới cùng
          ],
        ),
      ),
    );
  }
}