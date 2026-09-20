# Socket.IO & tính năng Chat (chia sẻ bài hát cho bạn bè)

> Tài liệu tham khảo: [Socket.IO docs v4](https://socket.io/docs/v4/) · [socket.io-client-dart](https://github.com/rikulo/socket.io-client-dart) · [pub.dev/socket_io_client](https://pub.dev/packages/socket_io_client)

**Mục tiêu MVP:** hai người dùng nhắn tin cho nhau, và **gửi được bài hát yêu thích** vào khung chat. Người nhận bấm vào thẻ bài hát là phát ngay trong app.

Không đồng bộ phát nhạc, không nghe chung, không phòng nhiều người. Những thứ đó để sau.

**Mục lục**

1. [Socket.IO là gì](#1-socketio-là-gì)
2. [Khác gì REST API](#2-khác-gì-rest-api)
3. [Các khái niệm cần biết](#3-các-khái-niệm-cần-biết)
4. [socket_io_client cho Flutter](#4-socket_io_client-cho-flutter)
5. [Thiết kế luồng chat](#5-thiết-kế-luồng-chat)
6. [Giao tiếp FE ↔ BE: danh sách event](#6-giao-tiếp-fe--be-danh-sách-event)
7. [Backend cần làm gì](#7-backend-cần-làm-gì)
8. [Frontend cần làm gì](#8-frontend-cần-làm-gì)
9. [Các bẫy hay gặp](#9-các-bẫy-hay-gặp)
10. [Lộ trình triển khai](#10-lộ-trình-triển-khai)

---

## 1. Socket.IO là gì

Hình dung thế này:

- **REST API** giống như **gửi thư**: app gửi một yêu cầu, server trả lời, rồi hết. Muốn biết có gì mới thì phải gửi thư hỏi tiếp.
- **Socket.IO** giống như **gọi điện thoại**: hai bên nối máy một lần rồi giữ máy luôn. **Bên nào cũng có thể nói bất cứ lúc nào**, và bên kia nghe được ngay.

Theo docs chính thức, Socket.IO là thư viện giúp client và server giao tiếp:

- **độ trễ thấp** (low-latency),
- **hai chiều** (server chủ động gửi xuống client được),
- **theo sự kiện** (event-based): mỗi tin nhắn có một cái tên, ví dụ `chat:message`, kèm theo dữ liệu.

Với app chat thì đặc điểm "server chủ động gửi xuống" chính là thứ ta cần: bạn của bạn gửi tin, máy bạn hiện tin đó ngay, không phải bấm refresh.

### Socket.IO KHÔNG phải WebSocket

Chỗ này nhiều người hay nhầm. Socket.IO **dùng** WebSocket để truyền dữ liệu, nhưng thêm giao thức riêng của nó lên trên:

```
┌─────────────────────────────────────────────┐
│ Socket.IO   → event, room, ack, namespace   │  ← code của bạn làm việc ở tầng này
├─────────────────────────────────────────────┤
│ Engine.IO   → heartbeat, reconnect, buffer  │
├─────────────────────────────────────────────┤
│ Transport   → WebSocket / HTTP long-polling │
└─────────────────────────────────────────────┘
```

Hệ quả là **client WebSocket thuần không kết nối được vào server Socket.IO**, và ngược lại. Hai phía phải cùng dùng thư viện Socket.IO, với phiên bản tương thích nhau.

### Những thứ Socket.IO làm sẵn giúp bạn

| Tính năng | Nghĩa là gì | Nếu tự viết bằng WebSocket thuần |
|---|---|---|
| Tự kết nối lại | Mất mạng thì tự thử kết nối lại, khoảng chờ tăng dần | Phải tự viết |
| Heartbeat (ping/pong) | Phát hiện kết nối "chết" dù chưa báo đóng | Phải tự viết |
| Buffer phía client | Emit lúc đang mất kết nối thì tin được giữ lại, gửi khi có mạng | Phải tự viết |
| Acknowledgement | Gửi event và chờ server trả lời, giống request/response | Phải tự viết cơ chế id |
| Room | Gom socket thành nhóm để gửi cho cả nhóm | Phải tự quản lý danh sách |
| Namespace | Chia nhiều "kênh logic" trên cùng một kết nối | Không có |

---

## 2. Khác gì REST API

| | REST API (`http` mà app đang dùng) | Socket.IO |
|---|---|---|
| Kết nối | Mở cho mỗi request rồi đóng | **Giữ mở liên tục** |
| Ai bắt đầu | Luôn là client | **Cả hai bên** |
| Kiểu giao tiếp | `GET /songs` → response | `emit('chat:send', data)` / `on('chat:message', ...)` |
| Server báo cho client khi có thay đổi | Không được, client phải polling | **Được, gửi ngay lập tức** |
| Trạng thái | Stateless, mỗi request độc lập | **Stateful**: server nhớ socket này là ai, đang ở room nào |
| Gửi cho nhiều người cùng lúc | Không có sẵn | `io.to(room).emit(...)` |
| Cache, CDN, HTTP status code | Có đầy đủ | Không có |
| Scale nhiều server | Dễ | Khó hơn: cần sticky session + Redis adapter |
| Hợp với | CRUD: danh sách bài, favorite, profile | Realtime: chat, presence, "đang gõ..." |

Ví dụ: An gửi cho Bình một bài hát.

- **Dùng REST:** máy Bình phải gọi `GET /messages?since=...` mỗi 2 giây để xem có tin mới chưa. Tốn pin, bị trễ, và tốn tài nguyên server dù chẳng có tin nào.
- **Dùng Socket.IO:** An emit `chat:send`. Server emit `chat:message` xuống máy Bình, tới nơi sau vài chục mili-giây.

> **Lưu ý:** Không phải chọn một trong hai. App thực tế **dùng cả hai**: REST cho dữ liệu tĩnh (danh sách bài hát như hiện tại, đăng nhập, danh sách bạn bè), Socket.IO riêng cho phần realtime.

---

## 3. Các khái niệm cần biết

### 3.1. Event: `emit` và `on`

Mọi thứ đều là "gửi event có tên" và "nghe event có tên".

```js
// Server (Node.js)
socket.emit("hello", { msg: "world" });            // send to this client
socket.on("chat:send", (payload) => { /* ... */ }); // listen from this client
```

```dart
// Client (Flutter)
socket.emit('chat:send', {'text': 'hi'});
socket.on('chat:message', (data) => print(data));
```

Dữ liệu được serialize sang JSON tự động, không cần `jsonEncode`. Có vài ngoại lệ: `Date` sẽ bị chuyển thành string, còn `Map`/`Set` của JS thì phải tự chuyển.

### 3.2. Acknowledgement (ack): request/response bên trong socket

Dùng khi client cần **câu trả lời** từ server, ví dụ "tin của tôi server nhận chưa, id thật là gì?".

```js
// Server: the last argument is the callback
socket.on("chat:send", (payload, ack) => {
  ack({ ok: true, message: {/* ... */} });
});
```

```dart
// Client: await the server's reply
final res = await socket.emitWithAckAsync('chat:send', {'text': 'hi'});
```

Có thể đặt timeout: nếu server không trả lời trong N ms thì báo lỗi. Trong chat, ack chính là thứ giúp UI đổi trạng thái tin nhắn từ "đang gửi" sang "đã gửi" hoặc "gửi lỗi".

### 3.3. Room: "nhóm" phía server

Với chat 1-1, mỗi **cuộc trò chuyện là một room**.

- `socket.join("c_an_binh")`: đưa socket vào room của cuộc trò chuyện.
- `io.to("c_an_binh").emit(...)`: gửi cho **cả hai người** trong cuộc trò chuyện.
- `socket.to("c_an_binh").emit(...)`: gửi cho người kia, **trừ người gửi**.
- **Room chỉ tồn tại ở server.** Client không biết mình đang ở room nào. Client muốn vào room thì phải gửi event nhờ server `join` hộ.
- **Khi socket disconnect, nó tự rời mọi room.** Điểm này rất quan trọng, xem [mục 9](#9-các-bẫy-hay-gặp).

> **Mẹo:** ngoài room theo cuộc trò chuyện, nên cho mỗi socket join luôn một **room cá nhân** tên là `user:<userId>`. Nhờ vậy server báo được "có tin mới" cho một người **kể cả khi họ đang không mở đúng cuộc trò chuyện đó**, để cập nhật badge ở danh sách chat.

### 3.4. Namespace

Là "kênh" riêng trên cùng một kết nối, ví dụ `/chat` và `/admin`. MVP **không cần**, dùng namespace mặc định `/` là đủ.

### 3.5. Middleware & xác thực

Client gửi thông tin đăng nhập lúc kết nối qua option `auth`. Server kiểm tra trong `io.use()`. Nếu từ chối, client nhận event `connect_error`.

```js
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!isValid(token)) return next(new Error("unauthorized"));
  next();
});
```

### 3.6. Đảm bảo gửi tin (delivery guarantee): phải hiểu để thiết kế đúng

Theo docs:

- **Thứ tự tin nhắn được đảm bảo.**
- **Mặc định là "at most once"**: tin có thể **mất** nếu rớt mạng đúng lúc đang gửi.
- **Client có buffer** khi mất kết nối, **server thì KHÔNG**. Nghĩa là trong lúc Bình mất mạng, server phát `chat:message` thì Bình **không bao giờ nhận được** tin đó.

**Hệ quả cho thiết kế chat:**

1. Tin nhắn phải được **lưu lại ở server**, không chỉ broadcast rồi quên.
2. Mỗi lần client (re)connect và mở cuộc trò chuyện, server phải gửi **lịch sử tin nhắn** (snapshot), không phải chỉ phần mới.

Thiết kế ở dưới làm đúng như vậy.

### 3.7. Volatile event

`socket.volatile.emit(...)`: gửi được thì gửi, không được thì bỏ, giống UDP. Hợp với dữ liệu "chỉ cần giá trị mới nhất", ví dụ trạng thái **"đang gõ..."**. Mất một tin typing thì chẳng ai quan tâm.

---

## 4. socket_io_client cho Flutter

### 4.1. Chọn phiên bản

| socket_io_client (Dart) | Server Socket.IO (Node) |
|---|---|
| `v0.9.*` ~ `v1.*` | `v2.*` |
| `v2.*` | `v3.*` ~ `v4.6.*` |
| **`v3.*`** (mới nhất: 3.1.6) | **`v4.7.*` trở lên** |

Project này nên dùng **`socket_io_client: ^3.1.6`**, còn server Node dùng **`socket.io@^4.8`**.

### 4.2. Kết nối

```dart
import 'package:socket_io_client/socket_io_client.dart' as io;

final socket = io.io(
  'https://chat.example.com',
  io.OptionBuilder()
      .setTransports(['websocket']) // required on Flutter mobile/desktop
      .disableAutoConnect()         // connect after the user is known
      .setAuth({'userId': userId, 'name': displayName})
      .setAckTimeout(5000)          // ack fails after 5s
      .build(),
);

socket.onConnect((_) => debugPrint('connected ${socket.id}'));
socket.onConnectError((err) => debugPrint('connect error: $err'));
socket.onDisconnect((reason) => debugPrint('disconnected: $reason'));

socket.connect();
```

Các option hay dùng (lấy từ `OptionBuilder` trong source của thư viện):

| Option | Tác dụng |
|---|---|
| `setTransports(['websocket'])` | **Bắt buộc với Flutter (không phải web).** Bỏ qua long-polling |
| `disableAutoConnect()` | Không tự kết nối ngay khi tạo, phải gọi `connect()` |
| `setAuth({...})` | Dữ liệu xác thực, server đọc từ `socket.handshake.auth` |
| `setExtraHeaders({...})` | Header tùy chỉnh |
| `setReconnectionAttempts(n)` / `setReconnectionDelay(ms)` | Tinh chỉnh việc tự kết nối lại |
| `setAckTimeout(ms)` | Timeout mặc định cho ack |
| `setRetries(n)` | Tự gửi lại nếu không nhận được ack (at-least-once phía client) |
| `enableForceNew()` | Tạo kết nối mới thay vì dùng lại kết nối đã cache |

> `setRetries(n)` rất hợp với chat, nhưng **bắt buộc phải đi kèm `clientMsgId`** ở phía server, nếu không một tin có thể bị lưu hai lần. Xem [mục 5.4](#54-chống-trùng-tin-nhắn).

### 4.3. Gửi, nhận, ack

```dart
// Fire-and-forget
socket.emit('chat:typing', {'conversationId': id});

// Wait for server reply (throws on timeout when ackTimeout is set)
final res = await socket.emitWithAckAsync('chat:send', {'text': 'Hello'});

// Listen
socket.on('chat:message', (data) {
  final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
});

// Stop listening (avoid duplicate handlers)
socket.off('chat:message');

// Tear down
socket.dispose();
```

Các event hệ thống nghe được: `connect`, `connect_error`, `disconnect`, `error`, `reconnect`, `reconnect_attempt`, `reconnect_failed`, `reconnect_error`, `ping`, `pong`.

---

## 5. Thiết kế luồng chat

### 5.1. Trải nghiệm người dùng (MVP)

1. An mở tab **Account**, thấy **danh sách trò chuyện** với những người đã chat.
2. An bấm vào Bình, mở màn chat, thấy **30 tin gần nhất**.
3. An gõ "nghe thử bài này đi" và gửi. Bình thấy ngay.
4. An đang nghe một bài, bấm nút **Chia sẻ** trên màn Playing, chọn Bình. Một **thẻ bài hát** xuất hiện trong khung chat của cả hai.
5. Bình bấm vào thẻ bài hát đó, app **phát bài ngay** bằng player sẵn có và mở màn Playing.
6. Ai online thì hiện chấm xanh. Ai đang gõ thì hiện "đang nhập...".

Hết. **Không** có: nhóm nhiều người, gửi ảnh, thu hồi tin, đồng bộ nghe chung.

### 5.2. Hai loại tin nhắn

Đây là điểm mấu chốt của tính năng. Một tin nhắn chỉ có hai dạng, phân biệt bằng trường `type`:

```jsonc
// Tin văn bản
{
  "id": "m_01H...",
  "conversationId": "c_u_an_u_binh",
  "senderId": "u_an",
  "type": "text",
  "text": "nghe thử bài này đi",
  "sentAt": 1758100000000
}
```

```jsonc
// Tin chia sẻ bài hát
{
  "id": "m_01H...",
  "conversationId": "c_u_an_u_binh",
  "senderId": "u_an",
  "type": "song",
  "text": "bài này hay nè",     // optional caption
  "song": {
    "id": "1121429554",
    "title": "Chúng Ta Của Tương Lai",
    "artist": "Sơn Tùng M-TP",
    "image": "https://..."
  },
  "sentAt": 1758100000000
}
```

**Vì sao gửi cả snapshot `title`/`artist`/`image` mà không chỉ gửi `id`?**

Hai lý do:

- Danh sách bài hát đến từ [songs.json trên remote](../lib/data/source/source.dart) và có thể đổi. Nếu bài bị gỡ, thẻ chat cũ sẽ thành ô trống không biết là bài gì.
- Vẽ được khung chat ngay mà không phải chờ load xong danh sách bài.

Còn **`song.id` vẫn là thứ quan trọng nhất**: khi người nhận bấm vào thẻ, app tra `id` đó trong danh sách bài đang có để phát. Tra không thấy thì hiện thẻ ở dạng "bài hát không còn khả dụng" và khóa nút phát.

> **Lưu ý:** server **không lưu và không gửi file nhạc**. Nó chỉ chuyển đi vài dòng metadata. File nhạc vẫn stream từ `song.source` như hiện tại.

### 5.3. Cuộc trò chuyện (conversation)

MVP chỉ có chat 1-1, nên `conversationId` sinh **tất định** từ hai userId:

```
conversationId = "c_" + [userA, userB].sort().join("_")
```

Ví dụ `u_an` và `u_binh` luôn ra `c_u_an_u_binh`, bất kể ai mở trước. Nhờ vậy không cần API "tạo cuộc trò chuyện", và không lo tạo trùng hai cuộc cho cùng một cặp người.

Mỗi conversation server lưu:

```jsonc
{
  "id": "c_u_an_u_binh",
  "memberIds": ["u_an", "u_binh"],
  "messages": [ /* last 50 */ ],
  "lastMessageAt": 1758100000000
}
```

### 5.4. Chống trùng tin nhắn

Khi mạng chập chờn, client có thể gửi lại một tin mà thực ra server đã nhận rồi. Cách xử lý chuẩn:

1. Client sinh **`clientMsgId`** (UUID) trước khi gửi, và hiển thị tin luôn trên UI với trạng thái `sending` (optimistic UI).
2. Server nhận `chat:send`, kiểm tra `clientMsgId` đã tồn tại trong conversation chưa. Rồi thì **trả về tin cũ** chứ không tạo tin mới.
3. Server ack về `{ ok: true, message }`, trong đó `message.clientMsgId` giữ nguyên.
4. Client tìm tin theo `clientMsgId`, **thay thế** bằng bản từ server (có `id` và `sentAt` thật), đổi trạng thái sang `sent`.
5. Khi nhận broadcast `chat:message`, nếu `clientMsgId` đã có trong danh sách thì bỏ qua, không thêm lần nữa.

Bước 5 cũng chính là lý do server broadcast cho **cả người gửi** (`io.to` chứ không phải `socket.to`): chỉ một đường code duy nhất, và người gửi mở app trên hai máy cũng thấy đủ tin.

### 5.5. Luồng hoạt động tổng thể

```
      An (Flutter)                 Server (Node)                  Bình (Flutter)
          │                             │                              │
          │── connect {auth} ──────────▶│ join room "user:u_an"        │
          │                             │                              │
          │                             │◀───────── connect {auth} ────│ join "user:u_binh"
          │                             │                              │
   mở chat với Bình                     │                              │
          │── conversation:open ───────▶│ id = c_u_an_u_binh           │
          │   {peerId: u_binh}          │ socket.join(id)              │
          │◀─ ack {conversation, ───────│                              │
          │        messages}            │                              │
          │                             │                              │
   gửi "hay lắm"                        │                              │
          │── chat:send ───────────────▶│ validate, lưu tin            │
          │   {clientMsgId, text}       │                              │
          │◀─ ack {ok, message} ────────│                              │
          │◀─ chat:message ─────────────│──── chat:message ───────────▶│ hiện tin mới
          │   (bỏ qua, đã có)           │  (vào cả room hội thoại      │
          │                             │   và room "user:u_binh")     │
          │                             │                              │
   bấm Chia sẻ trên màn Playing         │                              │
          │── chat:send ───────────────▶│                              │
          │   {type:"song", song:{...}} │                              │
          │◀─ chat:message ─────────────│──── chat:message ───────────▶│ hiện thẻ bài hát
          │                             │                              │      │
          │                             │                              │   bấm vào thẻ
          │                             │                              │      ▼
          │                             │                     tra song.id trong danh sách
          │                             │                     → PlayerController.load()
          │                             │                     → push('/playing')
          │                             │                              │
          │                             │       (Bình mất mạng 5 giây) │
          │                             │  Bình tự rời mọi room ✖      │
          │                             │◀───────── (reconnect) ───────│
          │                             │◀──── conversation:open ──────│ onConnect → mở lại
          │                             │───── ack {messages mới} ────▶│ đồng bộ lại lịch sử
```

---

## 6. Giao tiếp FE ↔ BE: danh sách event

Đây là **"hợp đồng API"** giữa FE và BE, đóng vai trò giống tài liệu REST endpoint. Cả hai bên phải thống nhất tên event và shape dữ liệu.

**Quy ước:** tên event có dạng `domain:action`. Payload **luôn là một object**, kể cả khi rỗng (`{}`); lý do xem [mục 9](#9-các-bẫy-hay-gặp).

### Client → Server

| Event | Payload | Ack trả về |
|---|---|---|
| `user:list` | `{}` | `{ ok, users: [{userId, name, online}] }` |
| `conversation:list` | `{}` | `{ ok, conversations }` |
| `conversation:open` | `{ peerId }` | `{ ok, conversation, messages }` hoặc `{ ok:false, error }` |
| `conversation:close` | `{ conversationId }` | `{ ok }` |
| `chat:send` | xem bên dưới | `{ ok, message }` hoặc `{ ok:false, error }` |
| `chat:typing` | `{ conversationId }` | không có (dùng `volatile.emit`) |
| `chat:read` | `{ conversationId }` | `{ ok }` |

Payload của `chat:send`:

```jsonc
// text message
{ "clientMsgId": "uuid", "conversationId": "c_...", "type": "text", "text": "hay lắm" }

// song share
{
  "clientMsgId": "uuid",
  "conversationId": "c_...",
  "type": "song",
  "text": "bài này hay nè",
  "song": { "id": "1121429554", "title": "...", "artist": "...", "image": "https://..." }
}
```

### Server → Client

| Event | Payload | Khi nào |
|---|---|---|
| `chat:message` | một object message | Có tin mới trong cuộc trò chuyện |
| `chat:typing` | `{ conversationId, userId }` | Người kia đang gõ |
| `chat:read` | `{ conversationId, userId, readAt }` | Người kia đã đọc |
| `presence:update` | `{ userId, online }` | Có người online / offline |
| `conversation:updated` | `{ conversation }` | Cập nhật danh sách chat (tin cuối, số chưa đọc) |

Object `conversation` trong `conversation:list`:

```jsonc
{
  "id": "c_u_an_u_binh",
  "peer": { "userId": "u_binh", "name": "Bình", "online": true },
  "lastMessage": { "type": "song", "text": "bài này hay nè", "sentAt": 1758100000000 },
  "unreadCount": 2
}
```

---

## 7. Backend cần làm gì

### 7.1. Stack đề xuất

- **Node.js + `socket.io@^4.8`**: thư viện gốc, docs đầy đủ nhất.
- **Dữ liệu sống trong RAM** (`Map`), và được **ghi ra một file JSON** mỗi khi có tin mới. Xem [mục 7.4](#74-lưu-lịch-sử-chat).
- Có thể viết bằng Dart (package `socket_io`), nhưng hệ sinh thái mỏng hơn nhiều, không khuyến khích.

**Vì sao không dùng Firebase?** Firestore bản thân nó đã là một backend realtime: nó có listener đẩy dữ liệu xuống client ngay khi có thay đổi, tức là làm đúng việc mà Socket.IO đang làm ở đây. Cho app Flutter nói chuyện thẳng với Firestore thì không cần Socket.IO nữa, và mục đích học coi như mất. Tệ hơn là trường hợp lai, client vừa gửi tin qua socket vừa ghi thẳng vào Firestore: hai đường ghi cho cùng một dữ liệu, và bạn sẽ mất thời gian gỡ lỗi trùng tin thay vì học được gì.

Nếu vẫn muốn dùng Firebase thì cách đúng là **chỉ server Node được đụng vào Firestore, qua Firebase Admin SDK**. App Flutter không cài Firebase, vẫn chỉ nói chuyện qua socket. Firestore là cái kho, Socket.IO là đường truyền. Kiến trúc này sạch, nhưng nó **không giúp bạn bỏ được server Node** (Cloud Functions không chạy Socket.IO được, xem [mục 7.5](#75-deploy)), lại bắt bạn làm thêm việc không liên quan tới bài học: tạo project, giữ service account key ngoài git, cấu hình biến môi trường trên host. Chỉ đáng làm nếu bạn muốn học luôn Firebase, hoặc đã cần Firebase Cloud Messaging cho push notification.

### 7.1.1. Lộ trình lưu trữ

| Giai đoạn | Lưu ở đâu | Vì sao |
|---|---|---|
| **Học Socket.IO** (giai đoạn 0–3) | RAM + **file JSON** | Khoảng 15 dòng, không credential, không cài gì thêm. Dồn hết thời gian vào phần socket |
| **Deploy lần đầu** | **SQLite** trên ổ đĩa bền | Ghi từng dòng thay vì ghi đè cả file, có index và transaction. Vài chục nghìn tin vẫn nhanh |
| **Khi thật sự cần** | **Postgres** (Render, Railway, Neon, Supabase) | Chỉ cần khi chạy **nhiều instance**, hoặc cần backup tự động |

Ba điểm hay bị hiểu nhầm:

- **SQLite nằm ở server, không phải ở điện thoại.** Nó là thư viện chạy ngay trong tiến trình Node, và cả database chỉ là một file `chat.db` cạnh `server.js`. Về bản chất giống hệt file JSON, chỉ khác là có SQL và ghi thông minh hơn.
- **Trục nâng cấp thật sự không phải "SQLite tiến lên Postgres".** Nó là "ổ đĩa tạm sang ổ đĩa bền", và xa hơn là "một server sang nhiều server". SQLite hết đất đúng ở mốc thứ hai, vì nó là một file nằm trên một máy. Nhưng tới đó thì Socket.IO cũng cần Redis adapter rồi.
- **Nếu phải rời SQLite thì chọn Postgres chứ không phải MongoDB.** Dữ liệu chat có quan hệ rõ ràng: một cuộc trò chuyện có nhiều tin nhắn, mỗi tin thuộc về một người gửi. MongoDB hợp hơn khi mỗi bản ghi có hình dạng khác nhau và chưa biết trước cấu trúc, điều không đúng với app này. Một lựa chọn khác là **Turso**, tức SQLite chạy trên đám mây, chuyển sang gần như giữ nguyên câu truy vấn.

> Rất có thể bạn dừng ở SQLite và không bao giờ cần tới Postgres. Một app chat vài trăm người dùng chạy SQLite vẫn thoải mái, vì tin nhắn chỉ là ghi thêm dòng mới rồi đọc theo thứ tự thời gian, đúng thứ SQLite làm tốt nhất.

### 7.2. Checklist BE

- [ ] Tạo HTTP server gắn Socket.IO, cấu hình CORS (cần nếu có bản Flutter web)
- [ ] Middleware `io.use`: đọc `userId` và `name` từ `handshake.auth`, gắn vào `socket.data`
- [ ] Khi connect: `socket.join("user:<userId>")`, broadcast `presence:update`
- [ ] `user:list`: trả danh sách người dùng đã từng kết nối (MVP), kèm trạng thái online
- [ ] `conversation:list`: trả các cuộc trò chuyện có mặt người này, sắp xếp theo `lastMessageAt`
- [ ] `conversation:open`: tính `conversationId` tất định, tạo nếu chưa có, `socket.join`, trả 30–50 tin gần nhất
- [ ] `chat:send`: **validate ở server** (có phải thành viên không, text ≤ 500 ký tự, `song.id` hợp lệ), chống trùng theo `clientMsgId`, lưu tin, broadcast
- [ ] `chat:typing`: relay bằng `socket.to(...).volatile.emit(...)`
- [ ] `disconnect`: đánh dấu offline, broadcast `presence:update`
- [ ] Rate limit cho `chat:send`, ví dụ 10 tin / 10 giây / socket
- [ ] **Lưu `conversations` ra file JSON** sau mỗi tin mới, và đọc lại lúc khởi động
- [ ] Thêm `data.json` vào `.gitignore`
- [ ] Log và endpoint `/health` để deploy

### 7.3. Code mẫu (MVP, khoảng 150 dòng)

`package.json`: `{ "type": "module", "dependencies": { "socket.io": "^4.8.1" } }`

```js
// server.js
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { Server } from "socket.io";

const httpServer = createServer((req, res) => {
  if (req.url === "/health") return res.end("ok");
  res.writeHead(404).end();
});
const io = new Server(httpServer, { cors: { origin: "*" } });

const MAX_MESSAGES = 50;
const MAX_TEXT = 500;
const users = new Map();         // userId -> { userId, name, online }
const conversations = new Map(); // conversationId -> conversation

// ---------- helpers ----------
function conversationId(a, b) {
  return `c_${[a, b].sort().join("_")}`;
}

function getOrCreateConversation(a, b) {
  const id = conversationId(a, b);
  if (!conversations.has(id)) {
    conversations.set(id, { id, memberIds: [a, b], messages: [], lastMessageAt: 0 });
  }
  return conversations.get(id);
}

function peerOf(conversation, userId) {
  const peerId = conversation.memberIds.find((id) => id !== userId);
  return users.get(peerId) ?? { userId: peerId, name: peerId, online: false };
}

function summary(conversation, userId) {
  return {
    id: conversation.id,
    peer: peerOf(conversation, userId),
    lastMessage: conversation.messages.at(-1) ?? null,
    unreadCount: 0, // MVP: counted on the client
  };
}

// Never trust the client payload: rebuild the message from scratch.
function buildMessage(payload, sender, conversation) {
  const text = String(payload.text ?? "").trim().slice(0, MAX_TEXT);
  const base = {
    id: randomUUID(),
    clientMsgId: String(payload.clientMsgId ?? randomUUID()),
    conversationId: conversation.id,
    senderId: sender.userId,
    senderName: sender.name,
    sentAt: Date.now(),
  };

  if (payload.type === "song") {
    const song = payload.song ?? {};
    if (!song.id) return null;
    return {
      ...base,
      type: "song",
      text,
      song: {
        id: String(song.id),
        title: String(song.title ?? ""),
        artist: String(song.artist ?? ""),
        image: String(song.image ?? ""),
      },
    };
  }

  if (!text) return null;
  return { ...base, type: "text", text };
}

// ---------- auth ----------
io.use((socket, next) => {
  const { userId, name } = socket.handshake.auth ?? {};
  if (typeof userId !== "string" || typeof name !== "string") {
    return next(new Error("unauthorized"));
  }
  socket.data.user = { userId, name: name.slice(0, 30) };
  next();
});

// ---------- events ----------
io.on("connection", (socket) => {
  const me = socket.data.user;
  users.set(me.userId, { ...me, online: true });
  socket.join(`user:${me.userId}`);
  socket.broadcast.emit("presence:update", { userId: me.userId, online: true });

  socket.on("user:list", (_payload, ack) => {
    ack?.({ ok: true, users: [...users.values()].filter((u) => u.userId !== me.userId) });
  });

  socket.on("conversation:list", (_payload, ack) => {
    const mine = [...conversations.values()]
      .filter((c) => c.memberIds.includes(me.userId))
      .sort((a, b) => b.lastMessageAt - a.lastMessageAt)
      .map((c) => summary(c, me.userId));
    ack?.({ ok: true, conversations: mine });
  });

  socket.on("conversation:open", ({ peerId } = {}, ack) => {
    if (typeof peerId !== "string" || peerId === me.userId) {
      return ack?.({ ok: false, error: "BAD_PEER" });
    }
    const conversation = getOrCreateConversation(me.userId, peerId);
    socket.join(conversation.id);
    ack?.({
      ok: true,
      conversation: summary(conversation, me.userId),
      messages: conversation.messages,
    });
  });

  socket.on("conversation:close", ({ conversationId: id } = {}, ack) => {
    if (typeof id === "string") socket.leave(id);
    ack?.({ ok: true });
  });

  socket.on("chat:send", (payload = {}, ack) => {
    const conversation = conversations.get(String(payload.conversationId ?? ""));
    if (!conversation) return ack?.({ ok: false, error: "NO_CONVERSATION" });
    if (!conversation.memberIds.includes(me.userId)) {
      return ack?.({ ok: false, error: "NOT_A_MEMBER" });
    }

    // Retries and flaky networks resend the same message: return the stored one.
    const existing = conversation.messages.find((m) => m.clientMsgId === payload.clientMsgId);
    if (existing) return ack?.({ ok: true, message: existing });

    const message = buildMessage(payload, me, conversation);
    if (!message) return ack?.({ ok: false, error: "BAD_MESSAGE" });

    conversation.messages = [...conversation.messages, message].slice(-MAX_MESSAGES);
    conversation.lastMessageAt = message.sentAt;

    // Send to the conversation room AND to each member's personal room, so the
    // chat list updates even when the peer has not opened this conversation.
    io.to(conversation.id).emit("chat:message", message);
    for (const memberId of conversation.memberIds) {
      io.to(`user:${memberId}`).emit("conversation:updated", {
        conversation: summary(conversation, memberId),
      });
    }
    ack?.({ ok: true, message });
  });

  socket.on("chat:typing", ({ conversationId: id } = {}) => {
    if (typeof id !== "string") return;
    // Typing is disposable: drop it rather than queue it.
    socket.to(id).volatile.emit("chat:typing", { conversationId: id, userId: me.userId });
  });

  socket.on("chat:read", ({ conversationId: id } = {}, ack) => {
    if (typeof id === "string") {
      socket.to(id).emit("chat:read", { conversationId: id, userId: me.userId, readAt: Date.now() });
    }
    ack?.({ ok: true });
  });

  socket.on("disconnect", () => {
    users.set(me.userId, { ...me, online: false });
    socket.broadcast.emit("presence:update", { userId: me.userId, online: false });
  });
});

httpServer.listen(process.env.PORT ?? 3000, () => console.log("chat server ready"));
```

> Code trên giữ tất cả trong RAM nên restart là mất sạch. Phần lưu xuống file nằm ở [mục 7.4](#74-lưu-lịch-sử-chat), thêm khoảng 15 dòng nữa. Muốn lên production thì còn cần: xác thực thật (JWT), phân trang lịch sử, và push notification khi app đóng.

### 7.4. Lưu lịch sử chat

File JSON này nằm ở **backend**, trên ổ đĩa của máy chạy server Node, ví dụ `data.json` đặt cạnh `server.js`. Điện thoại không lưu gì cả. App Flutter mỗi lần mở cuộc trò chuyện đều xin lịch sử từ server, nên nguồn sự thật chỉ có một chỗ.

Cơ chế gồm đúng ba bước:

1. Lúc khởi động, đọc file lên và đổ vào `Map`.
2. Trong lúc chạy, mọi thao tác đọc ghi vẫn làm trên `Map` như code ở [mục 7.3](#73-code-mẫu-mvp-khoảng-150-dòng), nhanh và đồng bộ.
3. Mỗi khi có tin mới, ghi đè toàn bộ `Map` ra lại file, **có debounce** để 10 tin gửi liên tiếp chỉ tốn một lần ghi đĩa.

```js
// storage.js
import { readFileSync, writeFileSync, renameSync, existsSync } from "node:fs";

const FILE = process.env.DATA_FILE ?? "./data.json";
const FLUSH_DELAY_MS = 300;

export function loadConversations() {
  if (!existsSync(FILE)) return new Map();
  try {
    const raw = JSON.parse(readFileSync(FILE, "utf8"));
    return new Map(Object.entries(raw.conversations ?? {}));
  } catch (err) {
    // A corrupted file must not stop the server from booting.
    console.error("cannot read", FILE, err);
    return new Map();
  }
}

let timer = null;

export function scheduleSave(conversations) {
  if (timer) return; // a flush is already pending
  timer = setTimeout(() => {
    timer = null;
    const payload = { conversations: Object.fromEntries(conversations) };
    // Write to a temp file first: a crash mid-write cannot truncate the real one.
    writeFileSync(`${FILE}.tmp`, JSON.stringify(payload));
    renameSync(`${FILE}.tmp`, FILE);
  }, FLUSH_DELAY_MS);
}
```

Ghép vào `server.js` chỉ mất ba dòng:

```js
import { loadConversations, scheduleSave } from "./storage.js";

const conversations = loadConversations(); // replaces: new Map()

// inside socket.on("chat:send", ...), right after updating the conversation:
conversations.set(conversation.id, conversation);
scheduleSave(conversations);
```

Thêm vào `.gitignore`, nếu không lịch sử chat lúc test sẽ đi vào commit:

```
data.json
data.json.tmp
```

> **Cảnh báo quan trọng:** cách này chỉ ăn chắc khi **chạy local**. Render và Railway gói free dùng filesystem tạm, nên container restart hoặc deploy bản mới là file biến mất, lịch sử chat mất theo. Gói free của Render còn tự ngủ khi không có traffic, nên chuyện đó xảy ra thường xuyên chứ không hiếm.
>
> Thực tế sẽ là: giai đoạn 0 đến 3 chạy server ngay trên máy mình, hai thiết bị nối vào qua IP LAN, file JSON làm đúng việc của nó. Muốn deploy thật cho bạn bè dùng thì đổi sang SQLite kèm **ổ đĩa gắn ngoài** (Render Disk, Railway Volume, hoặc VPS), đúng vào giai đoạn 4 của lộ trình.

Khi đổi sang SQLite, lược đồ MVP chỉ cần hai bảng. `messages` giữ tin nhắn với `conversationId` và `sentAt` làm index, còn phần `song` lưu ở ba cột `songId`, `songTitle`, `songArtist`, `songImage` để khỏi phải parse JSON lúc đọc. `conversations` chỉ cần `id`, `memberIds` và `lastMessageAt`. Bảng `users` chưa cần, vì MVP chưa có đăng ký thật.

### 7.5. Deploy

- Cần host hỗ trợ **kết nối dài hạn**: Render, Railway, Fly.io, VPS.
- **Không dùng được serverless** (Vercel Functions, Netlify Functions), vì hàm bị tắt sau mỗi request.
- Gói free thường **ngủ khi không có traffic**, nên lần kết nối đầu sẽ chậm vài giây.
- Chạy **nhiều instance** thì phải có **sticky session** và **Redis adapter**, nếu không hai người vào hai server khác nhau sẽ không thấy tin của nhau. MVP chạy 1 instance là đủ.

---

## 8. Frontend cần làm gì

### 8.1. Checklist FE

- [ ] Thêm `socket_io_client: ^3.1.6` và `uuid` vào `pubspec.yaml`
- [ ] Tạo tầng socket bọc thư viện, để UI không gọi thẳng `io.Socket`
- [ ] Model: `ChatMessage`, `ChatConversation`, `ChatUser`, `SharedSong` (kèm `fromJson` / `toJson`)
- [ ] Provider Riverpod: danh sách cuộc trò chuyện, tin nhắn của cuộc đang mở, trạng thái kết nối
- [ ] **Optimistic UI**: hiện tin ngay với trạng thái `sending`, đổi sang `sent` khi có ack, `failed` khi timeout (kèm nút gửi lại)
- [ ] Dedupe theo `clientMsgId` khi nhận `chat:message`
- [ ] **Mở lại cuộc trò chuyện mỗi khi `onConnect`** (sau reconnect), vì server đã đá socket ra khỏi room
- [ ] UI: màn danh sách chat, màn chat, bubble tin văn bản, **bubble thẻ bài hát**
- [ ] **Nút Chia sẻ trên màn Playing** mở bottom sheet chọn người nhận, rồi gửi `chat:send` type `song`
- [ ] **Bấm thẻ bài hát**: tra `song.id` trong danh sách bài, `PlayerController.load()`, rồi `context.push('/playing')`
- [ ] Route mới trong [router.dart](../lib/router.dart): `/chat` và `/chat/:conversationId`
- [ ] Android: cho phép `http://` khi test local (`usesCleartextTraffic`), hoặc dùng `https` luôn

### 8.2. Cấu trúc thư mục đề xuất (khớp với cấu trúc hiện tại)

```
lib/
├── core/
│   ├── player/player_providers.dart     (đã có)
│   └── chat/
│       ├── chat_socket.dart             ← wraps socket_io_client, exposes streams
│       ├── chat_models.dart             ← ChatMessage, ChatConversation, SharedSong...
│       ├── chat_providers.dart          ← ConversationListController, ChatController
│       └── share_song.dart              ← Song → SharedSong, SharedSong → play
└── ui/
    └── chat/
        ├── conversation_list_page.dart  ← danh sách trò chuyện
        ├── chat_page.dart               ← khung chat của một cuộc trò chuyện
        ├── message_bubble.dart          ← tin văn bản
        ├── song_message_card.dart       ← thẻ bài hát, bấm vào là phát
        └── share_to_chat_sheet.dart     ← bottom sheet chọn người nhận
```

Tab **Account** hiện vẫn là placeholder ([user.dart](../lib/ui/user/user.dart)), nên đặt danh sách trò chuyện ở đó là hợp lý nhất. Hoặc thêm hẳn một branch **Chat** vào `StatefulShellRoute` nếu muốn có tab riêng.

### 8.3. Tầng socket (rút gọn)

```dart
// lib/core/chat/chat_socket.dart
import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocket {
  ChatSocket({required String url, required String userId, required String name})
    : _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .setAuth({'userId': userId, 'name': name})
            .setAckTimeout(5000)
            .build(),
      ) {
    _socket
      ..onConnect((_) => _connected.add(true))
      ..onDisconnect((_) => _connected.add(false))
      ..on('chat:message', (data) => _messages.add(_asMap(data)))
      ..on('chat:typing', (data) => _typing.add(_asMap(data)))
      ..on('presence:update', (data) => _presence.add(_asMap(data)))
      ..on('conversation:updated', (data) => _conversations.add(_asMap(data)));
  }

  final io.Socket _socket;
  final _connected = StreamController<bool>.broadcast();
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _typing = StreamController<Map<String, dynamic>>.broadcast();
  final _presence = StreamController<Map<String, dynamic>>.broadcast();
  final _conversations = StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get connected => _connected.stream;
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<Map<String, dynamic>> get typing => _typing.stream;
  Stream<Map<String, dynamic>> get presence => _presence.stream;
  Stream<Map<String, dynamic>> get conversations => _conversations.stream;

  void connect() => _socket.connect();

  void notify(String event, [Map<String, dynamic> payload = const {}]) =>
      _socket.emit(event, payload);

  // Payload must be a Map: a List would be spread into multiple arguments.
  Future<Map<String, dynamic>> request(
    String event, [
    Map<String, dynamic> payload = const {},
  ]) async {
    final res = await _socket.emitWithAckAsync(event, payload);
    return _asMap(res);
  }

  void dispose() {
    _socket.dispose();
    _connected.close();
    _messages.close();
    _typing.close();
    _presence.close();
    _conversations.close();
  }

  static Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);
}
```

### 8.4. Controller Riverpod (ý tưởng chính)

```dart
// lib/core/chat/chat_providers.dart (sketch)
class ChatController extends FamilyNotifier<ChatState, String> {
  @override
  ChatState build(String peerId) {
    // conversation:open, listen to chat:message, dedupe by clientMsgId
    return const ChatState.loading();
  }

  Future<void> sendText(String text) async {
    final pending = ChatMessage.pendingText(text, clientMsgId: const Uuid().v4());
    state = state.withMessage(pending); // optimistic
    await _send(pending);
  }

  Future<void> sendSong(Song song, {String caption = ''}) async {
    final pending = ChatMessage.pendingSong(song, caption, clientMsgId: const Uuid().v4());
    state = state.withMessage(pending);
    await _send(pending);
  }

  Future<void> _send(ChatMessage pending) async {
    try {
      final res = await _socket.request('chat:send', pending.toPayload());
      // Replace the optimistic copy with the server copy (real id + sentAt).
      state = state.confirm(pending.clientMsgId, ChatMessage.fromJson(res['message']));
    } catch (_) {
      state = state.markFailed(pending.clientMsgId);
    }
  }

  void typing() => _socket.notify('chat:typing', {'conversationId': _conversationId});

  // On every (re)connect: reopen the conversation, because the server
  // drops room membership when the socket disconnects.
  void _onConnected() { /* request('conversation:open', {'peerId': peerId}) */ }
}
```

### 8.5. Chia sẻ bài hát: hai đầu của luồng

**Đầu gửi** — nút Chia sẻ trên [màn Playing](../lib/ui/playing/playing.dart) mở bottom sheet chọn người nhận, rồi đóng gói bài đang phát:

```dart
// lib/core/chat/share_song.dart
Map<String, dynamic> sharedSongPayload(Song song) => {
  'id': song.id,
  'title': song.title,
  'artist': song.artist,
  'image': song.image,
};
```

**Đầu nhận** — bấm vào thẻ bài hát thì tra trong danh sách bài đang có rồi phát:

```dart
// lib/ui/chat/song_message_card.dart (sketch)
Future<void> _playShared(WidgetRef ref, BuildContext context, SharedSong shared) async {
  final songs = ref.read(songListProvider).valueOrNull ?? const <Song>[];
  final index = songs.indexWhere((s) => s.id == shared.id);
  if (index < 0) {
    // The catalog changed since the message was sent.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bài hát này không còn khả dụng')),
    );
    return;
  }
  final player = ref.read(playerControllerProvider.notifier);
  await player.load(songs, index);
  await player.play();
  if (context.mounted) context.push('/playing');
}
```

Điểm cộng: `PlayerController.load()` hiện đã có nhánh "cùng queue thì không load lại", nên bấm vào nhiều thẻ khác nhau trong cùng một cuộc chat chỉ `seek` sang bài mới chứ không dựng lại cả queue.

> **Quyết định thiết kế:** thẻ bài hát phát **vào queue chính của app**, không phát riêng một mình. Như vậy mini player, nút next/prev và màn Playing hoạt động y như khi mở bài từ tab Home, không phải viết thêm code nào.

### 8.6. Vòng đời app (mobile)

- App xuống nền một lúc thì OS có thể cắt socket. Lúc quay lại, thư viện tự reconnect → `onConnect` → **mở lại cuộc trò chuyện** → nhận lịch sử mới → merge vào danh sách hiện có.
- Thoát màn chat: gọi `conversation:close` để rời room, nhưng **giữ socket sống** nếu vẫn ở trong app, để còn nhận `conversation:updated` cho badge tin chưa đọc.
- Đăng xuất hoặc đóng app: `dispose()` socket.
- Muốn nhận tin khi app đã đóng hẳn thì phải dùng **push notification** (FCM), socket không làm được việc đó. Nằm ngoài phạm vi MVP.

---

## 9. Các bẫy hay gặp

| # | Bẫy | Cách tránh |
|---|---|---|
| 1 | Flutter mobile không kết nối được | Thêm `.setTransports(['websocket'])` |
| 2 | Lệch phiên bản client và server nên kết nối lỗi | Dart `socket_io_client` 3.x ↔ Node `socket.io` ≥ 4.7 |
| 3 | Android emulator gọi `localhost` không tới máy tính | Dùng `http://10.0.2.2:3000`. Máy thật thì dùng IP LAN của máy tính |
| 4 | Android chặn `http://` | Bật `usesCleartextTraffic` khi dev, hoặc dùng `https` |
| 5 | Emit một `List` thì server nhận thành **nhiều tham số** | Payload luôn là `Map`. Thư viện Dart "trải" `Iterable` thành nhiều argument |
| 6 | `emitWithAck(event, null)` thì server nhận `ack` ở **vị trí tham số đầu** | Luôn gửi `{}` thay vì `null` |
| 7 | Reconnect xong nhưng **không nhận tin nhắn nữa** | Server tự rời room khi disconnect, nên gọi lại `conversation:open` trong `onConnect` |
| 8 | **Tin nhắn hiện hai lần** | Dedupe theo `clientMsgId`, vì người gửi cũng nhận broadcast của chính mình |
| 9 | Mất tin trong lúc rớt mạng | Server không buffer. Mở lại conversation phải trả **lịch sử đầy đủ** |
| 10 | Handler bị gọi 2–3 lần | Không đăng ký `socket.on` trong `build()` của widget. Đăng ký một lần ở tầng socket, dùng `off()` khi hủy |
| 11 | Thư viện Dart cache socket theo host nên option mới không có tác dụng | Tạo với `enableForceNew()`, hoặc giữ đúng một instance cho cả app |
| 12 | Rò bộ nhớ trên iOS | Dùng `socket.dispose()` thay vì chỉ `close()` / `disconnect()` |
| 13 | Tin tưởng payload của client | **Luôn dựng lại message ở server**: `id`, `senderId` và `sentAt` do server quyết định, không lấy từ client |
| 14 | Thẻ bài hát thành ô trống sau vài tuần | Gửi kèm snapshot `title`/`artist`/`image`, đừng chỉ gửi `songId` |
| 15 | Spam "đang gõ..." làm nghẽn kết nối | Dùng `volatile.emit` và debounce phía client, ví dụ tối đa 1 lần / 2 giây |
| 16 | Deploy lên serverless nên socket rớt liên tục | Dùng Render, Railway, Fly.io hoặc VPS |

---

## 10. Lộ trình triển khai

| Giai đoạn | Nội dung | Kết quả kiểm chứng |
|---|---|---|
| **0. Hello socket** | Server Node chỉ có kết nối và log. App kết nối, in `socket.id` | Thấy log connect ở cả hai phía |
| **1. Chat văn bản** | `conversation:open`, `chat:send`, `chat:message`, màn chat đơn giản | 2 máy nhắn qua lại realtime |
| **2. Danh sách trò chuyện** | `user:list`, `conversation:list`, `conversation:updated`, badge chưa đọc | Vào tab Account thấy danh sách, có tin mới thì nhảy lên đầu |
| **3. Chia sẻ bài hát** | Message `type: "song"`, nút Chia sẻ ở màn Playing, thẻ bài hát bấm được | Gửi bài từ máy A, máy B bấm vào là phát đúng bài |
| **4. Ổn định** | Optimistic UI, dedupe `clientMsgId`, mở lại conversation sau reconnect, presence, typing, đổi sang **SQLite** khi deploy | Tắt wifi 5 giây rồi bật lại: không mất tin, không trùng tin. Restart server: lịch sử còn nguyên |
| **5. Nâng cao (tùy chọn)** | Auth thật (JWT), phân trang lịch sử, push notification, reaction emoji | — |

Giai đoạn **0 → 2** giúp nắm vững Socket.IO. Giai đoạn **3** là phần mang lại giá trị riêng cho app nghe nhạc. Giai đoạn **4** quyết định chat dùng được thật hay chỉ chạy được lúc demo.
