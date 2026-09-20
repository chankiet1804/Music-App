# Socket.IO Chat Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng server Socket.IO chat 1-1 (text + chia sẻ bài hát) cho app Flutter, lưu dữ liệu trong RAM và ghi ra `data.json`.

**Architecture:** Bốn module tách theo trách nhiệm — `config.js` (hằng số), `store.js` (hai `Map` + đọc/ghi file), `model.js` (hàm thuần biến đổi dữ liệu), `server.js` (chỗ duy nhất chạm Socket.IO). Thêm `scripts/demo-client.js` giả lập hai người dùng để kiểm chứng toàn bộ hợp đồng event mà không cần mở Flutter.

**Tech Stack:** Node.js 24 ESM, `socket.io@^4.8` (dependency), `socket.io-client@^4.8` (devDependency). Không framework, không DB, không eslint/prettier/dotenv.

**Spec:** [docs/superpowers/specs/2026-09-19-socketio-chat-backend-design.md](../specs/2026-09-19-socketio-chat-backend-design.md)

## Global Constraints

- Vị trí: `C:\development\music-app-backend` — **repo git riêng**, không nằm trong repo `music-app`.
- ESM: `package.json` có `"type": "module"`. Mọi import dùng cú pháp `import`.
- **Không cấu hình CORS** — chỉ có client Android và iOS.
- Comment trong code viết bằng **tiếng Anh**, ngắn gọn. Không thêm comment thừa.
- Không tin payload client: `id`, `senderId`, `senderName`, `sentAt` luôn do server sinh.
- `name` cắt còn `MAX_NAME = 30`, `text` trim rồi cắt còn `MAX_TEXT = 500`.
- Giữ `KEEP_MESSAGES = 200` tin mỗi cuộc trò chuyện, `conversation:open` trả `HISTORY_LIMIT = 50` tin cuối.
- Rate limit `chat:send`: `RATE_LIMIT_MAX = 10` tin trong `RATE_LIMIT_WINDOW_MS = 10000` ms trên mỗi socket.
- `data.json` và `data.json.tmp` nằm trong `.gitignore`.
- Commit message: **không** có trailer AI co-author, không có dòng "Generated with".
- Đường dẫn trong lệnh kiểm chứng dùng scratchpad:
  `C:\Users\admin\AppData\Local\Temp\claude\c--development-music-app\fe4c13e0-3927-4aa5-a997-e3106935d643\scratchpad`

## File Structure

| File | Trách nhiệm | Phụ thuộc |
|---|---|---|
| `config.js` | Hằng số cấu hình, đọc biến môi trường | không |
| `store.js` | Sở hữu `users` / `conversations` Map và file `data.json` | `config.js` |
| `model.js` | Hàm thuần: id hội thoại, dựng message, summary, unread | `config.js`, `store.js` |
| `server.js` | HTTP server + `/health` + toàn bộ socket event | tất cả |
| `scripts/demo-client.js` | Kịch bản kiểm chứng hai người dùng | `socket.io-client` |
| `package.json`, `.gitignore`, `README.md` | Vận hành và tài liệu | — |

---

### Task 1: Scaffold repo, config.js

**Files:**
- Create: `C:\development\music-app-backend\package.json`
- Create: `C:\development\music-app-backend\.gitignore`
- Create: `C:\development\music-app-backend\config.js`

**Interfaces:**
- Consumes: không có (task đầu tiên)
- Produces: `config.js` export các named const: `PORT: number`, `HOST: string`, `DATA_FILE: string`, `FLUSH_DELAY_MS: number`, `MAX_TEXT: number`, `MAX_NAME: number`, `KEEP_MESSAGES: number`, `HISTORY_LIMIT: number`, `RATE_LIMIT_MAX: number`, `RATE_LIMIT_WINDOW_MS: number`

- [ ] **Step 1: Tạo thư mục và git repo**

```bash
mkdir -p /c/development/music-app-backend/scripts
cd /c/development/music-app-backend
git init -b main
```

- [ ] **Step 2: Tạo `package.json`**

```json
{
  "name": "music-app-backend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "description": "Socket.IO chat server for the music-app Flutter client",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js",
    "demo": "node scripts/demo-client.js"
  },
  "dependencies": {
    "socket.io": "^4.8.1"
  },
  "devDependencies": {
    "socket.io-client": "^4.8.1"
  }
}
```

- [ ] **Step 3: Cài dependency**

Run: `cd /c/development/music-app-backend && npm install`
Expected: tạo `node_modules/` và `package-lock.json`, không có lỗi.

- [ ] **Step 4: Tạo `.gitignore`**

```gitignore
node_modules/
data.json
data.json.tmp
*.log
.DS_Store
```

- [ ] **Step 5: Tạo `config.js`**

```js
// All tunables live here so nothing else reads process.env.

export const PORT = Number(process.env.PORT ?? 3000);
export const HOST = "0.0.0.0";
export const DATA_FILE = process.env.DATA_FILE ?? "./data.json";

// Disk writes are debounced: ten quick messages cost one write.
export const FLUSH_DELAY_MS = 300;

export const MAX_TEXT = 500;
export const MAX_NAME = 30;

// Kept per conversation in memory and on disk.
export const KEEP_MESSAGES = 200;
// Returned by conversation:open.
export const HISTORY_LIMIT = 50;

export const RATE_LIMIT_MAX = 10;
export const RATE_LIMIT_WINDOW_MS = 10_000;
```

- [ ] **Step 6: Kiểm chứng config đọc được**

```bash
cd /c/development/music-app-backend
node --input-type=module -e "const c = await import('./config.js'); console.log(c.PORT, c.HOST, c.KEEP_MESSAGES, c.HISTORY_LIMIT, c.RATE_LIMIT_MAX);"
```

Expected: in ra `3000 0.0.0.0 200 50 10`

- [ ] **Step 7: Commit**

```bash
cd /c/development/music-app-backend
git add package.json package-lock.json .gitignore config.js
git commit -m "chore: scaffold chat backend with socket.io and config"
```

