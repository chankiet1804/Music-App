---
name: test-ui
description: Use when a UI change in this Flutter app (screen, widget, navigation, form, animation) is finished and must be verified on a real device or emulator before reporting done, or when the user asks to test/check the UI, run the app, or reproduce a visual or interaction bug.
---

# Test UI trên device

## Nguyên tắc

Agent tự chạy app, tự bấm thử, tự đọc lỗi và sửa **trước khi** báo xong. User không phải là người test đầu tiên.

- Logic (validate, controller, repository) → để `flutter test` lo. Device chỉ dùng cho **flow UI**: điều hướng, form, hiển thị, tương tác.
- Đọc màn hình bằng `mobile_list_elements_on_screen` (text, rẻ). **Chỉ chụp screenshot** khi cần đánh giá giao diện (layout, màu, overflow) và một tấm cuối cho báo cáo.

## Các bước

### 1. Kiểm tra rẻ trước
```
flutter analyze
flutter test
```
Fail thì sửa xong mới sang bước 2. Không lên device khi test còn đỏ.

### 2. Chọn device
Gọi `mobile_list_available_devices`.
- **Không có device nào** → DỪNG, hỏi user đúng câu: *"Bạn mở sẵn emulator giúp tôi, hoặc cho tôi biết tên device."* Không tự đoán, không dùng remote device.
- Có nhiều device → hỏi user chọn cái nào.
- Lấy id đúng cho Flutter bằng `flutter devices` (Android thường là `emulator-5554`).

### 3. Chạy app và kết nối Dart MCP
Chạy nền (Bash `run_in_background`), ghi log ra file trong scratchpad:
```
flutter run -d <device-id> --print-dtd > <scratchpad>/flutter_run.log 2>&1
```
Đợi log có dòng `Dart Tooling Daemon` → lấy URI `ws://...` → `dtd` `connect`. (Không thấy thì `dtd` `listDtdUris`.) Kiểm tra bằng `dtd` `listConnectedApps`.

### 4. Bấm thử flow
- `mobile_list_elements_on_screen` → tìm phần tử theo **text hoặc Semantics label** → bấm bằng ref/tọa độ.
- Nhiều thao tác liên tiếp (gõ email → gõ password → bấm nút) → gộp vào `mobile_batch_commands` với `listElementsAtEnd: true`.
- Lưu ý: `Key('login.email')` **không** hiện với mobile-mcp — Key chỉ dùng cho widget/integration test. Phần tử không có text/label thì dùng `widget_inspector` `get_widget_tree` (`summaryOnly: true`) để xác định, hoặc mới chụp screenshot.
- Test cả **đường đúng** và **đường lỗi** (bỏ trống, sai định dạng, sai mật khẩu).
- Flow cần đăng nhập Firebase → hỏi user tài khoản test. Không tự tạo tài khoản thật, không dùng dữ liệu thật.

### 5. Sau mỗi thao tác, kiểm tra lỗi
`get_runtime_errors` (`clearRuntimeErrors: true` để không đọc lại lỗi cũ). Có lỗi (overflow, exception, null...) → sửa code → `hot_reload` (đổi state/khởi tạo thì `hot_restart`) → bấm lại đúng bước đó. Lặp tới khi sạch.

### 6. Lưu flow thành integration test
Flow đã chạy đúng → **REQUIRED SUB-SKILL:** dùng `dart-flutter:flutter-add-integration-test` để chuyển các bước vừa bấm thành test trong `integration_test/`. Test dùng `Key` có sẵn (`login.email`, `login.submit`...); widget quan trọng chưa có Key thì thêm Key.

### 7. Dọn dẹp
Dừng tiến trình `flutter run`, `dtd` `disconnect`.

## Mẫu báo cáo (bắt buộc đúng khung)

```
**Device:** <tên + id>
**Flow đã test:**
| # | Bước | Kết quả mong đợi | Thực tế |
|---|------|------------------|---------|
| 1 | ...  | ...              | ✅ / ❌ |
**Lỗi tìm thấy & đã sửa:** <lỗi → nguyên nhân → file:dòng> (hoặc "Không có")
**Chưa test được:** <phần nào + lý do> (hoặc "Không có")
**Integration test đã thêm:** <đường dẫn file> (hoặc lý do chưa thêm)
**Screenshot cuối:** <đường dẫn file>
```

## Lỗi hay gặp

| Sai | Đúng |
|-----|------|
| Chụp screenshot sau mỗi bước | `list_elements`; screenshot chỉ khi cần nhìn giao diện + 1 tấm cuối |
| Báo "xong" khi chỉ mới `flutter test` | UI change phải qua bước 4–5 trên device |
| Không có device thì tự chạy trên Chrome/web | Dừng và hỏi user |
| Chỉ test đường đúng | Test cả đường lỗi |
| Tìm phần tử theo `Key` bằng mobile-mcp | Tìm theo text/Semantics label |
| Còn runtime error nhưng UI "trông ổn" nên bỏ qua | Runtime error là bug, phải sửa |
| Sửa/xóa test cho pass | Không bao giờ — báo user nguyên nhân |
