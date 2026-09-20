# Thiết kế backend Socket.IO cho tính năng chat

> Ngày: 2026-09-19 · Tài liệu nguồn: [docs/socketio-chat.md](../../socketio-chat.md) mục 6 và 7

## 1. Mục tiêu

Dựng một server Socket.IO phục vụ tính năng chat 1-1 của app nghe nhạc Flutter: nhắn tin văn bản
và chia sẻ bài hát. Server là nguồn sự thật duy nhất của lịch sử tin nhắn.

Đây là bản MVP phục vụ mục đích học Flutter và Socket.IO, nên tiêu chí hàng đầu là **code dễ đọc**,
không phải khả năng mở rộng. Ưu tiên đúng chức năng cho client gọi, đủ để FE đi hết giai đoạn 0–4
của lộ trình trong tài liệu nguồn.

### Ngoài phạm vi

Xác thực thật (JWT), phân trang lịch sử, push notification, chat nhóm, gửi ảnh, thu hồi tin,
đồng bộ nghe chung, chạy nhiều instance. Không có bản Flutter web nên **không cấu hình CORS**.

## 2. Quyết định thiết kế

| Vấn đề | Quyết định | Lý do |
|---|---|---|
| Vị trí | `C:\development\music-app-backend`, git repo riêng | Tách bạch app và server, deploy độc lập |
| Runtime | Node.js 24 (ESM, `"type": "module"`) | Đã có sẵn trên máy; hỗ trợ `node --watch` |
| Thư viện | `socket.io@^4.8` (dep), `socket.io-client` (devDep) | Khớp `socket_io_client: ^3.1.6` phía Dart |
| Xác thực | `handshake.auth = {userId, name}`, server tin luôn | Đơn giản nhất, đúng mục 7.3 của tài liệu nguồn |
| Lưu trữ | `Map` trong RAM, ghi ra `data.json` có debounce | ~15 dòng, không credential, không cài thêm gì |
| `unreadCount` | **Tính ở server** qua `lastReadAt` từng thành viên | FE chỉ việc hiển thị, không phải tự đếm |
| Phạm vi event | Toàn bộ checklist mục 7.2 | FE có đủ mọi thứ để làm tới giai đoạn 4 |
| CORS | Không cấu hình | Chỉ có Android và iOS |
| Tooling | Chỉ npm scripts, không eslint/prettier/dotenv/nodemon | Giảm thứ phải cài và phải hiểu |

`unreadCount` tính ở server là điểm **khác** tài liệu nguồn (mục 7.3 để MVP đếm ở client).
Đổi lại phải lưu thêm `lastReadAt` cho mỗi thành viên, và `conversation:updated` phải tính
summary riêng cho từng người thay vì gửi chung một object.

## 3. Cấu trúc thư mục

```
music-app-backend/
├── config.js                 ~20 dòng   hằng số cấu hình
├── store.js                  ~90 dòng   Map + đọc/ghi data.json
├── model.js                  ~90 dòng   logic thuần trên dữ liệu
├── server.js                ~150 dòng   http server + socket event
├── scripts/
│   └── demo-client.js        ~80 dòng   hai client giả lập để kiểm chứng
├── package.json
├── README.md
└── .gitignore
```

Mỗi module có một việc rõ ràng:

- **`config.js`** — đọc biến môi trường, trả về hằng số. Không phụ thuộc gì.
- **`store.js`** — sở hữu hai `Map` và file JSON. Xuất `users`, `conversations`,
  `loadData()`, `scheduleSave()`. Không biết gì về Socket.IO.
- **`model.js`** — hàm thuần biến đổi dữ liệu: sinh `conversationId`, dựng message,
  tính summary và unread. Không biết gì về Socket.IO, không tự ghi file.
- **`server.js`** — chỗ duy nhất chạm tới Socket.IO. Mỗi handler ngắn, gọi `model.js`
  rồi `scheduleSave()` rồi emit.

### `config.js`

