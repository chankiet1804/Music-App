# CLAUDE.md — music_app

App nghe nhạc Flutter: Riverpod (state), go_router (điều hướng), Firebase Auth (đăng nhập), just_audio (phát nhạc), shadcn_ui (component UI).

## 1. Cấu trúc thư mục (bắt buộc giữ đúng)

```
lib/
  data/     model/, service/, repository/, source/, providers.dart   ← dữ liệu & gọi API/Firebase
  core/     <feature>/*_providers.dart, *_controller.dart            ← state, logic (Riverpod)
  ui/       <màn hình>/...                                           ← widget theo từng màn
  shared/   widgets/                                                 ← widget dùng chung nhiều màn
  theme/    màu, kích thước, font, theme                             ← import qua theme.dart
```

- **Không** tạo `lib/features/` hay layer mới.
- Service/repository nằm trong `data/`. Provider + controller của feature nằm trong `core/<feature>/`.
- `ui/` chỉ được import: `core/`, `data/model/`, `data/providers.dart`, `shared/`, `theme/`.
  **Không** import trực tiếp `data/service/`, `data/repository/`, `data/source/` từ `ui/` — phải đi qua provider.

## 2. Có sẵn thì phải dùng lại — không tự viết bản mới

| Cần gì | Dùng cái này | File mẫu |
|---|---|---|
| Thông báo / toast | `AppToast.show()`, `AppToast.success()`... | [lib/shared/widgets/toast/](lib/shared/widgets/toast/) |
| Màu, spacing, bo góc, icon size, font | `AppColors`, `AppSpacing`, `AppRadius`, `AppIconSize`, `AppTypography` (import `theme/theme.dart`) | [lib/theme/](lib/theme/) |
| Nút play/pause, nút điều khiển | `PlayPauseButton`, `MediaButtonControl` | [lib/shared/widgets/](lib/shared/widgets/) |
| Ô nhập, nút có loading, validate form | `PillInput`, `LoadingButton`, `validators.dart` | [lib/ui/login/](lib/ui/login/) |
| Provider dạng service (để fake khi test) | mẫu `authServiceProvider` | [lib/core/auth/auth_providers.dart](lib/core/auth/auth_providers.dart) |
| Controller có trạng thái loading/error | mẫu `AuthController` (`AsyncNotifier`) | [lib/core/auth/auth_controller.dart](lib/core/auth/auth_controller.dart) |
| Lấy dữ liệu bài hát | `songsProvider`, `songByIdProvider` | [lib/data/providers.dart](lib/data/providers.dart) |

Quy tắc:
- **Trước khi tạo widget/service/provider mới: tìm trong repo xem đã có cái tương tự chưa**, và nói rõ đã tìm thấy gì.
- Nếu cái có sẵn gần đúng nhưng thiếu, **hỏi trước** khi mở rộng nó hoặc tạo cái mới.
- Không hardcode màu, kích thước, font — luôn lấy từ `theme/`.
- Widget dùng ở 2 màn trở lên → chuyển vào `shared/widgets/` (hỏi trước khi di chuyển).

## 3. Test

- Test nằm trong `test/`, fake dùng chung trong `test/fakes/` (ví dụ `FakeAuthService`).
- Widget test: mẫu [test/login_page_test.dart](test/login_page_test.dart) — override provider bằng fake, tắt animation.
- Logic mới trong `core/` hoặc `data/` phải có test đi kèm.
- **Responsive:** mỗi màn hình phải có một test chạy qua mọi kích thước bằng `testWidgetsOnScreens` trong [test/helpers/screen_sizes.dart](test/helpers/screen_sizes.dart) (điện thoại nhỏ/thường/lớn, nằm ngang, tablet, chữ to 2x). Overflow tự làm test fail. Phần tử nằm dưới form cuộn thì `ensureVisible` trước khi tap. Test hành vi (validate, gọi service) giữ ở một size, không cần lặp.
- Font thật (Nunito, Geist) được nạp cho mọi test qua [test/flutter_test_config.dart](test/flutter_test_config.dart). Thêm font mới vào app thì thêm vào file này, nếu không đo kích thước chữ sẽ sai.
- **Không được xóa, skip, comment hay sửa expected value của test cho pass.** Nếu test cũ fail, dừng lại và báo nguyên nhân.

## 4. Sau khi sửa code, luôn chạy

```
flutter analyze
flutter test
```

Cả hai phải sạch thì mới báo là xong. Nếu fail, báo nguyên văn lỗi — không nói "đã xong" khi chưa chạy.

**Có sửa UI** (màn hình, widget, điều hướng, form, animation) → bắt buộc dùng skill `test-ui` để tự test trên device trước khi báo xong. Không có device thì hỏi user, không bỏ qua bước này.

## 5. Cách làm việc

- Việc lớn (nhiều file, feature mới): **viết plan trước** (file nào sửa, dùng lại cái gì có sẵn), chờ duyệt rồi mới code.
- Chỉ làm đúng phạm vi được yêu cầu; không tự refactor hay thêm tính năng.
- Thay đổi nhỏ, chia nhỏ để dễ review.
- Comment trong code viết bằng tiếng Anh, ngắn gọn; không thêm comment thừa.

## 6. Tài liệu tham khảo trong repo

- [docs/riverpod.md](docs/riverpod.md) — cách dùng Riverpod trong app này
- [docs/firebase.md](docs/firebase.md) — cấu hình Firebase
- [docs/tips_flutter.md](docs/tips_flutter.md) — mẹo Flutter
