# FaithConnect — Messages (Unread, Schema, UX)

## Why unread was failing

The earlier implementation stored `unreadCount` on the shared chat document (`chats/{chatId}`). In a 1:1 conversation, unread is **per-user**, so resetting `unreadCount` when _either_ user opened the chat would clear the unread state for both users.

Additionally, the old `getUnreadCount()` computed unread by scanning all chats and querying message subcollections (`isRead == false`), which is expensive and prone to drift.

## Current Firestore structure (authoritative)

### Conversation header

`conversations/{conversationId}`

```js
{
  conversationId,
  participants: [userId1, userId2],
  lastMessage,
  lastMessageAt,
  lastSenderId
}
```

### Per-user metadata (source of truth for unread)

`users/{userId}/conversations/{conversationId}`

```js
{
  conversationId, otherUserId, lastReadAt, unreadCount, updatedAt;
}
```

> We keep writing legacy `chats/{chatId}` documents for compatibility during the hackathon, but the UI and badges should rely on the per-user metadata.

## Unread rules implemented

### On send (text/image/audio)

- Update `conversations/{conversationId}` with last message + timestamp.
- Sender metadata:
  - `lastReadAt = now`
  - `unreadCount = 0`
- Recipient metadata:
  - `unreadCount += 1`
  - do **not** modify `lastReadAt`

### On open chat

- Call `markConversationAsRead(conversationId, userId)`:
  - `unreadCount = 0`
  - `lastReadAt = now`

This resets unread **instantly** and remains correct across multiple devices.

## Realtime strategy (performance)

- Only listen in realtime to:
  - `users/{uid}/conversations` for conversation list
  - a derived `totalUnreadStream()` for tab badge
- Avoid listeners that watch full message collections from the list page.

## Indexes to create (recommended)

- `users/{uid}/conversations`:
  - `updatedAt desc`
- (optional) if you use the query:
  - `where unreadCount > 0`

## UI/UX philosophy

- Calm background, subtle dividers, no aggressive colors.
- Unread indicator:
  - blue dot for `unreadCount == 1`
  - small badge for `unreadCount > 1`
- Name uses heavier weight when unread.

## Safety notes

- Stream subscriptions in `MainWrapper` are cancelled in `dispose()`.
- Conversation list uses a simple paging approach by increasing limit as you scroll.
