# Implementation Guide: Heard Repeats Display

Quick reference for implementing the "Heard N Repeats" feature.

## Summary

Add display of repeat count below outgoing channel message bubbles. The infrastructure already exists - this is purely a UI change.

### How It Works

When you send a channel message (flood routing):
1. **Your device transmits** the packet once on LoRa
2. **Repeaters hear and relay** the same packet
3. **Your device's radio hears** these repeated transmissions
4. **Firmware recognizes** them as repeats of your sent message
5. **Firmware sends ACK events** via BLE for each heard repeat
6. **MessageService counts** them and stores in `message.heardRepeats`

**Key point**: Your companion device is listening to the LoRa transmissions from repeaters (not receiving ACKs back through the mesh). You only count repeaters within radio range of your device.

## Changes Required

### File: `UnifiedMessageBubble.swift`

**Location**: The `statusRow` computed property (around line 154)

**Current Code**:
```swift
private var statusRow: some View {
    HStack(spacing: 4) {
        // Retry button for failed messages
        if message.status == .failed, let onRetry {
            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }

        // Spinner for retrying
        if message.status == .retrying {
            ProgressView()
                .controlSize(.mini)
        }

        // Fail icon
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

**New Code** (add after the status text):
```swift
private var statusRow: some View {
    HStack(spacing: 4) {
        // Retry button for failed messages
        if message.status == .failed, let onRetry {
            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }

        // Spinner for retrying
        if message.status == .retrying {
            ProgressView()
                .controlSize(.mini)
        }

        // Fail icon
        if message.status == .failed {
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundStyle(.red)
        }

        Text(statusText)
            .font(.caption2)
            .foregroundStyle(.secondary)
        
        // NEW: Show heard repeats for delivered channel messages
        if shouldShowHeardRepeats {
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

// NEW: Computed property to determine if we should show repeat count
private var shouldShowHeardRepeats: Bool {
    message.isOutgoing &&           // Only for outgoing messages
    message.isChannelMessage &&     // Only for channel messages
    message.status == .delivered && // Only when delivered
    message.heardRepeats > 0        // Only if we heard repeats
}
```

**Alternative: More Compact Version** (matches native app style better):
```swift
// Replace the Text(statusText) section with:
if shouldShowHeardRepeats {
    Text("\(statusText) • Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.secondary)
} else {
    Text(statusText)
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

## Testing

### Preview Code

Add to the previews section in `UnifiedMessageBubble.swift`:

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
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Channel - Outgoing with 1 Repeat") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "Test message",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        heardRepeats: 1
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Channel - Outgoing No Repeats") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "No repeaters active",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        heardRepeats: 0
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Direct - Outgoing (Should NOT show repeats)") {
    let message = Message(
        deviceID: UUID(),
        contactID: UUID(),
        text: "Direct message",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        heardRepeats: 3  // Even with repeats, don't show for DMs
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Alice",
        contactNodeName: "Alice",
        deviceName: "My Device",
        configuration: .directMessage
    )
    .padding()
}
```

### Manual Testing Steps

1. **Setup**:
   - Connect to MeshCore device
   - Ensure you have active mesh network with repeaters
   - Open a channel (e.g., Public Channel)

2. **Test Scenarios**:
   
   **Scenario A: Normal Operation**
   - Send a message on the channel
   - Wait for delivery (should see "Delivered")
   - Watch for repeat count to appear/increment
   - Should see: "Delivered • Heard 2 repeats" (or similar)

   **Scenario B: No Active Repeaters**
   - Turn off repeaters or use isolated device
   - Send channel message
   - Should see: "Delivered" (no repeat count displayed)

   **Scenario C: Direct Message**
   - Send a direct message to a contact
   - Even if using flood routing, should NOT show repeat count
   - Should see: "Delivered" only

   **Scenario D: Failed Message**
   - Force message failure (disconnect device)
   - Should see: "Failed" with retry button
   - No repeat count should be shown

3. **Visual Verification**:
   - Text should be `.caption2` size
   - Color should be `.secondary` (gray)
   - Should have checkmark icon (if using expanded version)
   - Should be aligned with other status elements

## Optional Enhancements

### 1. Add Icon
```swift
if shouldShowHeardRepeats {
    Image(systemName: "antenna.radiowaves.left.and.right")
        .font(.caption2)
        .foregroundStyle(.secondary)
    
    Text("Heard \(message.heardRepeats)")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

### 2. Make it Tappable (Future Phase 2)
```swift
if shouldShowHeardRepeats {
    Button {
        // Show detail sheet with repeater list
        showRepeaterDetail = true
    } label: {
        HStack(spacing: 2) {
            Text("Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
            Image(systemName: "chevron.right")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .buttonStyle(.borderless)
}
```

### 3. Color Code by Repeat Count
```swift
private var repeatCountColor: Color {
    switch message.heardRepeats {
    case 0:
        return .secondary
    case 1...2:
        return .yellow
    case 3...5:
        return .green
    default:
        return .blue
    }
}

// Then use:
.foregroundStyle(repeatCountColor)
```

## Verification Checklist

Before submitting PR:
- [ ] Code compiles without errors
- [ ] Xcode previews render correctly
- [ ] Tested on real hardware with active mesh
- [ ] Repeat count displays for channel messages only
- [ ] Repeat count does NOT display for direct messages
- [ ] Repeat count only shows when > 0
- [ ] Text matches native app style (gray, small font)
- [ ] Grammar correct (singular "repeat" vs plural "repeats")
- [ ] No performance impact (simple conditional display)
- [ ] Works in both light and dark mode

## Rollback Plan

If this causes issues, simply:
1. Remove the `shouldShowHeardRepeats` computed property
2. Remove the conditional repeat count display from `statusRow`
3. Revert to showing only `Text(statusText)`

The data model and tracking logic remain unchanged, so rollback is safe.

## Next Steps

After implementing Phase 1 (this guide):
1. Gather user feedback
2. Monitor repeat count accuracy
3. Consider implementing Phase 2 (detailed repeater view)
4. Consider adding repeat count to conversation list preview
5. Add analytics/telemetry for repeat count distribution (useful for network health monitoring)

---

**Related Documents**:
- `001-heard-repeats-display.md` - Full enhancement specification
- `Message.swift` - Data model with `heardRepeats` property
- `MessageService.swift` - Tracking logic for repeats
- Native app screenshots - UI reference

**Estimated Implementation Time**: 30 minutes - 1 hour