| Hằng số | Giá trị mặc định | Ghi chú |
|---|---|---|
| `PORT` | `process.env.PORT ?? 3000` | |
| `HOST` | `0.0.0.0` | Để máy thật trong cùng LAN kết nối được |
| `DATA_FILE` | `process.env.DATA_FILE ?? "./data.json"` | |
| `FLUSH_DELAY_MS` | `300` | Debounce ghi đĩa |
| `MAX_TEXT` | `500` | Độ dài tối đa của `text` |
| `MAX_NAME` | `30` | Độ dài tối đa của `name` |
| `KEEP_MESSAGES` | `200` | Số tin giữ lại mỗi cuộc trò chuyện |
| `HISTORY_LIMIT` | `50` | Số tin trả về khi `conversation:open` |
| `RATE_LIMIT_MAX` | `10` | Số tin tối đa... |
| `RATE_LIMIT_WINDOW_MS` | `10000` | ...trong khoảng thời gian này, trên mỗi socket |

## 4. Mô hình dữ liệu

### User

```jsonc
{ "userId": "u_an", "name": "An", "online": true }
```

`online` **luôn được đặt lại `false`** lúc đọc file, vì cờ này chỉ có nghĩa trong phiên chạy hiện tại.

### Conversation

```jsonc
{
  "id": "c_u_an_u_binh",
  "memberIds": ["u_an", "u_binh"],
  "messages": [ /* tối đa KEEP_MESSAGES tin, cũ trước mới sau */ ],
  "lastMessageAt": 1758100000000,
  "lastReadAt": { "u_an": 1758100000000, "u_binh": 0 }
}
```

`conversationId` sinh tất định: `"c_" + [userA, userB].sort().join("_")`.

### Message

Hai dạng, phân biệt bằng `type`. Các trường `id`, `senderId`, `senderName`, `sentAt`
**do server sinh**, không lấy từ client.

```jsonc
// type: "text"
{
  "id": "<randomUUID>",
  "clientMsgId": "<uuid do client sinh>",
  "conversationId": "c_u_an_u_binh",
  "senderId": "u_an",
  "senderName": "An",
  "type": "text",
  "text": "nghe thử bài này đi",
  "sentAt": 1758100000000
}
```

```jsonc
// type: "song" — thêm trường song, text trở thành caption tuỳ chọn
{
  "...": "các trường như trên",
  "type": "song",
  "text": "bài này hay nè",
  "song": { "id": "1121429554", "title": "...", "artist": "...", "image": "https://..." }
}
```

### Conversation summary (gửi xuống client)

Tính riêng cho từng người nhận, vì `peer` và `unreadCount` khác nhau giữa hai thành viên.

```jsonc
{
  "id": "c_u_an_u_binh",
  "peer": { "userId": "u_binh", "name": "Bình", "online": true },
  "lastMessage": { /* message cuối, hoặc null */ },
  "unreadCount": 2
}
```

`unreadCount` = số tin thoả `senderId !== me && sentAt > lastReadAt[me]`.

## 5. Hợp đồng event

### Client → Server

| Event | Payload | Ack |
|---|---|---|
| `user:list` | `{}` | `{ ok, users }` — mọi user đã từng kết nối, trừ chính mình |
| `conversation:list` | `{}` | `{ ok, conversations }` — sort `lastMessageAt` giảm dần |
| `conversation:open` | `{ peerId }` | `{ ok, conversation, messages }` hoặc `{ ok: false, error }` |
| `conversation:close` | `{ conversationId }` | `{ ok: true }` |
| `chat:send` | xem dưới | `{ ok, message }` hoặc `{ ok: false, error }` |
| `chat:typing` | `{ conversationId }` | không có |
| `chat:read` | `{ conversationId }` | `{ ok: true }` |

Payload `chat:send`:

```jsonc
{ "clientMsgId": "uuid", "conversationId": "c_...", "type": "text", "text": "hay lắm" }

{ "clientMsgId": "uuid", "conversationId": "c_...", "type": "song",
  "text": "bài này hay nè",
  "song": { "id": "...", "title": "...", "artist": "...", "image": "..." } }
```

### Server → Client

