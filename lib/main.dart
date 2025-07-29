// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // Cần thiết để kiểm tra platform
import 'app.dart';

// Đảm bảo flutterLocalNotificationsPlugin là global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Định nghĩa AndroidNotificationChannel (cho Android 8.0 trở lên)
// Điều này rất quan trọng để quản lý thông báo trên Android.
final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'unauthorized_access_fcm_channel', // ID channel - KHỚP VỚI ID TRONG _showLocalNotification
  'Cảnh báo an ninh từ Smart Lock', // Tên channel hiển thị cho người dùng
  description: 'Thông báo cảnh báo truy cập trái phép từ hệ thống khóa cửa thông minh.', // Mô tả channel
  importance: Importance.max,
);

// Hàm top-level cho thông báo nền từ FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Đảm bảo Firebase được khởi tạo trong isolate nền
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // Khi app ở background/terminated, hệ thống Android sẽ tự hiển thị
  // thông báo nếu FCM payload có trường 'notification'.
  // Do đó, chúng ta KHÔNG cần gọi _showLocalNotification ở đây để tránh trùng lặp.
  // Chúng ta chỉ gọi _showLocalNotification khi app ở foreground.
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Cấu hình Flutter Local Notifications chỉ cho Android
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  // Bỏ DarwinInitializationSettings (iOS)
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // Bỏ iOS: initializationSettingsIOS
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      print('Notification tapped: ${notificationResponse.payload}');
      // Khi người dùng nhấn vào thông báo, hủy nó để dọn dẹp khay
      await flutterLocalNotificationsPlugin.cancel(notificationResponse.id ?? 0);
      // Có thể thêm logic điều hướng ở đây nếu cần
    },
  );

  // Đảm bảo kênh thông báo được tạo trên Android
  // if (defaultTargetPlatform == TargetPlatform.android) { // Không cần check platform nữa nếu chỉ có Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  print('Android Notification Channel created: ${channel.id}');
  // }

  // Yêu cầu quyền thông báo (chỉ có các tham số liên quan đến Android/chung)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false, // Yêu cầu quyền đầy đủ
  );

  // Cấu hình hiển thị thông báo khi app ở foreground (chỉ các tùy chọn chung/Android)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Đăng ký handler cho thông báo nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Đăng ký thiết bị vào topic
  await FirebaseMessaging.instance.subscribeToTopic('unauthorized_access_alerts');
  print('Subscribed to topic: unauthorized_access_alerts');

  // Lắng nghe thông báo khi app ở foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    // CHỈ HIỂN THỊ THÔNG BÁO CỤC BỘ KHI APP Ở FOREGROUND
    // vì hệ thống không tự hiển thị 'notification' payload khi app foreground.
    _showLocalNotification(message);
  });

  // Lắng nghe khi người dùng nhấn vào thông báo từ trạng thái background/terminated
  // Đây là nơi bạn có thể xử lý khi người dùng nhấn vào thông báo để mở app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message opened app: ${message.data}');
    // Khi người dùng mở app thông qua thông báo, chúng ta có thể hủy thông báo đó.
    // Nếu ID thông báo là 0, thì nó sẽ hủy thông báo ID 0.
    flutterLocalNotificationsPlugin.cancel(0); // Hủy thông báo có ID 0 (thông báo cảnh báo chính)
  });

  // Xóa TẤT CẢ thông báo cục bộ ngay khi ứng dụng khởi động chính (sau khi Firebase init và plugin init)
  // Đây là lớp bảo vệ cuối cùng để dọn dẹp các thông báo local cũ.
  await flutterLocalNotificationsPlugin.cancelAll();
  print('Cleared all local notifications on app startup.');

  runApp(const SmartLockApp());
}

// Hàm trợ giúp để hiển thị thông báo cục bộ từ RemoteMessage
// Hàm này chỉ được gọi khi app ở FOREGROUND
Future<void> _showLocalNotification(RemoteMessage message) async {
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;

  // Sử dụng ID thông báo cố định 0 để thông báo mới nhất sẽ cập nhật cái cũ.
  const int notificationId = 0;

  // Bỏ 'const' ở đây để có thể truy cập channel.id
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    channel.id, // SỬ DỤNG ID CHANNEL ĐÃ ĐỊNH NGHĨA GLOBAL
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
    autoCancel: true, // Để thông báo tự động bị loại bỏ khi người dùng nhấn vào
  );
  // Bỏ DarwinNotificationDetails (iOS)
  // Bỏ 'const' ở đây
  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    // Bỏ iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformChannelSpecifics,
    payload: message.data['notificationType'],
  );
  print('Local notification shown with ID: $notificationId (Foreground).');
}