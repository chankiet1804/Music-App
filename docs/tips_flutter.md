# Flutter Best Practices & Performance Tips

> Tổng hợp từ 2 video:
> - [19 Flutter Best Practices for Pro-Level Apps (2026 Guide)](https://www.youtube.com/watch?v=XlitAikSDR8) — quy trình + kiến trúc (rộng, nông)
> - [5 Tips to Optimize Your Flutter App](https://www.youtube.com/watch?v=qSXfSPV4yDw) — performance runtime (hẹp, sâu)

Tài liệu này dùng làm **checklist để implement dần** cho music-app. Mỗi mục có phần *Trạng thái trong repo* để biết cái gì đã có, cái gì còn thiếu.

Ký hiệu: ✅ đã có · ⚠️ có một phần / cần sửa · ❌ chưa có · ⏸️ chưa cần

**Mục lục**

- [Phần A — Performance runtime](#phần-a--performance-runtime) (ưu tiên cao, sửa được ngay)
- [Phần B — Kiến trúc & code runtime](#phần-b--kiến-trúc--code-runtime)
- [Phần C — Network & offline](#phần-c--network--offline)
- [Phần D — Chất lượng code & quy trình](#phần-d--chất-lượng-code--quy-trình)
- [Phần E — Vận hành & release](#phần-e--vận-hành--release)
- [Lộ trình đề xuất](#lộ-trình-đề-xuất)

---

## Phần A — Performance runtime

5 tip từ video thứ hai. Cụ thể nhất, sửa được ngay, thấy kết quả ngay.

### A1. Không viết method trả về Widget ⚠️

**Vấn đề:** mỗi lần `build()` chạy và gặp method đó, Flutter tạo **instance widget mới hoàn toàn**. Flutter không biết widget đó "vẫn như cũ" vì nhận được object mới mỗi lần → mất khả năng so sánh widget tree và skip rebuild.

**Số liệu tác giả đo** (list 100 item, 60fps):

| Cách làm | Số lần build mỗi item |
|---|---|
| `buildListItem()` method | ~300 |
| Tách thành class `ListItem` | ~57 |

```dart
// BAD: new instance on every parent rebuild
Widget buildListItem(String title) => ListTile(title: Text(title));

// GOOD: Flutter can compare instances and skip rebuilds
class _ListItem extends StatelessWidget {
  const _ListItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => ListTile(title: Text(title));
}
```

**Rule:** gần như không bao giờ tạo widget trong method. Tách ra class riêng — private class trong cùng file cũng được.

> Dev từ React/Vue sang hay dính lỗi này, vì bên đó helper function trả JSX là chuyện bình thường.

**Trạng thái trong repo:**
- ✅ `SongItem` đã là class riêng.
- ⚠️ [mini_player.dart:104](../lib/ui/home/mini_player.dart#L104) — `Widget art() => Image.network(...)` là closure trả widget trong `build()`, lại được gọi 2 lần (dòng 128 nền blur, dòng 134 ảnh chính) → 2 instance mới mỗi rebuild. Nên tách thành `_ArtImage`.
- ⚠️ [play_pause_button.dart:74](../lib/shared/widgets/play_pause_button.dart#L74) — `Widget _buildFilled(...)` cùng vấn đề.

### A2. `ListView.builder()` thay vì truyền `children` ✅

**Vấn đề:** `ListView(children: [...])` khiến Flutter **khởi tạo toàn bộ widget instance vào memory ngay lập tức**, kể cả cái ngoài màn hình.

**Điểm tinh tế:** Flutter *không* gọi `build()` cho tất cả — chỉ build phần visible + buffer nhỏ. **Nhưng object đã tồn tại hết trong RAM rồi** → vẫn trả giá trước. 10.000 item = 10.000 object dù user chỉ thấy vài cái.

**Rule:** list dynamic hoặc lớn → luôn dùng `.builder()` / `.separated()`.

**Trạng thái trong repo:** ✅ [home.dart:33](../lib/ui/home/home.dart#L33) dùng `ListView.separated` với `itemBuilder` (`.separated` cũng lazy như `.builder`). Không có chỗ nào dùng `ListView(children:)`.

### A3. Không đặt logic nặng / tính toán lặp trong `build()` ✅

Hai lỗi riêng biệt:

1. **Logic nặng trong `build()`** — `build()` bị gọi rất nhiều lần, công việc nặng lặp lại liên tục.
2. **Lặp tính toán trong cùng một `build()`** — Flutter chạy `build()` tuần tự từng dòng. Gọi `findMax()` hai lần thì nó tính hai lần, không cache gì cả. `numbers.contains(5000)` là O(n) mỗi lần gọi.

Ba mức giải pháp, tăng dần:

```dart
// BAD: recomputed on every build, twice per build
Widget build(BuildContext context) {
  return Text('${findMax(numbers)} / ${findMax(numbers)}');
}

// BETTER: compute once per build
Widget build(BuildContext context) {
  final max = findMax(numbers);
  return Text('$max / $max');
}

// BEST: compute once per widget lifecycle
late final int _max;

@override
void initState() {
  super.initState();
  _max = findMax(widget.numbers);
}
```

**Trạng thái trong repo:** ✅ chưa thấy tính toán nặng trong `build()`. Giữ nguyên nguyên tắc khi thêm màn hình mới (đặc biệt là sort/filter/search danh sách bài hát).

### A4. Isolate cho tính toán nặng ⏸️

Flutter chạy logic app **và** render UI trên cùng **main isolate** (single thread). Việc nặng CPU trên đó → animation giật, tương tác trễ, app đơ.

```dart
// Must be a top-level (or static) function to be passed to compute()
List<Song> parseSongs(String body) =>
    (jsonDecode(body) as List).map((e) => Song.fromJson(e)).toList();

final songs = await compute(parseSongs, response.body);
```

**Ràng buộc hay fail:** hàm truyền vào `compute()` phải là **top-level hoặc static function**, không được là closure hay instance method.

**Áp dụng cho:** xử lý ảnh, parse dữ liệu lớn, tính toán phức tạp.

**Trạng thái trong repo:** ⏸️ chưa dùng, hiện chưa cần — `assets/songs.json` nhỏ. Cân nhắc lại khi load danh sách vài nghìn bài từ server.

### A5. Tối ưu ảnh ❌

Ba việc cần làm:

**1. Resolution variants** — Flutter hỗ trợ 3 biến thể theo convention thư mục, tự chọn theo pixel density của máy:

```
assets/
  ITunes_logo.png        # 1.0x
  2.0x/ITunes_logo.png
  3.0x/ITunes_logo.png
```

Không có variant thì Flutter vẫn scale được, nhưng sẽ load ảnh to không cần thiết trên máy density thấp → phí RAM và CPU.

**2. Đúng format:**

| Format | Dùng cho |
|---|---|
| PNG | Ảnh cần trong suốt, cạnh sắc nét (icon) |
| JPEG | Ảnh chụp, nhiều màu |
| WebP | Nén tốt, hỗ trợ cả trong suốt lẫn ảnh chụp — lựa chọn hiện đại nhất |

**3. Nén và resize đúng kích thước** — đừng lấy ảnh thẳng từ Figma/camera ở full resolution. UI hiển thị 300×300 thì không có lý do gì load asset 3000×3000.

**Trạng thái trong repo:** ❌ **đây là điểm đáng sửa nhất.**
- `assets/` chỉ có `ITunes_logo.png`, không có thư mục `2.0x/`, `3.0x/`.
- Artwork load qua `Image.network` / `FadeInImage.assetNetwork` **không có `cacheWidth`/`cacheHeight`** → ảnh bìa từ server (600×600 trở lên) bị decode full size vào RAM dù mini player chỉ hiển thị 48×48.

```dart
// Decode at display size, not source size
Image.network(url, width: 48, height: 48, cacheWidth: 96, cacheHeight: 96)
```

Nối thẳng với [C1](#c1-tối-ưu-network-calls-) — nên chuyển sang `cached_network_image` để vừa cache đĩa vừa set được `memCacheWidth`.

---

## Phần B — Kiến trúc & code runtime

### B1. Dependency Injection ✅

Không hardcode dependency trong class → inject để swap implementation và test được. Dùng `get_it` hoặc Riverpod.

**Trạng thái:** ✅ repo đã dùng Riverpod (xem [riverpod.md](riverpod.md), [providers.dart](../lib/data/providers.dart)).

### B2. State management nhất quán ✅

| Giải pháp | Phù hợp |
|---|---|
| Provider | App đơn giản |
| Riverpod | Type-safe, scale tốt |
| Bloc/Cubit | Enterprise, state dự đoán được |
| GetX | Ít boilerplate |

⚠️ **Đừng trộn nhiều giải pháp state** trừ khi có lý do kiến trúc rõ ràng.

**Trạng thái:** ✅ Riverpod xuyên suốt, không trộn.

### B3. Tối ưu performance sớm

- Cache asset nặng (ảnh, JSON, AI response)
- `const` constructor để giảm rebuild
- `ListView.builder` cho list dài → [A2](#a2-listviewbuilder-thay-vì-truyền-children-)
- `RepaintBoundary` cô lập widget vẽ đắt
- Profile định kỳ bằng Flutter DevTools

**Ứng dụng cho music-app:** waveform / visualizer / ảnh bìa xoay trong màn playing là ứng viên cho `RepaintBoundary`.

### B4. Async & Isolate ✅

Việc nặng CPU đẩy sang `compute`/Isolate → [A4](#a4-isolate-cho-tính-toán-nặng-). Không bao giờ block main thread bằng vòng lặp dài hay API call đồng bộ. Dùng `async`/`await` nhất quán cho dễ đọc.

### B5. Logging có cấu trúc ❌

- `debugPrint` thay `print` (tránh vấn đề performance với log lớn)
- Package `logger` cho log màu, có cấu trúc
- Chỉ log cái cần, nhóm log theo feature/module

### B6. Bảo mật ⚠️

- Không hardcode API key → dùng `.env` hoặc secure storage
- HTTPS cho mọi network call
- Validate input cả client lẫn server
- `flutter_secure_storage` cho dữ liệu nhạy cảm
- Obfuscate + minify khi build production

**Liên quan:** khi làm chat (xem [socketio-chat.md](socketio-chat.md)) sẽ cần token auth → áp dụng mục này.

---

## Phần C — Network & offline

### C1. Tối ưu network calls ❌

Phần chi tiết nhất của video 1.

**Dio + interceptors:**

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) { /* add headers, log */ handler.next(options); },
    onResponse: (response, handler) { /* inspect or transform */ handler.next(response); },
    onError: (error, handler) { /* retry or refresh token */ handler.next(error); },
  ),
);
```

**Cache:** `flutter_cache_manager` — `DefaultCacheManager().getSingleFile(url)` lấy từ network hoặc cache nếu có → ít request hơn, UI nhanh hơn.

**Pagination:** gửi `page` & `limit`, server trả đúng trang, load tiếp khi user scroll → giảm data và memory.

**Offline mode:** `connectivity_plus` lắng nghe `onConnectivityChanged`. Khi `ConnectivityResult.none` → hiện banner/toast hoặc queue request lại, gửi khi có mạng.

**Trạng thái trong repo:** ⚠️ hiện load song list trực tiếp, đã có fallback về local khi remote fail (commit `89db351`). Chưa có cache ảnh, chưa có pagination, chưa có detect mạng.

### C2. Offline-first & resilient sync ❌

Mục nâng cao nhất của video 1. Mạng mobile hay chập chờn — thiết kế app chạy được cả khi mất mạng.

| Thành phần | Nội dung |
|---|---|
| Local-first storage | Ghi/đọc Hive hoặc SQLite, sync chạy nền |
| Optimistic UI | Update UI ngay, đánh dấu record `pending` |
| Outbox queue | Buffer lệnh ghi kèm UUID, replay khi online |
| Idempotent API | Server chỉ chấp nhận mỗi operation ID một lần |
| Conflict strategy | Chọn **một** và ghi vào doc: LWW / field-level merge / server-authoritative |
| Backoff & retry | Exponential backoff, giới hạn số lần, báo lỗi ra UI |
| Reachability hooks | Trigger sync khi mạng trở lại |

⚠️ **Pro tip:** log mọi quyết định sync (ai, khi nào, conflict gì, retry mấy lần) — vàng khi debug bug từ user report.

**Ứng dụng cho music-app:** danh sách favorite và playlist là ứng viên rõ nhất cho offline-first.

---

## Phần D — Chất lượng code & quy trình

### D1. Linter + static analysis ❌

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_lints: ^5.0.0
```

Cấu hình `analysis_options.yaml` với rule nghiêm. Linter ép: dùng logger thay `print`, `final` cho giá trị bất biến, format nhất quán.

CI command: `flutter analyze` + `dart format --set-exit-if-changed .`

### D2. CI/CD — máy làm việc của máy, người làm việc của người ❌

| Automation | Human review |
|---|---|
| Lint, format | Kiến trúc |
| Unit/widget test | Edge case |
| Security scan | Business logic |
| Cảnh báo build phình to/chậm | Tính rõ ràng của code |

**Rule team:** PR không merge được cho tới khi all checks pass + ít nhất 1 senior approve.

### D3. Refactor trước khi thêm feature

Dọn duplication, pattern cũ, đặt tên lại cho rõ → rồi mới ghép code mới vào, không hack/shortcut.

### D4. Tránh "clever code"

Code dễ đọc sống lâu hơn code thông minh. Thà dài thêm vài dòng nhưng dễ debug và mở rộng.

### D5. Code metrics & coverage ❌

- `dart_code_metrics` — độ phức tạp, anti-pattern
- `flutter test --coverage` — đo test coverage
- SonarQube cho dự án lớn
- Đặt ngưỡng coverage tối thiểu trong CI

### D6. Git đúng cách ✅

- Feature branch — main luôn sạch và deployable
- Commit atomic, message nói rõ *cái gì* và *tại sao*
- PR + peer review trước khi merge
- Tag version khi release production

---

## Phần E — Vận hành & release

### E1. Feature flags ❌

Bật/tắt feature từ xa, test an toàn, rollout dần mà không cần deploy lại. Dùng `flutter_config` hoặc Firebase Remote Config.

### E2. Semantic versioning

`major.minor.patch` — major = breaking change, minor = feature tương thích ngược, patch = bug fix. Giữ CI/CD pipeline dự đoán được.

### E3. Monitor production ❌

| Tool | Mục đích |
|---|---|
| Crashlytics | Phát hiện crash tức thì |
| Sentry | Error monitoring & reporting |
| Firebase Analytics | Hiểu hành vi user |
| Performance Monitoring | Đo độ mượt UI |

"Đừng bay mù sau khi release."

### E4. Cập nhật dependency ⚠️

`flutter pub outdated` + `flutter pub upgrade`. Đọc changelog trước khi lên major version. Tự động hoá bằng Renovate bot.

### E5. Documentation & onboarding ⚠️

- README có hướng dẫn setup
- API doc bằng dartdoc
- `ARCHITECTURE.md` giải thích cấu trúc project
- Giữ doc cho dev mới luôn cập nhật

**Trạng thái:** ⚠️ đã có [riverpod.md](riverpod.md), [socketio-chat.md](socketio-chat.md) và file này. Chưa có `ARCHITECTURE.md`.

---

## Lộ trình đề xuất

Sắp theo **tỉ lệ lợi ích / công sức** cho music-app:

**Đợt 1 — sửa nhanh, thấy kết quả ngay**

1. [A5](#a5-tối-ưu-ảnh-) — thêm `cacheWidth`/`cacheHeight` cho artwork, chuyển sang `cached_network_image`. Win lớn nhất về memory.
2. [A1](#a1-không-viết-method-trả-về-widget-) — tách `art()` trong `mini_player.dart` và `_buildFilled()` trong `play_pause_button.dart` thành class.
3. [D1](#d1-linter--static-analysis-) — bật `flutter_lints` + `analysis_options.yaml`.

**Đợt 2 — nền tảng**

4. [B5](#b5-logging-có-cấu-trúc-) — logger có cấu trúc, thay mọi `print`.
5. [C1](#c1-tối-ưu-network-calls-) — Dio + interceptor, detect mạng bằng `connectivity_plus`.
6. [D2](#d2-cicd--máy-làm-việc-của-máy-người-làm-việc-của-người-) — GitHub Actions chạy analyze + format + test.

**Đợt 3 — khi app lớn hơn**

7. [C2](#c2-offline-first--resilient-sync-) — offline-first cho favorite/playlist.
8. [B6](#b6-bảo-mật-) — khi làm auth cho tính năng chat.
9. [E3](#e3-monitor-production-) — trước khi release thật.