| Event | Payload | Gửi tới | Khi nào |
|---|---|---|---|
| `chat:message` | một message | `io.to(conversationId)` | Có tin mới |
| `conversation:updated` | `{ conversation }` | `io.to("user:<id>")`, từng người một | Sau `chat:send`, `chat:read`, `conversation:open` |
| `chat:typing` | `{ conversationId, userId }` | `socket.to(id).volatile` | Người kia đang gõ |
| `chat:read` | `{ conversationId, userId, readAt }` | `socket.to(id)` | Người kia đã đọc |
| `presence:update` | `{ userId, online }` | `socket.broadcast` | Connect / disconnect |

`chat:message` gửi vào cả room hội thoại **kể cả người gửi**, nên FE bắt buộc dedupe theo
`clientMsgId`. Đây là chủ ý: một đường code duy nhất, và người gửi mở app trên hai máy
vẫn thấy đủ tin.

### Mã lỗi

| Mã | Nghĩa |
|---|---|
| `BAD_PEER` | `peerId` không phải chuỗi, hoặc trùng chính mình |
| `NO_CONVERSATION` | `conversationId` không tồn tại |
| `NOT_A_MEMBER` | Người gửi không thuộc cuộc trò chuyện |
| `BAD_MESSAGE` | Tin rỗng, hoặc `type: "song"` mà thiếu `song.id` |
| `RATE_LIMITED` | Vượt 10 tin trong 10 giây trên cùng một socket |

Lỗi ở tầng kết nối (`handshake.auth` thiếu `userId` hoặc `name`) trả bằng
`next(new Error("unauthorized"))`, client nhận qua `connect_error`.

## 6. Luồng xử lý từng event

**Middleware `io.use`** — đọc `userId` và `name` từ `handshake.auth`. Cả hai phải là chuỗi
không rỗng, nếu không thì từ chối. `name` cắt còn `MAX_NAME` ký tự. Gắn vào `socket.data.user`.

**`connection`** — ghi user vào `store.users` với `online: true`, `socket.join("user:<userId>")`,
`socket.broadcast.emit("presence:update", ...)`, `scheduleSave()`.

**`user:list`** — trả toàn bộ `store.users` trừ chính mình.

**`conversation:list`** — lọc các conversation có mình trong `memberIds`, sort theo
`lastMessageAt` giảm dần, map qua `summaryFor(conv, me)`.

**`conversation:open`** — validate `peerId`, tạo conversation nếu chưa có, `socket.join(conv.id)`,
đặt `lastReadAt[me] = Date.now()`, trả về summary cùng `HISTORY_LIMIT` tin cuối.
Gửi `conversation:updated` cho chính mình để badge chưa đọc về 0 ngay.

**`conversation:close`** — `socket.leave(conversationId)`. Socket vẫn sống để còn nhận
`conversation:updated` cho badge.

**`chat:send`** — theo thứ tự:

1. Kiểm tra rate limit của socket, vượt thì ack `RATE_LIMITED`.
2. Tìm conversation, không có thì `NO_CONVERSATION`.
3. Kiểm tra thành viên, không phải thì `NOT_A_MEMBER`.
4. Tìm `clientMsgId` trong `messages`; có rồi thì ack lại **tin cũ** và dừng (chống trùng).
5. `buildMessage()` dựng tin từ đầu; trả `null` thì ack `BAD_MESSAGE`.
6. Nối tin vào `messages`, cắt còn `KEEP_MESSAGES`, cập nhật `lastMessageAt`,
   đặt `lastReadAt[senderId] = sentAt` (tin mình gửi thì mình đã đọc).
7. `scheduleSave()`.
8. `io.to(conv.id).emit("chat:message", message)`.
9. Với mỗi thành viên: `io.to("user:<id>").emit("conversation:updated", { conversation: summaryFor(conv, id) })`.
10. Ack `{ ok: true, message }`.

**`chat:typing`** — `socket.to(id).volatile.emit(...)`. Typing mất một tin thì không ai quan tâm.

**`chat:read`** — đặt `lastReadAt[me] = Date.now()`, `scheduleSave()`, báo `chat:read` cho người
kia và `conversation:updated` cho chính mình.

