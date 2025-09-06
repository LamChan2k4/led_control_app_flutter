# LED Control App - Điều khiển Relay qua Bluetooth

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

Một ứng dụng di động đa nền tảng được xây dựng bằng Flutter, cho phép người dùng điều khiển đồng thời 9 hệ thống relay thông qua kết nối Bluetooth. Ứng dụng cung cấp một giao diện trực quan để dễ dàng bật/tắt các thiết bị điện, đèn LED từ xa.

---

## 🚀 Tính năng chính

- **Kết nối Bluetooth nhanh chóng:** Tự động quét và hiển thị các thiết bị Bluetooth Low Energy (BLE) hoặc Bluetooth Classic ở gần.
- **Giao diện trực quan:** Bảng điều khiển gồm 9 công tắc (switches), mỗi công tắc tương ứng với một relay, thể hiện rõ ràng trạng thái bật/tắt.
- **Phản hồi tức thì:** Gửi lệnh điều khiển và nhận phản hồi trạng thái từ mạch relay một cách nhanh chóng.
- **Tự động kết nối lại:** (Tùy chọn, nếu bạn đã làm tính năng này) Ghi nhớ thiết bị đã kết nối và tự động kết nối lại trong lần sử dụng tiếp theo.
- **Thiết kế đa nền tảng:** Hoạt động mượt mà trên cả Android và iOS nhờ sức mạnh của Flutter.

---

## 📸 Ảnh chụp màn hình ứng dụng

*(Đây là phần quan trọng nhất! Hãy thay thế các ảnh mẫu. Bạn có thể dùng các công cụ như `ezgif.com` để tạo ảnh GIF từ video quay màn hình)*

| Màn hình quét thiết bị | Màn hình điều khiển |
| :---: | :---: |
| <img src="screenshots/scan_screen.png" width="250"> | <img src="screenshots/control_panel.png" width="250"> |

**Video Demo Ngắn:**

*(Nếu có thể, hãy đăng một video ngắn lên YouTube hoặc tạo một ảnh GIF và chèn vào đây. Ví dụ:)*
`![App Demo GIF](screenshots/app_demo.gif)`

---

## 🛠️ Công nghệ & Thư viện sử dụng

- **Framework:** Flutter
- **Ngôn ngữ:** Dart
- **Giao tiếp Bluetooth:**
- `flutter_bluetooth_serial` (cho Bluetooth Classic/SPP). 
- **Quyền ứng dụng:** `permission_handler`

---

## ⚙️ Hướng dẫn cài đặt và chạy thử

Để chạy dự án này trên máy của bạn, hãy làm theo các bước sau:

**1. Chuẩn bị:**
- Đảm bảo bạn đã cài đặt Flutter SDK.
- Clone repository này về máy của bạn:
  ```bash
  git clone https://github.com/LamChan2k4/led_control_app_flutter.git
  ```
- Di chuyển vào thư mục dự án:
  ```bash
  cd led_control_app_flutter
  ```

**2. Cài đặt các gói phụ thuộc:**
```bash
flutter pub get
```

**3. Cấu hình quyền Bluetooth:**
Ứng dụng này yêu cầu quyền truy cập Bluetooth. Hãy đảm bảo các file cấu hình native đã được thiết lập đúng:
- **Android (`android/app/src/main/AndroidManifest.xml`):**
  ```xml
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  ```
- **iOS (`ios/Runner/Info.plist`):**
  ```xml
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>Ứng dụng cần truy cập Bluetooth để tìm và điều khiển các thiết bị relay.</string>
  <key>NSBluetoothPeripheralUsageDescription</key>
  <string>Ứng dụng cần truy cập Bluetooth để tìm và điều khiển các thiết bị relay.</string>
  ```

**4. Chạy ứng dụng:**
Kết nối một thiết bị di động thật (không hỗ trợ trên máy ảo) và chạy lệnh:
```bash
flutter run
```

---

## 💡 Hướng phát triển trong tương lai

- [ ] Lưu lại trạng thái của các relay để khôi phục sau khi mất kết nối.
- [ ] Cho phép người dùng đặt tên cho từng relay (ví dụ: "Đèn phòng khách", "Quạt").
- [ ] Thêm tính năng hẹn giờ bật/tắt.
- [ ] Cải thiện giao diện người dùng với các animation và chủ đề sáng/tối.

