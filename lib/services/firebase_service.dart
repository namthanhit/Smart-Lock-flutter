import 'package:firebase_database/firebase_database.dart';
import '../models/access_log.dart';
import 'dart:math';
import '../models/card_item.dart';
import '../models/notification_log.dart';
import 'package:flutter/foundation.dart'; // Thêm dòng này

class FirebaseService {
  static final _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _db = FirebaseDatabase.instance.ref();
  int _lastRequestTime = 0;
  static const _requestInterval = 1000;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> _rateLimitRequest() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRequestTime < _requestInterval) {
      await Future.delayed(Duration(milliseconds: _requestInterval - (now - _lastRequestTime)));
    }
    _lastRequestTime = DateTime.now().millisecondsSinceEpoch;
  }

  // Away Mode methods
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

  /// Stream để lắng nghe thay đổi awayMode realtime
  Stream<bool> getAwayModeStream() {
    return _db.child('awayMode').onValue.map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool;
      }
      return false;
    });
  }

  // Access Logs methods
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

  /// Stream để lắng nghe thay đổi logs realtime
  Stream<List<AccessLog>> getLogsStream() {
    return _db.child('logs').onValue.map((event) {
      if (!event.snapshot.exists) return <AccessLog>[];

      final logList = <AccessLog>[];
      for (var entry in event.snapshot.children) {
        try {
          final data = Map<String, dynamic>.from(entry.value as Map);
          logList.add(AccessLog(
            method: data['method'] as String,
            success: data['success'] as bool,
            timestamp: data['timestamp'] as int,
          ));
        } catch (e) {
          // Skip invalid log entries
          continue;
        }
      }
      logList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logList;
    });
  }

  /// Method để thêm log mới
  Future<void> addLog(AccessLog log) async {
    await _rateLimitRequest();
    try {
      await _db.child('logs').push().set({
        'method': log.method,
        'success': log.success,
        'timestamp': log.timestamp,
      });
    } catch (e) {
      throw Exception('Lỗi thêm log: $e');
    }
  }

  // OTP methods
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

  /// Stream để lắng nghe thay đổi OTP history realtime
  Stream<List<OtpLog>> getOtpLogsStream() {
    return _db.child('otpHistory').onValue.map((event) {
      if (!event.snapshot.exists) return <OtpLog>[];

      final otpList = <OtpLog>[];
      for (var entry in event.snapshot.children) {
        try {
          final data = Map<String, dynamic>.from(entry.value as Map);
          otpList.add(OtpLog(
            code: data['code'] as String,
            expireAt: data['expireAt'] as int,
            used: data['used'] as bool,
            createdAt: data['createdAt'] as int,
          ));
        } catch (e) {
          // Skip invalid OTP entries
          continue;
        }
      }
      otpList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return otpList;
    });
  }

  // Phương thức tạo OTP với mã cụ thể
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

  // Phương thức hỗ trợ tạo OTP ngẫu nhiên 6 chữ số
  String _generateRandomOtpCode() {
    final random = Random();
    // Tạo số ngẫu nhiên từ 100000 đến 999999
    return (random.nextInt(900000) + 100000).toString();
  }

  /// Phương thức tạo OTP ngẫu nhiên 6 chữ số và lưu vào Firebase
  Future<void> createRandomOtp(int expireAt) async {
    final code = _generateRandomOtpCode();
    await createOtp(code, expireAt); // Tái sử dụng logic lưu OTP hiện có
  }


  /// Stream để lắng nghe OTP hiện tại
  Stream<Map<String, dynamic>?> getCurrentOtpStream() {
    return _db.child('otp').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Method để đánh dấu OTP đã sử dụng
  Future<void> markOtpAsUsed(String code) async {
    await _rateLimitRequest();
    try {
      // Cập nhật OTP hiện tại
      await _db.child('otp/used').set(true);

      // Cập nhật trong lịch sử OTP
      final snap = await _db.child('otpHistory').get();
      if (snap.exists) {
        for (var entry in snap.children) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          if (data['code'] == code && !(data['used'] as bool)) {
            await entry.ref.update({'used': true});
            break;
          }
        }
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái OTP: $e');
    }
  }

  // Master Password methods
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

  /// Stream để lắng nghe thay đổi master password
  Stream<String> getMasterPasswordStream() {
    return _db.child('masterPassword').onValue.map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as String;
      }
      return '123456';
    });
  }
  // --- QUẢN LÝ THẺ ---

  // Lấy stream của tất cả các thẻ từ node 'allowedCards'
  Stream<List<CardItem>> getCardsStream() {
    return _dbRef.child('allowedCards').onValue.map((event) { // THAY ĐỔI TỪ 'cards' SANG 'allowedCards'
      final List<CardItem> cards = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          try {
            cards.add(CardItem.fromMap(key, value));
          } catch (e) {
            print('Error parsing card $key: $e');
          }
        });
      }
      cards.sort((a, b) => (a.name ?? a.id).compareTo(b.name ?? b.id)); // Sắp xếp theo tên hoặc ID
      return cards;
    });
  }

  // Cập nhật tên của một thẻ, ghi vào trường 'name' bên trong node của thẻ đó
  Future<void> updateCardName(String cardId, String newName) async {
    await _dbRef.child('allowedCards').child(cardId).update({'name': newName}); // THAY ĐỔI ĐƯỜNG DẪN VÀ THÊM TRƯỜNG 'name'
  }

  // Xóa một thẻ khỏi node 'allowedCards'
  Future<void> deleteCard(String cardId) async {
    await _dbRef.child('allowedCards').child(cardId).remove(); // THAY ĐỔI ĐƯỜNG DẪN
  }

  // Stream để lấy lịch sử thông báo
  Stream<List<NotificationLog>> getNotificationHistoryStream() {
    return _db.child('notificationHistory').orderByChild('notificationTimestamp').onValue.map((event) {
      final List<NotificationLog> logs = [];
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          logs.add(NotificationLog.fromMap(key, map));
        });
      }
      // Đảo ngược danh sách để thông báo mới nhất hiển thị đầu tiên
      return logs.reversed.toList();
    }).handleError((e) {
      throw Exception('Lỗi stream lịch sử thông báo: $e');
    });
  }

  // NEW: Smart Lock Control methods
  // Stream để lắng nghe trạng thái khóa hiện tại (mở/đóng)
  Stream<bool> getLockStatusStream() {
    return _db.child('lockStatus/isOpen').onValue.map((event) {
      return event.snapshot.exists ? event.snapshot.value as bool : false; // Mặc định là đóng nếu không tồn tại
    }).handleError((e) {
      debugPrint('DEBUG ERROR: Lỗi stream trạng thái khóa: $e');
      throw Exception('Lỗi stream trạng thái khóa: $e');
    });
  }

  // Phương thức để cập nhật trạng thái khóa
  Future<void> setLockStatus(bool isOpen) async {
    await _rateLimitRequest();
    try {
      await _db.child('lockStatus/isOpen').set(isOpen);
      // Ghi log vào 'logs' khi có hành động mở/khóa từ ứng dụng
      await _db.child('logs').push().set({
        'method': isOpen ? 'Manual Unlock (App)' : 'Manual Lock (App)',
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    } catch (e) {
      debugPrint('DEBUG ERROR: Lỗi cập nhật trạng thái khóa: $e');
      throw Exception('Lỗi cập nhật trạng thái khóa: $e');
    }
  }

  // Connection status
  /// Stream để theo dõi trạng thái kết nối
  Stream<bool> getConnectionStream() {
    return _db.child('.info/connected').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }
}