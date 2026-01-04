# Channel Message Sync Race Condition - Fix Documentation

## The Problem

When reconnecting to the radio after being disconnected, channel messages that arrived while disconnected (and queued on the radio) were being lost due to a race condition.

### Root Cause

`MeshCoreSession.startAutoMessageFetching()` was immediately calling `getMessage()` to poll for messages. This happened **before** the sync phase could:
1. Wire up message handlers
2. Sync channels from the device to the local database

Result: Messages were consumed and discarded because handlers weren't ready and channels didn't exist in the database yet.

## The Fix

Removed the immediate `getMessage()` call from `startAutoMessageFetching()`. Now:
1. Connection establishes
2. Handlers are wired up
3. Channels are synced
4. **Then** `pollAllMessages()` is called during the sync phase
5. Auto-fetch continues in the background

Messages are only polled after the app is ready to handle them.

## How to Verify the Fix

### Test Procedure

1. **Start the app with device connected**
2. **Disconnect from the radio** (turn off Bluetooth, walk away, etc.)
3. **Send messages to a channel** while disconnected (messages should queue on radio)
4. **Reconnect to the radio**
5. **Check that all queued messages appear** in the channel conversation

### Expected Behavior (Before Fix)

- Messages sent to channels while disconnected would **not appear** after reconnecting
- Contact messages (direct messages) would work fine
- Only channel messages were affected

### Expected Behavior (After Fix)

- All messages (both channel and contact) queued on the radio during disconnection should appear after reconnecting
- Messages appear in the correct channel conversations
- No message loss

## Technical Details

### Code Change

**File:** `MeshCore/Sources/MeshCore/Session/MeshCoreSession.swift`

**Method:** `startAutoMessageFetching()`

**Change:** Removed immediate `getMessage()` call that was consuming messages before handlers were ready.

```swift
// REMOVED (was causing race condition):
do {
    _ = try await getMessage()
} catch {
    logger.debug("Initial message fetch: \(error.localizedDescription)")
}

// ADDED (explanation comment):
// NOTE: We deliberately do NOT poll for messages here!
// The initial message poll happens during the sync phase via pollAllMessages().
// If we poll here, we consume messages before the handlers are fully wired up,
// causing messages to be lost.
```

### Message Flow (After Fix)

1. **Connection established** → BLE transport connects
2. **Auto-fetch enabled** → `startAutoMessageFetching()` called (no polling yet)
3. **Handlers wired** → Message/channel handlers set up in SyncCoordinator
4. **Channels synced** → Channel info fetched and stored locally
5. **Initial poll** → `pollAllMessages()` called during sync phase
6. **Background polling** → Auto-fetch loop continues polling every 5 seconds

This ensures messages are only consumed when the app can properly handle them.
