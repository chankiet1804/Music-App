# Firebase cho music-app

> Tài liệu tham khảo: [FlutterFire docs](https://firebase.flutter.dev/) · [Firebase docs](https://firebase.google.com/docs) · [Admin SDK (Node)](https://firebase.google.com/docs/admin/setup)

Tài liệu này là **khung để làm dần** việc tích hợp Firebase. Mỗi lần làm một phần, mở file này, xem nguyên tắc ở [mục 1](#1-nguyên-tắc-bắt-buộc), làm theo checklist của giai đoạn đó, rồi cập nhật trạng thái.

Ký hiệu: ✅ đã có · ⚠️ có một phần / cần sửa · ❌ chưa có · ⏸️ chưa cần · 🚫 không dùng

**Mục lục**

1. [Nguyên tắc bắt buộc](#1-nguyên-tắc-bắt-buộc)
2. [Hiện trạng repo](#2-hiện-trạng-repo)
3. [Bản đồ dịch vụ: dùng gì, không dùng gì](#3-bản-đồ-dịch-vụ-dùng-gì-không-dùng-gì)
4. [Kiến trúc tổng thể](#4-kiến-trúc-tổng-thể)
5. [Quy ước code](#5-quy-ước-code)
6. [Lộ trình và checklist từng giai đoạn](#6-lộ-trình-và-checklist-từng-giai-đoạn)
7. [Chi phí và gói cước](#7-chi-phí-và-gói-cước)
8. [Các bẫy hay gặp](#8-các-bẫy-hay-gặp)
9. [Nhật ký cập nhật](#9-nhật-ký-cập-nhật)

---

## 1. Nguyên tắc bắt buộc

Đọc trước mỗi lần làm. Vi phạm một trong các điều dưới là phải dừng lại xem lại thiết kế.

1. **Firebase không thay Socket.IO cho chat.** Tin nhắn chỉ đi một đường duy nhất: client gửi qua socket, server Node ghi vào SQLite. App Flutter **không** đọc hay ghi tin nhắn vào Firestore. Lý do ở [socketio-chat.md mục "Vì sao không dùng Firebase?"](socketio-chat.md).
2. **Firebase lo 4 việc:** danh tính (Auth), dữ liệu cá nhân của user (Firestore), thông báo khi app đóng (FCM), giám sát (Crashlytics, Analytics, Remote Config).
3. **Mọi truy cập Firebase đi qua interface repository**, giống `Repository`/`DataSource` trong [lib/data/](../lib/data/). UI và controller không gọi trực tiếp `FirebaseFirestore.instance` hay `FirebaseAuth.instance`. Mục đích: test được bằng fake, và đổi được backend sau này.
4. **Danh sách bài hát vẫn là nguồn sự thật duy nhất** (`songsProvider`). Firestore chỉ lưu `songId`, không chép lại thông tin bài hát.
5. **Không có Security Rules thì không ship.** Collection nào thêm vào Firestore cũng phải có rule đi kèm trong cùng commit.
6. **Ở gói Spark (miễn phí) càng lâu càng tốt.** Dịch vụ nào bắt lên Blaze thì ghi rõ trong mục của nó, và phải đặt budget alert trước khi bật.

---

## 2. Hiện trạng repo

Cập nhật bảng này mỗi khi xong một giai đoạn.

| Phần | Trạng thái | Ghi chú |
|---|---|---|
| Nền tảng | — | Chỉ Android (`com.kiet.music_app`) và iOS. FlutterFire hỗ trợ đầy đủ cả hai |
| `firebase_core`, `flutterfire configure` | ✅ | Khởi tạo trong [main.dart](../lib/main.dart) |
| Crashlytics | ❌ | Đang chỉ `debugPrint` lỗi ở [repository.dart](../lib/data/repository/repository.dart) |
| Analytics | ❌ | |
| Auth | ⚠️ | Email/password xong (đăng nhập, đăng ký, quên mật khẩu, đăng xuất). Google/Apple chưa |
| Firestore (favorites, history) | ❌ | Tab Favorite ([favorite.dart](../lib/ui/favorite/favorite.dart)) mới là placeholder |
| Xác thực socket chat bằng ID token | ❌ | Spec chat hiện để server tin luôn `userId` từ `handshake.auth` |
| FCM | ❌ | Socket không nhận được tin khi app đóng |
| Remote Config | ❌ | URL `songs.json` đang viết cứng trong [source.dart](../lib/data/source/source.dart) |
| App Check | ⏸️ | Bật cùng lúc với Firestore |
| Cloud Storage | ⏸️ | Chỉ dùng cho avatar nếu cần |
| Cloud Functions | ⏸️ | Cần Blaze |
| Dynamic Links | 🚫 | Đã ngừng hoạt động từ 08/2025 |

---

## 3. Bản đồ dịch vụ: dùng gì, không dùng gì

| Dịch vụ | Ưu tiên | Dùng để làm gì trong app | Gói |
|---|---|---|---|
| **Crashlytics** | Cao | Bắt crash, ghi lỗi non-fatal (remote load lỗi, nguồn audio hỏng) | Spark |
| **Authentication** | Cao | Đăng nhập (ẩn danh, Google, Apple). Cấp ID token cho server chat | Spark |
| **Cloud Firestore** | Cao | Favorites, lịch sử nghe, playlist của từng user, đồng bộ nhiều máy | Spark |
| **Cloud Messaging (FCM)** | Cao | Push thông báo tin chat khi người nhận offline | Spark |
| **Analytics** | Trung bình | Event `song_play`, `song_skip`, `favorite_add`… | Spark |
| **Remote Config** | Trung bình | URL `songs.json`, URL server chat, feature flag, nội dung Discovery | Spark |
| **App Check** | Trung bình | Chặn request không đến từ app thật vào Firestore | Spark |
| **App Distribution** | Thấp | Gửi bản build cho bạn bè test | Spark |
| **Cloud Storage** | Thấp | Chỉ avatar. **Không** chứa file nhạc (egress đắt) | **Blaze** |
| **Cloud Functions** | Thấp | Đếm lượt nghe, bảng xếp hạng, dọn dữ liệu khi xóa user. Không chạy được Socket.IO | **Blaze** |
| **Firebase AI Logic** | Tùy chọn | Gợi ý bài theo tâm trạng, đặt tên playlist | Tùy model |
| **Firestore cho chat** | 🚫 | Xung đột với Socket.IO, xem nguyên tắc 1 | — |
| **Dynamic Links** | 🚫 | Đã ngừng. Dùng App Links / Universal Links + go_router | — |

---

## 4. Kiến trúc tổng thể

```
┌──────────────── Flutter app ─────────────────┐
│ Auth ─────► ID token ──────────────────┐     │
│ Firestore ◄─► users/{uid}/favorites…   │     │
│ FCM token ─────────────────────────────┤     │
│ Crashlytics · Analytics · Remote Config│     │
└────────────────────────────────────────┼─────┘
                                         ▼  Socket.IO
                                            handshake.auth = { token }
                         ┌──────── Node server ────────┐
                         │ Admin SDK                   │
                         │  · auth().verifyIdToken()   │
                         │  · messaging().send()       │
                         │ SQLite: tin nhắn, FCM token │
                         └─────────────────────────────┘
```

| Dữ liệu | Ai ghi | Nằm ở đâu |
|---|---|---|
| Danh sách bài hát | Server tĩnh | `songs.json` (remote) + `assets/songs.json` (fallback) |
| Tài khoản user | Firebase Auth | Firebase |
| Favorites, history, playlist | App (client) | Firestore `users/{uid}/…` |
| Tin nhắn chat | Server Node | SQLite trên server |
| FCM token của từng máy | Server Node (app gửi lên qua socket) | SQLite trên server |

---

## 5. Quy ước code

### 5.1 Vị trí file (đề xuất)

```
lib/
  firebase_options.dart              ← sinh bởi flutterfire configure, không sửa tay
  core/
    auth/
      auth_providers.dart            ← authServiceProvider, authStateProvider
      auth_controller.dart           ← AuthController (AsyncNotifier): sign in/up, reset, sign out
    monitoring/
      crash_reporter.dart            ← bọc Crashlytics
  data/
    model/
      app_user.dart, auth_failure.dart
    service/
      auth_service.dart              ← interface + FirebaseAuthService
    repository/
      favorite_repository.dart       ← interface + FirestoreFavoriteRepository
    favorite_providers.dart
test/
  fakes/                             ← FakeAuthService, FakeFavoriteRepository
```

Khi viết code thật, nếu thấy chỗ khác hợp hơn với cấu trúc lúc đó thì sửa lại mục này cho khớp.

### 5.2 Pattern repository

```dart
abstract interface class FavoriteRepository {
  Stream<Set<String>> watchFavoriteIds(String uid);
  Future<void> add(String uid, String songId);
  Future<void> remove(String uid, String songId);
}
```

- UI chỉ thấy interface. Bản Firestore là một class cài đặt riêng.
- Test dùng fake class (giống cách [repository_test.dart](../test/repository_test.dart) đang làm), hoặc `fake_cloud_firestore` / `firebase_auth_mocks` nếu cần test chính bản cài đặt.

### 5.3 Provider

| Provider | Loại | Ghi chú |
|---|---|---|
| `authServiceProvider` | `Provider` | Override trong test |
| `authStateProvider` | `StreamProvider<AppUser?>` | Bọc `AuthService.authStateChanges()` |
| `favoriteIdsProvider` | `StreamProvider<Set<String>>` | Phụ thuộc `authStateProvider`. Chưa đăng nhập thì trả set rỗng |
| `favoriteSongsProvider` | `FutureProvider<List<Song>>` | Ghép `favoriteIdsProvider` với `songsProvider` |

Tên và loại provider theo [riverpod.md](riverpod.md).

### 5.4 Router

- Route cần đăng nhập thì chặn bằng `redirect` của go_router, đọc từ `authStateProvider`.
- Router phải được báo khi auth đổi (`refreshListenable`), nếu không thì đăng xuất xong vẫn ở lại màn cũ.

---

## 6. Lộ trình và checklist từng giai đoạn

Làm theo thứ tự. Mỗi giai đoạn tự đứng được và commit riêng. Mục **"Xong khi"** là tiêu chí nghiệm thu.

### Giai đoạn 0: Setup nền

- [ ] Tạo project trên Firebase Console (nên có 2 project `dev` và `prod`, hoặc ít nhất ghi rõ đang dùng project nào)
- [ ] Cài `firebase-tools` và `flutterfire_cli`, chạy `flutterfire configure` → sinh `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
- [ ] Thêm `firebase_core`
- [ ] `main()` chuyển sang async:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    DevicePreview.enable(enabled: kDebugMode);
    runApp(const ProviderScope(child: MysicApp()));
  }
  ```
- [ ] Kiểm tra `minSdk` Android và iOS deployment target có đủ cho các plugin không (xem pub.dev từng plugin)
- [ ] Quyết định có commit các file config không. Chúng **không phải secret** (bảo vệ thật nằm ở Security Rules và App Check), nhưng tách theo môi trường thì dễ quản lý hơn

**Xong khi:** app build và chạy được trên cả Android lẫn iOS, không có lỗi khởi tạo Firebase.

### Giai đoạn 1: Crashlytics + Analytics

- [ ] Thêm `firebase_crashlytics`, `firebase_analytics`
- [ ] Gắn handler bắt lỗi toàn cục trong `main()`:
  ```dart
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  ```
- [ ] Tắt thu thập ở debug: `setCrashlyticsCollectionEnabled(!kDebugMode)`
- [ ] Ghi non-fatal ở các chỗ đang chỉ `debugPrint`: fallback trong `DefaultRepository.loadData()`, nguồn audio lỗi trong player
- [ ] Bọc trong `CrashReporter` (interface) để test không phụ thuộc Firebase
- [ ] Analytics: log `song_play`, `song_skip` (kèm vị trí đang nghe), `favorite_add`. Gắn `FirebaseAnalyticsObserver` vào router nếu muốn theo dõi màn hình

**Xong khi:** một crash thử (`FirebaseCrashlytics.instance.crash()` ở bản release) hiện trên Console, và event hiện trong DebugView.

### Giai đoạn 2: Authentication + tab Account

- [x] Thêm `firebase_auth` (+ `google_sign_in`, `sign_in_with_apple` nếu dùng)
- [x] Email/password: `AuthService` ([auth_service.dart](../lib/data/service/auth_service.dart)), `AuthController`, màn Login gộp sign in / sign up, quên mật khẩu, gửi mail xác minh sau khi đăng ký (không chặn), Sign out ở tab Account
- [x] Test với `FakeAuthService`
- Ghi chú: luồng anonymous-first bên dưới **chưa áp dụng**. Hiện tại bắt buộc đăng nhập trước khi vào app
- [ ] Bật provider trên Console: Anonymous, Google (Android cần SHA-1/SHA-256 của keystore debug và release), Apple (bắt buộc nếu lên App Store mà có đăng nhập mạng xã hội)
- [ ] Mở rộng `AuthService`: `signInAnonymously()`, `signInWithGoogle()`, `getIdToken()`
- [ ] Luồng: mở app → nếu chưa có user thì đăng nhập ẩn danh → nghe nhạc ngay. Ở tab Account cho phép **nâng cấp** lên Google/Apple bằng `linkWithCredential` để giữ nguyên `uid` và dữ liệu
- [ ] Tab Account: avatar, tên, nút đăng nhập/đăng xuất
- [ ] Router: `redirect` và `refreshListenable` (mục 5.4)
- [ ] Test các provider mới với `FakeAuthService`

**Xong khi:** đăng nhập ẩn danh → nâng lên Google → `uid` không đổi; đăng xuất → về trạng thái chưa đăng nhập.

### Giai đoạn 3: Firestore + tab Favorite

- [ ] Thêm `cloud_firestore`, `firebase_app_check`
- [ ] Schema:
  ```
  users/{uid}                       displayName, photoUrl, createdAt
  users/{uid}/favorites/{songId}    addedAt
  users/{uid}/history/{autoId}      songId, playedAt
  users/{uid}/playlists/{id}        name, songIds[], updatedAt
  ```
  `favorites` dùng `songId` làm document id nên thêm hai lần vẫn không trùng.
- [ ] Security Rules (lưu vào repo, ví dụ `firestore.rules`):
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{db}/documents {
      match /users/{uid}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
  ```
- [ ] Test rules bằng Emulator Suite (`firebase emulators:start`) trước khi deploy
- [ ] `FavoriteRepository` + providers ở mục 5.3
- [ ] Nút tim ở `SongItem` và màn Playing; tab Favorite hiển thị `favoriteSongsProvider`
- [ ] History: ghi khi bài được nghe quá một ngưỡng (ví dụ 30 giây), không ghi mỗi lần `load()`
- [ ] Bật App Check (Play Integrity / App Attest; debug provider khi dev)

**Xong khi:** thả tim trên máy A thì máy B (cùng tài khoản) thấy ngay; tắt mạng vẫn thả tim được và đồng bộ lại khi có mạng; user khác không đọc được dữ liệu của mình.

### Giai đoạn 4: Ráp Auth vào chat Socket.IO

Làm sau khi phần chat MVP trong [socketio-chat.md](socketio-chat.md) đã chạy.

- [ ] Client: `setAuth({'token': idToken})` thay cho `{userId, name}`
- [ ] Server: cài `firebase-admin`, khởi tạo bằng service account (đọc từ biến môi trường, **không commit key**)
- [ ] Middleware:
  ```js
  io.use(async (socket, next) => {
    try {
      const decoded = await admin.auth().verifyIdToken(socket.handshake.auth?.token);
      socket.data.userId = decoded.uid;
      socket.data.name = decoded.name ?? "Ẩn danh";
      next();
    } catch {
      next(new Error("unauthorized"));
    }
  });
  ```
- [ ] ID token hết hạn sau khoảng 1 giờ. Trước mỗi lần reconnect, client lấy token mới (`getIdToken()`) và gán lại `socket.auth`
- [ ] Cập nhật spec [2026-09-19-socketio-chat-backend-design.md](superpowers/specs/2026-09-19-socketio-chat-backend-design.md) ở phần xác thực

**Xong khi:** token giả hoặc hết hạn bị `connect_error: unauthorized`; app mở lại sau hơn 1 giờ vẫn kết nối lại được.

### Giai đoạn 5: FCM cho chat khi app đóng

- [ ] Thêm `firebase_messaging` (+ `flutter_local_notifications` nếu cần hiện thông báo khi app đang mở)
- [ ] Android 13+: xin quyền `POST_NOTIFICATIONS`. iOS: upload APNs key lên Console, bật Push Notifications + Background Modes (cần tài khoản Apple Developer trả phí)
- [ ] App lấy FCM token sau khi đăng nhập, gửi lên server qua event socket (ví dụ `device:register`). Gửi lại khi `onTokenRefresh`
- [ ] Server lưu token theo `userId` (một user có thể nhiều máy). Khi người nhận **không online** thì gọi `admin.messaging().send()`. Token không còn hợp lệ thì xóa
- [ ] Payload `data` mang `conversationId` (và `songId` nếu là tin chia sẻ bài)
- [ ] Bấm thông báo: xử lý cả `getInitialMessage()` (app đã tắt hẳn) và `onMessageOpenedApp` (app chạy nền), rồi `router.go(...)` tới màn chat
- [ ] Đăng xuất thì báo server bỏ token của máy đó

**Xong khi:** tắt hẳn app máy B, máy A gửi tin → B nhận thông báo → bấm vào mở đúng cuộc trò chuyện.

### Giai đoạn 6: Remote Config + Discovery (tùy chọn)

- [ ] Thêm `firebase_remote_config`
- [ ] Key: `songs_url`, `chat_server_url`, `chat_enabled`, `discovery_banner`
- [ ] `RemoteDataSource` nhận URL từ config, giữ URL hiện tại làm giá trị mặc định
- [ ] `fetchAndActivate()` không được chặn màn hình đầu: dùng giá trị mặc định hoặc giá trị đã cache trước

**Xong khi:** đổi `songs_url` trên Console thì lần mở app sau dùng URL mới, không cần build lại.

### Giai đoạn mở rộng (chưa lên lịch)

- Cloud Functions đếm lượt nghe, bảng xếp hạng "Thịnh hành" cho Discovery (Blaze)
- BigQuery export từ Analytics (Blaze)
- Firebase AI Logic: gợi ý bài dựa trên history
- Cloud Storage cho avatar (Blaze)

---

## 7. Chi phí và gói cước

| Gói | Có gì | Dùng cho giai đoạn |
|---|---|---|
| **Spark** (miễn phí) | Auth, Firestore (có hạn mức đọc/ghi mỗi ngày), FCM, Crashlytics, Analytics, Remote Config, App Check | 0 → 6 |
| **Blaze** (trả theo mức dùng) | Thêm Cloud Functions, Cloud Storage, BigQuery export, vượt hạn mức Firestore | Mở rộng |

- Trước khi lên Blaze: đặt **budget alert** trong Google Cloud Billing.
- Tốn tiền nhất thường là **Firestore đọc** (listener trên danh sách lớn) và **egress Storage**. Vì vậy favorites chỉ lưu `songId`, và không đưa file nhạc lên Storage.
- Hạn mức cụ thể thay đổi theo thời gian, xem lại trang [pricing](https://firebase.google.com/pricing) mỗi khi lên kế hoạch.

---

## 8. Các bẫy hay gặp

| Bẫy | Hậu quả | Cách tránh |
|---|---|---|
| Quên `WidgetsFlutterBinding.ensureInitialized()` trước `Firebase.initializeApp` | Crash lúc khởi động | Theo đúng snippet giai đoạn 0 |
| Google Sign-In trên Android thiếu SHA-1 của keystore **release** | Debug chạy được, bản release lỗi `ApiException: 10` | Thêm cả SHA debug và release vào Console |
| Để Firestore ở "test mode" | Ai cũng đọc/ghi được, sau 30 ngày thì khóa hết | Viết rules ngay từ đầu (giai đoạn 3) |
| Client vừa ghi socket vừa ghi Firestore cho cùng dữ liệu chat | Tin trùng, khó debug | Nguyên tắc 1 |
| Commit service account key của Admin SDK | Lộ toàn quyền project | Chỉ đọc từ biến môi trường; thêm vào `.gitignore` |
| Socket giữ ID token cũ khi reconnect | Bị `unauthorized` sau khoảng 1 giờ | Lấy token mới trước khi reconnect (giai đoạn 4) |
| Gọi trực tiếp `FirebaseFirestore.instance` trong widget | Không test được, khó đổi backend | Đi qua repository (mục 5.2) |
| Test gọi plugin Firebase thật | Test fail vì chưa khởi tạo Firebase | Override provider bằng fake |
| Listener Firestore không hủy | Tốn lượt đọc, rò rỉ bộ nhớ | Dùng `StreamProvider`; dùng `autoDispose` nếu chỉ một màn cần |
| Bắt lỗi `user-not-found` / `wrong-password` khi đăng nhập | Project bật Email Enumeration Protection (mặc định từ 09/2023) chỉ trả `invalid-credential` | Map cả 3 code về cùng một message (xem [auth_failure.dart](../lib/data/model/auth_failure.dart)) |
| iOS giữ phiên đăng nhập trong Keychain sau khi gỡ app | Cài lại app vẫn đang đăng nhập (FlutterFire #4661) | **Chưa xử lý.** Cách làm: cờ `first_run` trong `shared_preferences`, không có thì `signOut()` |
| Dùng Dynamic Links | Dịch vụ đã ngừng | App Links / Universal Links + go_router |
| Đưa file nhạc lên Cloud Storage | Hóa đơn egress lớn | Giữ nguồn nhạc ở server hiện tại hoặc CDN riêng |

---

## 9. Nhật ký cập nhật

Ghi một dòng mỗi khi xong một giai đoạn hoặc đổi một quyết định trong tài liệu này.

| Ngày | Thay đổi |
|---|---|
| 2026-10-11 | Tạo tài liệu: nguyên tắc, bản đồ dịch vụ, lộ trình 0–6 |
| 2026-10-11 | Giai đoạn 2: xong email/password auth. Auth dùng `AuthService` (data/service) thay cho tên `AuthRepository` |