---

### Task 2: store.js — Map và lưu xuống data.json

**Files:**
- Create: `C:\development\music-app-backend\store.js`

**Interfaces:**
- Consumes: `config.js` → `DATA_FILE`, `FLUSH_DELAY_MS`
- Produces:
  - `users: Map<string, {userId: string, name: string, online: boolean}>`
  - `conversations: Map<string, {id: string, memberIds: string[], messages: object[], lastMessageAt: number, lastReadAt: Record<string, number>}>`
  - `loadData(): void` — đọc file vào hai Map, đặt mọi `online` về `false`
  - `scheduleSave(): void` — hẹn ghi debounce
  - `saveNow(): void` — ghi ngay, huỷ lịch hẹn đang chờ

- [ ] **Step 1: Viết `store.js`**

```js
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";

import { DATA_FILE, FLUSH_DELAY_MS } from "./config.js";

export const users = new Map();
export const conversations = new Map();

export function loadData() {
  if (!existsSync(DATA_FILE)) return;
  try {
    const raw = JSON.parse(readFileSync(DATA_FILE, "utf8"));
    for (const [id, user] of Object.entries(raw.users ?? {})) {
      // online only means something within the current run.
      users.set(id, { ...user, online: false });
    }
    for (const [id, conversation] of Object.entries(raw.conversations ?? {})) {
      conversations.set(id, conversation);
    }
  } catch (err) {
    // A corrupted file must not stop the server from booting.
    console.error(`cannot read ${DATA_FILE}, starting empty:`, err.message);
  }
}

let timer = null;

export function scheduleSave() {
  if (timer) return; // a flush is already pending
  timer = setTimeout(saveNow, FLUSH_DELAY_MS);
}

export function saveNow() {
  if (timer) {
    clearTimeout(timer);
    timer = null;
  }
  const payload = {
    users: Object.fromEntries(users),
    conversations: Object.fromEntries(conversations),
  };
  // Write to a temp file first: a crash mid-write cannot truncate the real one.
  writeFileSync(`${DATA_FILE}.tmp`, JSON.stringify(payload));
  renameSync(`${DATA_FILE}.tmp`, DATA_FILE);
}
```

- [ ] **Step 2: Viết script kiểm chứng vòng đời lưu/đọc**

```bash
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
cat > "$SCRATCH/check-store.mjs" <<'EOF'
import assert from "node:assert/strict";
import { rmSync } from "node:fs";

const BASE = "file:///C:/development/music-app-backend/";
process.env.DATA_FILE = "C:/development/music-app-backend/data.check.json";

const store = await import(`${BASE}store.js`);

store.users.set("u_an", { userId: "u_an", name: "An", online: true });
store.conversations.set("c_u_an_u_binh", {
  id: "c_u_an_u_binh",
  memberIds: ["u_an", "u_binh"],
  messages: [{ id: "m1", text: "hi" }],
  lastMessageAt: 1,
  lastReadAt: { u_an: 1, u_binh: 0 },
});
store.saveNow();

// Fresh module instance = a fresh process would see the same thing.
const reloaded = await import(`${BASE}store.js?v=2`);
reloaded.loadData();

assert.equal(reloaded.users.get("u_an").name, "An");
assert.equal(reloaded.users.get("u_an").online, false, "online must reset on load");
assert.equal(reloaded.conversations.get("c_u_an_u_binh").messages.length, 1);

rmSync(process.env.DATA_FILE, { force: true });
console.log("store ok");
EOF
node "$SCRATCH/check-store.mjs"
```

Expected: in ra `store ok`, không có AssertionError.

- [ ] **Step 3: Kiểm chứng file hỏng không làm chết tiến trình**

```bash
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
echo 'not json at all' > /c/development/music-app-backend/data.broken.json
cat > "$SCRATCH/check-store-broken.mjs" <<'EOF'
process.env.DATA_FILE = "C:/development/music-app-backend/data.broken.json";
const store = await import("file:///C:/development/music-app-backend/store.js");
store.loadData();
console.log("survived, users =", store.users.size);
EOF
node "$SCRATCH/check-store-broken.mjs"
rm -f /c/development/music-app-backend/data.broken.json
```

Expected: in ra dòng `cannot read ... starting empty:` rồi `survived, users = 0`, exit code 0.

- [ ] **Step 4: Commit**

```bash
cd /c/development/music-app-backend
git add store.js
git commit -m "feat: add in-memory store with debounced json persistence"
```

---

### Task 3: model.js — logic thuần trên dữ liệu

**Files:**
- Create: `C:\development\music-app-backend\model.js`

**Interfaces:**
- Consumes: `config.js` → `MAX_TEXT`, `KEEP_MESSAGES`; `store.js` → `users`, `conversations`
- Produces:
  - `conversationId(a: string, b: string): string`
  - `getOrCreateConversation(a: string, b: string): Conversation`
  - `peerOf(conversation, userId): {userId, name, online}`
  - `unreadCountFor(conversation, userId): number`
  - `summaryFor(conversation, userId): {id, peer, lastMessage, unreadCount}`
  - `buildMessage(payload, sender, conversation): Message | null` — `sender` là `{userId, name}`
  - `appendMessage(conversation, message): void`
  - `markRead(conversation, userId, at?: number): void`

- [ ] **Step 1: Viết `model.js`**

