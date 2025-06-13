import 'package:firebase_database/firebase_database.dart';
import '../models/access_log.dart';

class FirebaseService {
  static final _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _db = FirebaseDatabase.instance.ref();
  int _lastRequestTime = 0;
  static const _requestInterval = 1000;

  Future<void> _rateLimitRequest() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRequestTime < _requestInterval) {
      await Future.delayed(Duration(milliseconds: _requestInterval - (now - _lastRequestTime)));
    }
    _lastRequestTime = DateTime.now().millisecondsSinceEpoch;
  }

  Future<bool> getAwayMode() async {
    await _rateLimitRequest();
    try {
      final snap = await _db.child('awayMode').get();
      return snap.exists ? snap.value as bool : false;
    } catch (e) {
      throw Exception('Lỗi tải chế độ vắng nhà: $e');
    }
  }

  Future<void> setAwayMode(bool value) async {
    await _rateLimitRequest();
    try {
      await _db.child('awayMode').set(value);
    } catch (e) {
      throw Exception('Lỗi cập nhật chế độ vắng nhà: $e');
    }
  }

  Future<List<AccessLog>> getLogs() async {
    await _rateLimitRequest();
    try {
      final snap = await _db.child('logs').get();
      if (!snap.exists) return [];

      final logList = <AccessLog>[];
      for (var entry in snap.children) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        logList.add(AccessLog(
          method: data['method'] as String,
          success: data['success'] as bool,
          timestamp: data['timestamp'] as int,
        ));
      }
      logList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logList;
    } catch (e) {
      throw Exception('Lỗi tải lịch sử truy cập: $e');
    }
  }

  Future<List<OtpLog>> getOtpLogs() async {
    await _rateLimitRequest();
    try {
      final snap = await _db.child('otpHistory').get();
      if (!snap.exists) return [];

      final otpList = <OtpLog>[];
      for (var entry in snap.children) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        otpList.add(OtpLog(
          code: data['code'] as String,
          expireAt: data['expireAt'] as int,
          used: data['used'] as bool,
          createdAt: data['createdAt'] as int,
        ));
      }
      otpList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return otpList;
    } catch (e) {
      throw Exception('Lỗi tải lịch sử OTP: $e');
    }
  }

  Future<String?> getMasterPassword() async {
    await _rateLimitRequest();
    try {
      final snap = await _db.child('masterPassword').get();
      return snap.value as String? ?? '123456';
    } catch (e) {
      throw Exception('Lỗi lấy mật khẩu chính: $e');
    }
  }

  Future<void> setMasterPassword(String password) async {
    await _rateLimitRequest();
    try {
      await _db.child('masterPassword').set(password);
    } catch (e) {
      throw Exception('Lỗi cập nhật mật khẩu: $e');
    }
  }

  Future<void> createOtp(String code, int expireAt) async {
    await _rateLimitRequest();
    try {
      final now = DateTime.now();
      final createdAt = now.millisecondsSinceEpoch ~/ 1000;

      // Lưu OTP hiện tại
      await _db.child('otp').set({
        'code': code,
        'expireAt': expireAt,
        'used': false,
      });

      // Lưu vào lịch sử OTP
      await _db.child('otpHistory').push().set({
        'code': code,
        'expireAt': expireAt,
        'used': false,
        'createdAt': createdAt,
      });
    } catch (e) {
      throw Exception('Lỗi tạo OTP: $e');
    }
  }
}