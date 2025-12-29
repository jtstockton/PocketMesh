# Code Changes: Visual Diff for Heard Repeats

This document shows the **exact code changes** needed in `UnifiedMessageBubble.swift`.

## File: UnifiedMessageBubble.swift

### Change 1: Add Helper Computed Property

**Location**: After `textColor` computed property (around line 148)

**Add this new computed property**:

```swift
// MARK: - Context Menu

/// Determines if heard repeats count should be displayed
private var shouldShowHeardRepeats: Bool {
    message.isOutgoing &&           // Only outgoing messages
    message.isChannelMessage &&     // Only channel messages (not DMs)
    message.status == .delivered && // Only delivered messages
    message.heardRepeats > 0        // Only if we actually heard repeats
}

// MARK: - Context Menu
```

### Change 2: Update Status Row

**Location**: `statusRow` computed property (around line 214)

**Before** (current code):
```swift
private var statusRow: some View {
    HStack(spacing: 4) {
        // Only show retry button for failed messages (not retrying)
        if message.status == .failed, let onRetry {
            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }

        // Show spinner for retrying status
        if message.status == .retrying {
            ProgressView()
                .controlSize(.mini)
        }

        // Only show icon for failed status
        if message.status == .failed {
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundStyle(.red)
        }

        Text(statusText)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    .padding(.trailing, 4)
}
```

**After** (new code):
```swift
private var statusRow: some View {
    HStack(spacing: 4) {
        // Only show retry button for failed messages (not retrying)
        if message.status == .failed, let onRetry {
            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }

        // Show spinner for retrying status
        if message.status == .retrying {
            ProgressView()
                .controlSize(.mini)
        }

        // Only show icon for failed status
        if message.status == .failed {
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundStyle(.red)
        }

        Text(statusText)
            .font(.caption2)
            .foregroundStyle(.secondary)
        
        // NEW: Show heard repeats for channel messages
        if shouldShowHeardRepeats {
            Text("•")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text("Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    .padding(.trailing, 4)
}
```

## Complete Code Snippet

If you prefer to copy-paste the entire section, here's the complete new `statusRow`:

```swift
// MARK: - Status Row

private var statusRow: some View {
    HStack(spacing: 4) {
        // Only show retry button for failed messages (not retrying)
        if message.status == .failed, let onRetry {
            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }

        // Show spinner for retrying status
        if message.status == .retrying {
            ProgressView()
                .controlSize(.mini)
        }

        // Only show icon for failed status
        if message.status == .failed {
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundStyle(.red)
        }

        Text(statusText)
            .font(.caption2)
            .foregroundStyle(.secondary)
        
        // Show heard repeats for channel messages
        if shouldShowHeardRepeats {
            Text("•")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text("Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    .padding(.trailing, 4)
}

/// Determines if heard repeats count should be displayed
private var shouldShowHeardRepeats: Bool {
    message.isOutgoing &&           // Only outgoing messages
    message.isChannelMessage &&     // Only channel messages (not DMs)
    message.status == .delivered && // Only delivered messages
    message.heardRepeats > 0        // Only if we actually heard repeats
}
```

## Alternative: Simpler Version (Without Icons)

If you want to match the native app more closely (text only):

```swift
// In statusRow, replace the repeat display section with:
if shouldShowHeardRepeats {
    Text("• Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

## Visual Result

### Before (Current)
```
┌─────────────────────────────────┐
│ Hey that's good news!           │
└─────────────────────────────────┘
  Delivered                         ← Status only
```

### After (With Changes)
```
┌─────────────────────────────────┐
│ Hey that's good news!           │
└─────────────────────────────────┘
  Delivered • ✓ Heard 2 repeats    ← Status + repeat count
```

## Testing Your Changes

### 1. Build in Xcode
- Clean build folder: `Cmd+Shift+K`
- Build: `Cmd+B`
- Should compile without errors

### 2. Check Xcode Previews
The existing previews should still work. Add new ones:

```swift
#Preview("Channel - Outgoing with Repeats") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "Hey that's good news!",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        heardRepeats: 2
    )
    return VStack {
        UnifiedMessageBubble(
            message: MessageDTO(from: message),
            contactName: "Public Channel",
            contactNodeName: "Public Channel",
            deviceName: "My Device",
            configuration: .channel(isPublic: true, contacts: [])
        )
    }
    .padding()
}
```

### 3. Test on Device/Simulator
- Run app on device or simulator
- Navigate to a channel
- Send a test message
- Won't see repeats in simulator, but should see status row renders correctly

### 4. Test on Real Hardware
- Connect to MeshCore device
- Ensure you have active mesh network with repeaters
- Send message on channel
- Watch for repeat count to appear and increment

## Troubleshooting

### "Cannot find 'shouldShowHeardRepeats' in scope"
- Make sure you added the computed property
- Check it's defined within the `UnifiedMessageBubble` struct
- Should be `private var`, not `func`

### "Ambiguous reference to member 'heardRepeats'"
- Verify `Message` model has `heardRepeats` property
- Check imports at top of file include `PocketMeshServices`

### Status row layout looks wrong
- Check spacing in `HStack(spacing: 4)`
- Verify all text uses `.font(.caption2)`
- Make sure `.foregroundStyle(.secondary)` is applied

### Repeat count not updating
- This is a data/service issue, not UI
- Check `MessageService` is running
- Verify device is connected
- Check logs for "ACK received" messages

## Commit Message

When you're ready to commit:

```
feat: Display heard repeats count for channel messages

- Add repeat count display below outgoing channel message bubbles
- Shows "Heard N repeats" when heardRepeats > 0
- Only displays for channel messages (not DMs)
- Matches native MeshCore app functionality

Closes #X (replace X with your GitHub issue number)
```

## Files Changed

```
modified:   UnifiedMessageBubble.swift
```

That's it! Just one file changed.

---

**Estimated Time**: 15-30 minutes  
**Difficulty**: Easy  
**Risk**: Low (UI-only change)