```js
import { randomUUID } from "node:crypto";

import { KEEP_MESSAGES, MAX_TEXT } from "./config.js";
import { conversations, users } from "./store.js";

// Deterministic id: both sides always compute the same one.
export function conversationId(a, b) {
  return `c_${[a, b].sort().join("_")}`;
}

export function getOrCreateConversation(a, b) {
  const id = conversationId(a, b);
  if (!conversations.has(id)) {
    conversations.set(id, {
      id,
      memberIds: [a, b].sort(),
      messages: [],
      lastMessageAt: 0,
      lastReadAt: { [a]: 0, [b]: 0 },
    });
  }
  return conversations.get(id);
}

export function peerOf(conversation, userId) {
  const peerId = conversation.memberIds.find((id) => id !== userId);
  return users.get(peerId) ?? { userId: peerId, name: peerId, online: false };
}

export function unreadCountFor(conversation, userId) {
  const since = conversation.lastReadAt?.[userId] ?? 0;
  return conversation.messages.filter(
    (m) => m.senderId !== userId && m.sentAt > since,
  ).length;
}

// peer and unreadCount differ per member, so a summary is always per viewer.
export function summaryFor(conversation, userId) {
  return {
    id: conversation.id,
    peer: peerOf(conversation, userId),
    lastMessage: conversation.messages.at(-1) ?? null,
    unreadCount: unreadCountFor(conversation, userId),
  };
}

// Never trust the client payload: rebuild the message from scratch.
export function buildMessage(payload, sender, conversation) {
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

export function appendMessage(conversation, message) {
  conversation.messages = [...conversation.messages, message].slice(-KEEP_MESSAGES);
  conversation.lastMessageAt = message.sentAt;
  // Your own message counts as read by you.
  conversation.lastReadAt[message.senderId] = message.sentAt;
}

export function markRead(conversation, userId, at = Date.now()) {
  conversation.lastReadAt[userId] = at;
}
```

- [ ] **Step 2: Viết script kiểm chứng model**

```bash
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
cat > "$SCRATCH/check-model.mjs" <<'EOF'
import assert from "node:assert/strict";

const BASE = "file:///C:/development/music-app-backend/";
process.env.DATA_FILE = "C:/development/music-app-backend/data.never-written.json";

const { users } = await import(`${BASE}store.js`);
const m = await import(`${BASE}model.js`);

users.set("u_an", { userId: "u_an", name: "An", online: true });
users.set("u_binh", { userId: "u_binh", name: "Binh", online: false });

const an = { userId: "u_an", name: "An" };
const binh = { userId: "u_binh", name: "Binh" };

// Deterministic id, whoever opens first.
assert.equal(m.conversationId("u_binh", "u_an"), "c_u_an_u_binh");
assert.equal(m.conversationId("u_an", "u_binh"), "c_u_an_u_binh");

const conv = m.getOrCreateConversation("u_an", "u_binh");
assert.equal(m.getOrCreateConversation("u_binh", "u_an"), conv, "must reuse");

// Server owns id/senderId/sentAt; text is trimmed and capped.
const text = m.buildMessage(
  { clientMsgId: "cm1", type: "text", text: "  hay lam  ", senderId: "HACKED", id: "HACKED" },
  an,
  conv,
);
assert.equal(text.text, "hay lam");
assert.equal(text.senderId, "u_an");
assert.notEqual(text.id, "HACKED");
assert.equal(text.clientMsgId, "cm1");

assert.equal(m.buildMessage({ type: "text", text: "   " }, an, conv), null, "empty text rejected");
assert.equal(m.buildMessage({ type: "song", song: {} }, an, conv), null, "song needs an id");
assert.equal(
  m.buildMessage({ type: "text", text: "x".repeat(600) }, an, conv).text.length,
  500,
  "text capped at MAX_TEXT",
);

const song = m.buildMessage(
  { clientMsgId: "cm2", type: "song", text: "bai nay hay", song: { id: 1121429554, title: "T" } },
  an,
  conv,
);
assert.equal(song.type, "song");
assert.equal(song.song.id, "1121429554", "song.id coerced to string");
assert.equal(song.song.artist, "", "missing fields become empty strings");

m.appendMessage(conv, text);
m.appendMessage(conv, song);

// An sent both, so An has nothing unread and Binh has two.
assert.equal(m.unreadCountFor(conv, "u_an"), 0);
assert.equal(m.unreadCountFor(conv, "u_binh"), 2);

const forBinh = m.summaryFor(conv, "u_binh");
assert.equal(forBinh.peer.userId, "u_an");
assert.equal(forBinh.peer.name, "An");
assert.equal(forBinh.unreadCount, 2);
assert.equal(forBinh.lastMessage.type, "song");
assert.equal(m.summaryFor(conv, "u_an").peer.userId, "u_binh");

m.markRead(conv, "u_binh");
assert.equal(m.unreadCountFor(conv, "u_binh"), 0, "markRead clears unread");

// Unknown peer still yields a usable placeholder.
const ghost = m.getOrCreateConversation("u_an", "u_ghost");
assert.equal(m.peerOf(ghost, "u_an").name, "u_ghost");
assert.equal(m.peerOf(ghost, "u_an").online, false);

console.log("model ok");
EOF
node "$SCRATCH/check-model.mjs"
```

Expected: in ra `model ok`, không có AssertionError.

- [ ] **Step 3: Kiểm chứng cắt lịch sử ở `KEEP_MESSAGES`**

```bash
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
cat > "$SCRATCH/check-keep.mjs" <<'EOF'
import assert from "node:assert/strict";

const BASE = "file:///C:/development/music-app-backend/";
process.env.DATA_FILE = "C:/development/music-app-backend/data.never-written.json";

const m = await import(`${BASE}model.js`);
const conv = m.getOrCreateConversation("u_an", "u_binh");
const an = { userId: "u_an", name: "An" };

for (let i = 0; i < 250; i++) {
  m.appendMessage(conv, m.buildMessage({ clientMsgId: `c${i}`, type: "text", text: `m${i}` }, an, conv));
}

assert.equal(conv.messages.length, 200, "trimmed to KEEP_MESSAGES");
assert.equal(conv.messages.at(-1).text, "m249", "newest kept");
assert.equal(conv.messages.at(0).text, "m50", "oldest dropped");
console.log("keep ok");
EOF
node "$SCRATCH/check-keep.mjs"
```

Expected: in ra `keep ok`.

- [ ] **Step 4: Commit**

