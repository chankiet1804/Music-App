# Riverpod cheat sheet

## 0. Ý tưởng chung

- **Provider** giống một "biến global thông minh". Nó chỉ được tạo khi có người cần đến lần đầu, sau đó giá trị được cache lại. Khi giá trị đổi, những ai đang theo dõi sẽ được báo.
- **`ref`** là thứ dùng để "với tới" provider. Có `ref` thì mới đọc hay theo dõi được provider.
- **`ProviderScope`** ([main.dart](../lib/main.dart)) là cái kho chứa mọi provider. Phải bọc ở ngoài cùng app, thiếu nó là app crash.

Như vậy mỗi thứ có 2 phía: **nơi tạo provider** (khai báo bằng `final xxxProvider = ...`) và **nơi dùng** (widget hoặc provider khác gọi `ref.watch` hay `ref.read`).

## 1. Các loại provider: chọn theo kiểu dữ liệu

| Loại | Dùng khi dữ liệu là… | Trong app này |
|---|---|---|
| `Provider<T>` | Giá trị **đồng bộ và không đổi**: object, service, repository | `repositoryProvider`, `audioPlayerProvider` |
| `FutureProvider<T>` | Kết quả của **một lần gọi async**, thường là lấy dữ liệu từ server | `songsProvider`, `songByIdProvider` |
| `StreamProvider<T>` | **Dòng dữ liệu liên tục**, liên tục phát giá trị mới | `playerStateProvider`, `durationStateProvider` |
| `NotifierProvider<N, T>` | State **bạn tự thay đổi** qua các method (client state) | `playerControllerProvider` |

Hai "phụ kiện" có thể gắn thêm vào provider:

| Phụ kiện | Ý nghĩa | Ví dụ |
|---|---|---|
| `.autoDispose` | Không còn ai dùng thì tự hủy, lần sau dùng lại sẽ tính lại từ đầu | `songByIdProvider`: rời màn Playing thì bỏ đi |
| `.family` | Provider nhận **tham số**, mỗi tham số cho ra một bản riêng | `songByIdProvider('abc')` và `songByIdProvider('xyz')` là 2 bản khác nhau |

Không gắn `.autoDispose` thì provider **sống suốt app**. `songsProvider` cố ý để như vậy, nhờ đó chuyển tab không phải tải lại danh sách. `audioPlayerProvider` cũng vậy, nhờ đó nhạc không tắt khi rời màn Playing.

## 2. Phía widget: dùng widget nào để lấy được `ref`

| Widget | Khi nào dùng | Trong app này |
|---|---|---|
| `ConsumerWidget` | Thay cho `StatelessWidget`. Hàm `build` có thêm tham số `ref` | `HomeTabPage` ([home.dart](../lib/ui/home/home.dart)) |
| `ConsumerStatefulWidget` + `ConsumerState` | Thay cho `StatefulWidget` khi vẫn cần `initState`/`dispose` (ví dụ `AnimationController`). Có `ref` dùng được ở mọi chỗ trong State | `Playing` ([playing.dart](../lib/ui/playing/playing.dart)) |
| `Consumer(builder: (context, ref, child) {...})` | Bọc **một phần nhỏ** của cây widget. Khi provider đổi thì chỉ phần đó build lại, không phải cả màn | `_progressBar()` và `_playButton()` trong [playing.dart](../lib/ui/playing/playing.dart) |

Thanh progress dùng `Consumer` vì vị trí phát cập nhật liên tục. Nếu `watch` nó ở `build` của cả màn thì toàn bộ màn Playing (ảnh, tên bài…) sẽ build lại liên tục, rất phí.

### `ConsumerWidget` hay `ConsumerStatefulWidget`?

| | `ConsumerWidget` | `ConsumerStatefulWidget` |
|---|---|---|
| `watch` provider, tự vẽ lại khi provider đổi | ✅ | ✅ |
| Gọi `read`/`notifier` để đổi dữ liệu provider | ✅ | ✅ |
| Có `initState`/`dispose` | ❌ | ✅ |
| Giữ controller / mixin / state riêng của UI | ❌ | ✅ |

Mẹo chọn: **mặc định dùng `ConsumerWidget`**. Chỉ khi cần `initState`/`dispose` hoặc controller thì mới chuyển sang `ConsumerStatefulWidget`.

## 3. Các cách dùng `ref`

| Cú pháp | Ý nghĩa | Đặt ở đâu |
|---|---|---|
| `ref.watch(p)` | Đọc **và theo dõi**: giá trị đổi thì widget/provider tự chạy lại | Trong `build`, hoặc trong thân provider |
| `ref.read(p)` | Đọc **một lần**, không theo dõi | Trong callback: `onPressed`, `onSeek`… |
| `ref.read(p.notifier)` | Lấy đối tượng Notifier để **gọi method** (`play`, `pause`…) | Callback |
| `ref.listenManual(p, cb)` | Khi giá trị đổi thì **chạy side-effect** (không build UI) | `initState` |
| `ref.invalidate(p)` | Xóa cache, bắt provider tính lại | Nút Retry |
| `p.future` | Chờ `FutureProvider` có kết quả (dùng `await`) | Trong provider khác |
| `ref.onDispose(fn)` | Dọn dẹp khi provider bị hủy | Trong thân provider |

Quy tắc dễ nhớ: **`watch` để hiển thị, `read` để hành động.**
