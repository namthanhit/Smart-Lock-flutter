# Smart Lock App - Flutter Controller

## Giới thiệu
**Smart Lock App** là ứng dụng Flutter được phát triển để điều khiển và giám sát hệ thống khóa cửa thông minh sử dụng ESP32 và Firebase. Ứng dụng cho phép người dùng tạo OTP một lần, thay đổi mật khẩu chính, bật/tắt chế độ "vắng nhà", và xem nhật ký truy cập cửa theo thời gian thực.

## Tính năng chính
- 🔑 **Tạo mã OTP dùng một lần** với thời gian hết hạn.
- 🔁 **Thay đổi mật khẩu chính** từ ứng dụng.
- 🏠 **Bật/tắt chế độ "vắng nhà"** để vô hiệu hóa truy cập trong thời gian dài.
- 📊 **Xem trạng thái hiện tại** của khóa: đang khóa/mở, số lần nhập sai, thời gian bị khóa nếu có.
- 📜 **Xem lịch sử truy cập cửa** (password hoặc OTP, thành công/thất bại, thời gian).
- 🔔 **Thông báo cảnh báo** nếu có truy cập sai nhiều lần (tùy chọn).

## 🛠️ Công nghệ sử dụng
- ✅ Flutter 3.x
- ✅ Firebase Realtime Database
- ✅ Provider / Riverpod (quản lý trạng thái)
- ✅ HTTP / Firebase SDK
## ⚡ Giao tiếp với Firebase
Ứng dụng sử dụng Firebase Realtime Database để:
- Cập nhật OTP mới: `otp/code`, `otp/expireAt`, `otp/used`
- Thay đổi `masterPassword`
- Ghi nhận `awayMode` (true/false)
- Đọc dữ liệu từ `accessLog`, `failCount`, `lockedUntil`…