```bash
cd /c/development/music-app-backend
git add model.js
git commit -m "feat: add conversation and message model helpers"
```

---

### Task 4: server.js — HTTP, auth, presence, event hội thoại

**Files:**
- Create: `C:\development\music-app-backend\server.js`

**Interfaces:**
- Consumes: `config.js`, `store.js` (`users`, `conversations`, `loadData`, `scheduleSave`), `model.js` (`getOrCreateConversation`, `summaryFor`, `markRead`)
- Produces: server lắng nghe trên `HOST:PORT`; event `user:list`, `conversation:list`, `conversation:open`, `conversation:close`, `presence:update`, `conversation:updated`; route `GET /health`

Task này **chưa** làm `chat:send` / `chat:typing` / `chat:read` — Task 5 thêm vào cùng file.

- [ ] **Step 1: Viết `server.js`**

```js
import { createServer } from "node:http";
import { networkInterfaces } from "node:os";

import { Server } from "socket.io";

import { HISTORY_LIMIT, HOST, MAX_NAME, PORT } from "./config.js";
import { conversations, loadData, scheduleSave, users } from "./store.js";
import { getOrCreateConversation, markRead, summaryFor } from "./model.js";

loadData();

const httpServer = createServer((req, res) => {
  if (req.url === "/health") return res.end("ok");
  res.writeHead(404).end();
});

// No CORS: the only clients are the Android and iOS apps.
const io = new Server(httpServer);

// ---------- auth ----------
io.use((socket, next) => {
  const { userId, name } = socket.handshake.auth ?? {};
  if (typeof userId !== "string" || !userId.trim()) {
    return next(new Error("unauthorized"));
  }
  if (typeof name !== "string" || !name.trim()) {
    return next(new Error("unauthorized"));
  }
  socket.data.user = { userId: userId.trim(), name: name.trim().slice(0, MAX_NAME) };
  next();
});

// ---------- events ----------
io.on("connection", (socket) => {
  const me = socket.data.user;

  users.set(me.userId, { ...me, online: true });
  // A personal room reaches this user wherever they are, even outside a chat.
  socket.join(`user:${me.userId}`);
  socket.broadcast.emit("presence:update", { userId: me.userId, online: true });
  scheduleSave();
  console.log(`+ ${me.userId} (${me.name}) connected`);

  socket.on("user:list", (_payload, ack) => {
    const others = [...users.values()].filter((u) => u.userId !== me.userId);
    ack?.({ ok: true, users: others });
  });

  socket.on("conversation:list", (_payload, ack) => {
    const mine = [...conversations.values()]
      .filter((c) => c.memberIds.includes(me.userId))
      .sort((a, b) => b.lastMessageAt - a.lastMessageAt)
      .map((c) => summaryFor(c, me.userId));
    ack?.({ ok: true, conversations: mine });
  });

  socket.on("conversation:open", ({ peerId } = {}, ack) => {
    if (typeof peerId !== "string" || !peerId || peerId === me.userId) {
      return ack?.({ ok: false, error: "BAD_PEER" });
    }
    const conversation = getOrCreateConversation(me.userId, peerId);
    socket.join(conversation.id);
    markRead(conversation, me.userId);
    scheduleSave();

    ack?.({
      ok: true,
      conversation: summaryFor(conversation, me.userId),
      messages: conversation.messages.slice(-HISTORY_LIMIT),
    });
    // Clear this user's badge on their other screens right away.
    io.to(`user:${me.userId}`).emit("conversation:updated", {
      conversation: summaryFor(conversation, me.userId),
    });
  });

  socket.on("conversation:close", ({ conversationId } = {}, ack) => {
    // The socket stays alive so conversation:updated still reaches this user.
    if (typeof conversationId === "string") socket.leave(conversationId);
    ack?.({ ok: true });
  });

  socket.on("disconnect", () => {
    users.set(me.userId, { ...me, online: false });
    socket.broadcast.emit("presence:update", { userId: me.userId, online: false });
    scheduleSave();
    console.log(`- ${me.userId} disconnected`);
  });
});

function lanAddresses() {
  return Object.values(networkInterfaces())
    .flat()
    .filter((net) => net && net.family === "IPv4" && !net.internal)
    .map((net) => net.address);
}

httpServer.listen(PORT, HOST, () => {
  console.log(`chat server ready on port ${PORT}`);
  console.log(`  localhost : http://localhost:${PORT}`);
  console.log(`  emulator  : http://10.0.2.2:${PORT}`);
  for (const address of lanAddresses()) {
    console.log(`  LAN       : http://${address}:${PORT}`);
  }
});
```

- [ ] **Step 2: Khởi động server và kiểm chứng `/health`**

```bash
cd /c/development/music-app-backend
DATA_FILE=./data.dev.json node server.js &
sleep 2
curl -s http://localhost:3000/health; echo
```

Expected: log khởi động in `chat server ready on port 3000` kèm các dòng localhost / emulator / LAN; `curl` trả về `ok`.

- [ ] **Step 3: Kiểm chứng auth và event hội thoại bằng client tạm**

```bash
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
cat > "$SCRATCH/check-server4.mjs" <<'EOF'
import assert from "node:assert/strict";

const { io } = await import("file:///C:/development/music-app-backend/node_modules/socket.io-client/build/esm/index.js");
const URL = "http://localhost:3000";

function connect(userId, name) {
  return new Promise((resolve, reject) => {
    const s = io(URL, { transports: ["websocket"], forceNew: true, auth: { userId, name } });
    s.on("connect", () => resolve(s));
    s.on("connect_error", reject);
  });
}

// Missing auth must be refused.
await assert.rejects(() => connect(undefined, undefined), /unauthorized/);
console.log("auth rejects missing credentials");

const an = await connect("u_an", "An");
const binh = await connect("u_binh", "Binh");

const list = await an.emitWithAck("user:list", {});
assert.ok(list.ok);
assert.ok(list.users.some((u) => u.userId === "u_binh" && u.online === true));
assert.ok(!list.users.some((u) => u.userId === "u_an"), "self excluded");
console.log("user:list ok");