**`disconnect`** — đặt `online: false`, broadcast `presence:update`, `scheduleSave()`.
Socket tự rời mọi room, nên FE phải gọi lại `conversation:open` sau mỗi lần reconnect.

## 7. Bền vững dữ liệu

```jsonc
// data.json
{ "users": { "u_an": {} }, "conversations": { "c_u_an_u_binh": {} } }
```

- Lúc khởi động: đọc file, đổ vào `Map`, đặt mọi `online` về `false`.
  File không tồn tại hoặc hỏng thì log lỗi và khởi động rỗng — **không được làm server chết**.
- Lúc chạy: mọi thao tác làm trên `Map`, đồng bộ và nhanh.
- Sau mỗi thay đổi: `scheduleSave()` hẹn ghi sau `FLUSH_DELAY_MS`, nhiều thay đổi liên tiếp
  gộp thành một lần ghi. Ghi ra `data.json.tmp` rồi `rename` đè lên `data.json`,
  để crash giữa chừng không cắt cụt file thật.
- `data.json` và `data.json.tmp` nằm trong `.gitignore`.

Cách này chỉ ăn chắc khi chạy local. Muốn deploy thật thì đổi sang SQLite kèm ổ đĩa bền —
ngoài phạm vi bản này.

## 8. Vận hành

`package.json` scripts:

| Script | Lệnh | Dùng khi |
|---|---|---|
| `start` | `node server.js` | Chạy bình thường |
| `dev` | `node --watch server.js` | Sửa code tự restart |
| `demo` | `node scripts/demo-client.js` | Kiểm chứng server đang chạy |

HTTP: chỉ một route `GET /health` trả `ok`, mọi thứ khác trả 404.

Lúc khởi động in ra các URL dùng được, lấy IP LAN từ `os.networkInterfaces()`:

```
chat server ready on port 3000
  localhost : http://localhost:3000
  emulator  : http://10.0.2.2:3000
  LAN       : http://192.168.1.12:3000
```

Log mỗi khi có người connect/disconnect và mỗi tin nhắn được lưu, đủ để theo dõi lúc test
mà không ngập màn hình.

## 9. Kiểm chứng

`scripts/demo-client.js` dùng `socket.io-client` giả lập hai người dùng và chạy hết một kịch bản,
in log từng bước. Đây là bằng chứng cho từng mục checklist, không cần mở Flutter.

| Bước | Chứng minh điều gì |
|---|---|
| An và Bình connect | Middleware auth, `presence:update` |
| An gọi `user:list` | Thấy Bình trong danh sách |
| An gọi `conversation:open {peerId: "u_binh"}` | `conversationId` tất định, trả lịch sử |
| An gửi tin text | Bình nhận `chat:message`; cả hai nhận `conversation:updated` |
| An gửi lại đúng `clientMsgId` đó | Ack trả về tin cũ, `messages` không dài thêm |
| An gửi tin `type: "song"` | Bình nhận thẻ bài hát đủ metadata |
| In `unreadCount` của Bình | Bằng số tin An gửi, vì Bình chưa mở cuộc trò chuyện |
| Bình gọi `conversation:open` rồi in lại | `unreadCount` về 0 |
| An gửi 12 tin liên tiếp | Hai tin cuối bị từ chối `RATE_LIMITED` |
| Tắt server, bật lại, gọi `conversation:open` | Lịch sử còn nguyên từ `data.json` |

Kịch bản chạy tuần tự, mỗi bước in một dòng có tiền tố người thực hiện.
Bước cuối cần chạy tay (tắt/bật server rồi `npm run demo` lần nữa).

## 10. Việc phía Flutter sau khi có server

Nằm ngoài phạm vi bản thiết kế này, nhưng hợp đồng ở mục 5 là thứ FE bám vào.
Ba điểm FE bắt buộc phải làm đúng:

1. **Dedupe theo `clientMsgId`** khi nhận `chat:message`, vì người gửi cũng nhận broadcast của mình.
2. **Gọi lại `conversation:open` trong `onConnect`**, vì socket bị đá khỏi room khi disconnect.
3. **Payload luôn là `Map`**, kể cả khi rỗng thì gửi `{}` chứ không gửi `null`.