const bad = await an.emitWithAck("conversation:open", { peerId: "u_an" });
assert.equal(bad.error, "BAD_PEER");

const opened = await an.emitWithAck("conversation:open", { peerId: "u_binh" });
assert.ok(opened.ok);
assert.equal(opened.conversation.id, "c_u_an_u_binh");
assert.equal(opened.conversation.peer.userId, "u_binh");
assert.ok(Array.isArray(opened.messages));
console.log("conversation:open ok ->", opened.conversation.id);

const listed = await an.emitWithAck("conversation:list", {});
assert.ok(listed.conversations.some((c) => c.id === "c_u_an_u_binh"));
console.log("conversation:list ok");

assert.deepEqual(await an.emitWithAck("conversation:close", { conversationId: "c_u_an_u_binh" }), { ok: true });

// Presence reaches the other side.
const gone = new Promise((r) => binh.on("presence:update", (p) => p.online === false && r(p)));
an.disconnect();
const presence = await gone;
assert.equal(presence.userId, "u_an");
console.log("presence:update ok");

binh.disconnect();
console.log("server task 4 ok");
EOF
node "$SCRATCH/check-server4.mjs"
```

Expected: in lần lượt `auth rejects missing credentials`, `user:list ok`, `conversation:open ok -> c_u_an_u_binh`, `conversation:list ok`, `presence:update ok`, `server task 4 ok`.

- [ ] **Step 4: Dừng server và dọn file dev**

```bash
kill %1 2>/dev/null || true
rm -f /c/development/music-app-backend/data.dev.json
```

- [ ] **Step 5: Commit**

```bash
cd /c/development/music-app-backend
git add server.js
git commit -m "feat: add socket server with auth, presence and conversation events"
```

---

### Task 5: server.js — chat:send, typing, read, rate limit

**Files:**
- Modify: `C:\development\music-app-backend\server.js`

**Interfaces:**
- Consumes: Task 4's `server.js`; `model.js` → thêm `appendMessage`, `buildMessage`; `config.js` → thêm `RATE_LIMIT_MAX`, `RATE_LIMIT_WINDOW_MS`
- Produces: event `chat:send`, `chat:typing`, `chat:read`; broadcast `chat:message`, `conversation:updated`, `chat:typing`, `chat:read`

- [ ] **Step 1: Mở rộng import ở đầu `server.js`**

Thay hai dòng import `config.js` và `model.js` bằng:

```js
import {
  HISTORY_LIMIT,
  HOST,
  MAX_NAME,
  PORT,
  RATE_LIMIT_MAX,
  RATE_LIMIT_WINDOW_MS,
} from "./config.js";
```

```js
import {
  appendMessage,
  buildMessage,
  getOrCreateConversation,
  markRead,
  summaryFor,
} from "./model.js";
```

- [ ] **Step 2: Thêm helper rate limit ngay trước `io.on("connection", ...)`**

```js
// One sliding window per socket, dropped automatically when the socket dies.
function underRateLimit(socket) {
  const now = Date.now();
  const recent = (socket.data.sentAt ?? []).filter(
    (t) => now - t < RATE_LIMIT_WINDOW_MS,
  );
  if (recent.length >= RATE_LIMIT_MAX) {
    socket.data.sentAt = recent;
    return false;
  }
  socket.data.sentAt = [...recent, now];
  return true;
}

// The conversation list must update for both sides, each with their own counts.
function broadcastConversation(conversation) {
  for (const memberId of conversation.memberIds) {
    io.to(`user:${memberId}`).emit("conversation:updated", {
      conversation: summaryFor(conversation, memberId),
    });
  }
}
```

- [ ] **Step 3: Rút gọn `conversation:open` để dùng helper**

Thay khối `io.to(\`user:${me.userId}\`).emit("conversation:updated", ...)` ở cuối handler `conversation:open` bằng:

```js
    broadcastConversation(conversation);
```

- [ ] **Step 4: Thêm ba handler mới, đặt ngay trước `socket.on("disconnect", ...)`**

```js
  socket.on("chat:send", (payload = {}, ack) => {
    if (!underRateLimit(socket)) return ack?.({ ok: false, error: "RATE_LIMITED" });

    const conversation = conversations.get(String(payload.conversationId ?? ""));
    if (!conversation) return ack?.({ ok: false, error: "NO_CONVERSATION" });
    if (!conversation.memberIds.includes(me.userId)) {
      return ack?.({ ok: false, error: "NOT_A_MEMBER" });
    }

    // Retries and flaky networks resend the same message: return the stored one.
    const existing = conversation.messages.find(
      (m) => m.clientMsgId === payload.clientMsgId,
    );
    if (existing) return ack?.({ ok: true, message: existing });

    const message = buildMessage(payload, me, conversation);
    if (!message) return ack?.({ ok: false, error: "BAD_MESSAGE" });

    appendMessage(conversation, message);
    scheduleSave();

    // Goes to the sender too, so the client must dedupe by clientMsgId.
    io.to(conversation.id).emit("chat:message", message);
    broadcastConversation(conversation);
    ack?.({ ok: true, message });
    console.log(`  ${me.userId} -> ${conversation.id} [${message.type}]`);
  });

  socket.on("chat:typing", ({ conversationId } = {}) => {
    if (typeof conversationId !== "string") return;
    // Typing is disposable: drop it rather than queue it.
    socket
      .to(conversationId)
      .volatile.emit("chat:typing", { conversationId, userId: me.userId });
  });

  socket.on("chat:read", ({ conversationId } = {}, ack) => {
    const conversation = conversations.get(String(conversationId ?? ""));
    if (!conversation || !conversation.memberIds.includes(me.userId)) {
      return ack?.({ ok: true });
    }
    const readAt = Date.now();
    markRead(conversation, me.userId, readAt);
    scheduleSave();

    socket.to(conversation.id).emit("chat:read", {
      conversationId: conversation.id,
      userId: me.userId,
      readAt,
    });
    broadcastConversation(conversation);
    ack?.({ ok: true });
  });
```

- [ ] **Step 5: Khởi động lại server**

```bash
cd /c/development/music-app-backend
DATA_FILE=./data.dev.json node server.js &
sleep 2
curl -s http://localhost:3000/health; echo
```

Expected: `ok`.

- [ ] **Step 6: Kiểm chứng gửi tin, dedupe, unread, rate limit**

```bash
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
cat > "$SCRATCH/check-server5.mjs" <<'EOF'
import assert from "node:assert/strict";

const { io } = await import("file:///C:/development/music-app-backend/node_modules/socket.io-client/build/esm/index.js");
const URL = "http://localhost:3000";

function connect(userId, name) {
  return new Promise((resolve, reject) => {
    const s = io(URL, { transports: ["websocket"], forceNew: true, auth: { userId, name } });
    s.on("connect", () => resolve(s));
    s.on("connect_error", reject);
  });
}

const an = await connect("u_an", "An");
const binh = await connect("u_binh", "Binh");

const CONV = "c_u_an_u_binh";
await an.emitWithAck("conversation:open", { peerId: "u_binh" });

// Binh is NOT in the conversation room: only the personal room reaches them.
const binhUpdates = [];
binh.on("conversation:updated", (p) => binhUpdates.push(p.conversation));

const anMessages = [];
an.on("chat:message", (m) => anMessages.push(m));

assert.equal((await an.emitWithAck("chat:send", { conversationId: "c_nope", type: "text", text: "x" })).error, "NO_CONVERSATION");
assert.equal((await an.emitWithAck("chat:send", { conversationId: CONV, type: "text", text: "  " })).error, "BAD_MESSAGE");
assert.equal((await an.emitWithAck("chat:send", { conversationId: CONV, type: "song", song: {} })).error, "BAD_MESSAGE");
console.log("validation ok");

const sent = await an.emitWithAck("chat:send", { clientMsgId: "cm-1", conversationId: CONV, type: "text", text: "hay lam" });
assert.ok(sent.ok);
assert.equal(sent.message.senderId, "u_an");
assert.equal(sent.message.senderName, "An");

const again = await an.emitWithAck("chat:send", { clientMsgId: "cm-1", conversationId: CONV, type: "text", text: "hay lam" });
assert.equal(again.message.id, sent.message.id, "same clientMsgId returns the stored message");
console.log("dedupe ok");

const shared = await an.emitWithAck("chat:send", {
  clientMsgId: "cm-2", conversationId: CONV, type: "song", text: "bai nay hay ne",
  song: { id: "1121429554", title: "Chung Ta Cua Tuong Lai", artist: "Son Tung M-TP", image: "https://x/y.jpg" },
});
assert.equal(shared.message.song.title, "Chung Ta Cua Tuong Lai");
console.log("song share ok");

await new Promise((r) => setTimeout(r, 300));

// The sender receives their own broadcast; two sends produced two messages.
assert.equal(anMessages.length, 2, `sender sees own broadcast, got ${anMessages.length}`);

const last = binhUpdates.at(-1);
assert.equal(last.id, CONV);
assert.equal(last.peer.userId, "u_an");
assert.equal(last.unreadCount, 2, `Binh has 2 unread, got ${last.unreadCount}`);
assert.equal(last.lastMessage.type, "song");
console.log("unread ok ->", last.unreadCount);

const afterOpen = await binh.emitWithAck("conversation:open", { peerId: "u_an" });
assert.equal(afterOpen.conversation.unreadCount, 0, "opening clears unread");
assert.equal(afterOpen.messages.length, 2);
console.log("open clears unread ok");

// chat:read reaches the peer.
const readSeen = new Promise((r) => an.on("chat:read", r));
await binh.emitWithAck("chat:read", { conversationId: CONV });
const readEvt = await readSeen;
assert.equal(readEvt.userId, "u_binh");
console.log("chat:read ok");

// typing is relayed to the peer only.
const typingSeen = new Promise((r) => binh.on("chat:typing", r));
an.emit("chat:typing", { conversationId: CONV });
const typing = await typingSeen;
assert.equal(typing.userId, "u_an");
console.log("chat:typing ok");

// 10 allowed per 10s; this socket already used 4 sends above.
let limited = 0;
for (let i = 0; i < 12; i++) {
  const res = await an.emitWithAck("chat:send", { clientMsgId: `rl-${i}`, conversationId: CONV, type: "text", text: `m${i}` });
  if (res.error === "RATE_LIMITED") limited++;
}
assert.ok(limited > 0, "rate limit must kick in");
console.log("rate limit ok ->", limited, "rejected");

an.disconnect();
binh.disconnect();
console.log("server task 5 ok");
EOF
node "$SCRATCH/check-server5.mjs"
```

Expected: in lần lượt `validation ok`, `dedupe ok`, `song share ok`, `unread ok -> 2`, `open clears unread ok`, `chat:read ok`, `chat:typing ok`, `rate limit ok -> N rejected` (N ≥ 1), `server task 5 ok`.

- [ ] **Step 7: Kiểm chứng lịch sử sống qua restart**

```bash
kill %1 2>/dev/null || true
sleep 1
cd /c/development/music-app-backend
DATA_FILE=./data.dev.json node server.js &
sleep 2
SCRATCH="/c/Users/admin/AppData/Local/Temp/claude/c--development-music-app/fe4c13e0-3927-4aa5-a997-e3106935d643/scratchpad"
cat > "$SCRATCH/check-restart.mjs" <<'EOF'
import assert from "node:assert/strict";

const { io } = await import("file:///C:/development/music-app-backend/node_modules/socket.io-client/build/esm/index.js");
const s = io("http://localhost:3000", { transports: ["websocket"], forceNew: true, auth: { userId: "u_an", name: "An" } });
await new Promise((r) => s.on("connect", r));

const opened = await s.emitWithAck("conversation:open", { peerId: "u_binh" });
assert.ok(opened.messages.length > 0, "history survived the restart");
console.log("restart ok ->", opened.messages.length, "messages restored");

// The user list survives too, only the online flag resets.
const list = await s.emitWithAck("user:list", {});
assert.ok(list.users.some((u) => u.userId === "u_binh"), "known users survived");
assert.equal(list.users.find((u) => u.userId === "u_binh").online, false);
console.log("users restored ok");

s.disconnect();
EOF
node "$SCRATCH/check-restart.mjs"
kill %1 2>/dev/null || true
rm -f /c/development/music-app-backend/data.dev.json
```

Expected: `restart ok -> N messages restored` (N ≥ 2) và `users restored ok`.

- [ ] **Step 8: Commit**

```bash
cd /c/development/music-app-backend
git add server.js
git commit -m "feat: add chat send, typing, read and rate limiting"
```

---

### Task 6: demo-client.js và README

**Files:**
- Create: `C:\development\music-app-backend\scripts\demo-client.js`
- Create: `C:\development\music-app-backend\README.md`

**Interfaces:**
- Consumes: server đang chạy ở `http://localhost:3000`; `socket.io-client`
- Produces: `npm run demo` chạy hết kịch bản mục 9 của spec và in log từng bước

- [ ] **Step 1: Viết `scripts/demo-client.js`**

```js
// Two simulated users running the whole contract, so the server can be
// verified without opening the Flutter app. Start the server first.
import { io } from "socket.io-client";

const URL = process.env.CHAT_URL ?? "http://localhost:3000";

function connect(userId, name) {
  return new Promise((resolve, reject) => {
    const socket = io(URL, {
      transports: ["websocket"],
      forceNew: true,
      auth: { userId, name },
    });
    socket.on("connect", () => resolve(socket));
    socket.on("connect_error", reject);
  });
}

function log(who, line) {
  console.log(`[${who.padEnd(6)}] ${line}`);
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const an = await connect("u_an", "An");
const binh = await connect("u_binh", "Binh");
log("An", `connected as ${an.id}`);
log("Binh", `connected as ${binh.id}`);

binh.on("chat:message", (m) => {
  const body = m.type === "song" ? `SONG "${m.song.title}" - ${m.song.artist}` : `"${m.text}"`;
  log("Binh", `<- chat:message from ${m.senderName}: ${body}`);
});
binh.on("conversation:updated", ({ conversation }) => {
  log("Binh", `<- conversation:updated unread=${conversation.unreadCount}`);
});
an.on("chat:message", (m) => log("An", `<- chat:message (own broadcast) clientMsgId=${m.clientMsgId}`));

const people = await an.emitWithAck("user:list", {});
log("An", `user:list -> ${people.users.map((u) => `${u.name}(${u.online ? "online" : "offline"})`).join(", ")}`);

const opened = await an.emitWithAck("conversation:open", { peerId: "u_binh" });
log("An", `conversation:open -> ${opened.conversation.id}, ${opened.messages.length} messages in history`);

const first = await an.emitWithAck("chat:send", {
  clientMsgId: `demo-text-${Date.now()}`,
  conversationId: opened.conversation.id,
  type: "text",
  text: "nghe thu bai nay di",
});
log("An", `chat:send text -> ok=${first.ok} id=${first.message.id}`);

const retry = await an.emitWithAck("chat:send", {
  clientMsgId: first.message.clientMsgId,
  conversationId: opened.conversation.id,
  type: "text",
  text: "nghe thu bai nay di",
});
log("An", `resend same clientMsgId -> same id? ${retry.message.id === first.message.id}`);

const shared = await an.emitWithAck("chat:send", {
  clientMsgId: `demo-song-${Date.now()}`,
  conversationId: opened.conversation.id,
  type: "song",
  text: "bai nay hay ne",
  song: {
    id: "1121429554",
    title: "Chung Ta Cua Tuong Lai",
    artist: "Son Tung M-TP",
    image: "https://photo-resize-zmp3.zmdcdn.me/w600_r1x1_jpeg/cover.jpg",
  },
});
log("An", `chat:send song -> ok=${shared.ok} song.id=${shared.message.song.id}`);

await wait(300);

const before = await binh.emitWithAck("conversation:list", {});
log("Binh", `conversation:list -> unread=${before.conversations[0]?.unreadCount}`);

const binhOpened = await binh.emitWithAck("conversation:open", { peerId: "u_an" });
log("Binh", `conversation:open -> unread now ${binhOpened.conversation.unreadCount}`);

binh.emit("chat:typing", { conversationId: opened.conversation.id });
log("Binh", "chat:typing sent");

log("An", "sending 12 messages in a row to trip the rate limit...");
let rejected = 0;
for (let i = 0; i < 12; i++) {
  const res = await an.emitWithAck("chat:send", {
    clientMsgId: `demo-rl-${Date.now()}-${i}`,
    conversationId: opened.conversation.id,
    type: "text",
    text: `spam ${i}`,
  });
  if (res.error === "RATE_LIMITED") rejected++;
}
log("An", `rate limited ${rejected} of 12`);

await wait(300);
an.disconnect();
binh.disconnect();
console.log("\ndemo finished. Restart the server and run it again: history must survive.");
process.exit(0);
```

- [ ] **Step 2: Chạy demo**

```bash
cd /c/development/music-app-backend
node server.js &
sleep 2
npm run demo
```

Expected log có đủ các dòng: `connected as ...` cho cả hai; `user:list -> Binh(online)`; `conversation:open -> c_u_an_u_binh`; `chat:send text -> ok=true`; `resend same clientMsgId -> same id? true`; `chat:send song -> ok=true song.id=1121429554`; Binh nhận `<- chat:message ... SONG "Chung Ta Cua Tuong Lai"`; `conversation:list -> unread=2`; `conversation:open -> unread now 0`; `rate limited N of 12` với N ≥ 1.

- [ ] **Step 3: Kiểm chứng lịch sử sống qua restart bằng chính demo**

```bash
kill %1 2>/dev/null || true
sleep 1
cd /c/development/music-app-backend
node server.js &
sleep 2
npm run demo 2>&1 | grep "messages in history"
kill %1 2>/dev/null || true
```

Expected: `conversation:open -> c_u_an_u_binh, N messages in history` với **N > 0**, chứng minh `data.json` được đọc lại.

- [ ] **Step 4: Viết `README.md`**

````markdown
# music-app-backend

Server Socket.IO cho tính năng chat của app nghe nhạc Flutter: nhắn tin văn bản và
chia sẻ bài hát. Server là nguồn sự thật duy nhất của lịch sử tin nhắn.

Thiết kế chi tiết: `music-app/docs/superpowers/specs/2026-09-19-socketio-chat-backend-design.md`

## Chạy

```bash
npm install
npm start        # hoặc npm run dev để tự restart khi sửa code
```

Lúc khởi động server in ra các URL dùng được:

```
chat server ready on port 3000
  localhost : http://localhost:3000
  emulator  : http://10.0.2.2:3000     <- Android emulator
  LAN       : http://192.168.1.12:3000 <- máy thật cùng wifi
```

Kiểm tra server sống: `curl http://localhost:3000/health` trả về `ok`.

## Kiểm chứng không cần Flutter

```bash
npm run demo
```

Giả lập hai người dùng An và Bình chạy hết hợp đồng event và in log từng bước:
gửi tin, chia sẻ bài hát, chống trùng theo `clientMsgId`, đếm tin chưa đọc, rate limit.

## Kết nối từ Flutter

```dart
final socket = io.io(
  'http://192.168.1.12:3000', // IP LAN mà server in ra
  io.OptionBuilder()
      .setTransports(['websocket'])   // bắt buộc trên mobile
      .disableAutoConnect()
      .setAuth({'userId': 'u_an', 'name': 'An'})
      .setAckTimeout(5000)
      .build(),
);
```

Android cần bật `usesCleartextTraffic` khi test qua `http://`.

## Hợp đồng event

### Client → Server

| Event | Payload | Ack |
|---|---|---|
| `user:list` | `{}` | `{ ok, users }` |
| `conversation:list` | `{}` | `{ ok, conversations }` |
| `conversation:open` | `{ peerId }` | `{ ok, conversation, messages }` |
| `conversation:close` | `{ conversationId }` | `{ ok: true }` |
| `chat:send` | `{ clientMsgId, conversationId, type, text, song? }` | `{ ok, message }` |
| `chat:typing` | `{ conversationId }` | không có |
| `chat:read` | `{ conversationId }` | `{ ok: true }` |

### Server → Client

| Event | Payload |
|---|---|
| `chat:message` | một message |
| `conversation:updated` | `{ conversation }` |
| `chat:typing` | `{ conversationId, userId }` |
| `chat:read` | `{ conversationId, userId, readAt }` |
| `presence:update` | `{ userId, online }` |

### Mã lỗi

`BAD_PEER`, `NO_CONVERSATION`, `NOT_A_MEMBER`, `BAD_MESSAGE`, `RATE_LIMITED`.
Thiếu `userId` hoặc `name` trong `auth` thì bị từ chối ngay ở `connect_error`.

## Ba điều client bắt buộc làm đúng

1. **Dedupe theo `clientMsgId`** — `chat:message` gửi cho cả người gửi.
2. **Gọi lại `conversation:open` trong `onConnect`** — socket bị đá khỏi room khi disconnect.
3. **Payload luôn là `Map`**, rỗng thì gửi `{}` chứ không gửi `null`.

## Lưu trữ

Dữ liệu sống trong RAM, ghi ra `data.json` (debounce 300ms) cạnh `server.js`, đọc lại lúc khởi động.
File này nằm trong `.gitignore`. Muốn deploy thật thì đổi sang SQLite kèm ổ đĩa bền.

Đổi chỗ lưu: `DATA_FILE=./other.json npm start`. Đổi cổng: `PORT=4000 npm start`.
````

- [ ] **Step 5: Dọn dẹp và commit**

```bash
cd /c/development/music-app-backend
rm -f data.json data.json.tmp
git status --short
git add scripts/demo-client.js README.md
git commit -m "feat: add demo client script and readme"
```

Expected: `git status --short` **không** liệt kê `data.json` (đã bị `.gitignore` chặn).

---

## Self-Review

**Spec coverage:**

| Mục spec | Task |
|---|---|
| 2 — quyết định thiết kế (repo, ESM, deps, không CORS) | Task 1, Task 4 |
| 3 — cấu trúc thư mục, `config.js` | Task 1 |
| 4 — mô hình User / Conversation / Message / summary | Task 3 |
| 5 — hợp đồng event và mã lỗi | Task 4 (hội thoại), Task 5 (chat), README ở Task 6 |
| 6 — luồng từng event, thứ tự 10 bước của `chat:send` | Task 4, Task 5 |
| 7 — bền vững dữ liệu, tmp + rename, file hỏng không chết | Task 2 |
| 8 — scripts, `/health`, in IP LAN, log | Task 1, Task 4, Task 6 |
| 9 — kịch bản kiểm chứng | Task 6 (mỗi dòng bảng mục 9 có một dòng log tương ứng) |
| 10 — ba điều FE phải làm đúng | Task 6 (README) |

**Type consistency:** `summaryFor`, `markRead`, `appendMessage`, `buildMessage`,
`getOrCreateConversation`, `unreadCountFor`, `peerOf` — tên dùng ở Task 4 và 5 khớp
đúng tên định nghĩa ở Task 3. `scheduleSave` / `saveNow` / `loadData` khớp Task 2.
Hằng số dùng ở Task 3–5 đều có trong Task 1.

**Placeholder scan:** không có TBD/TODO; mọi step có lệnh chạy thật hoặc code đầy đủ.
