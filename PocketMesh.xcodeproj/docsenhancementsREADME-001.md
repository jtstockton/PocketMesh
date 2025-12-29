# Enhancement 001: Heard Repeats Display

**Feature**: Display repeat count for channel messages that were heard being retransmitted by mesh repeaters.

**Status**: 📋 Planning  
**Priority**: 🔵 Medium  
**Complexity**: 🟢 Low (UI-only change)  
**Upstream Merge Risk**: 🟢 Low

---

## Quick Links

- **GitHub Issue**: `.github/ISSUE_TEMPLATE/001-heard-repeats-feature.md`
- **Feature Spec**: `001-heard-repeats-display.md`
- **Architecture**: `001-heard-repeats-architecture.md`
- **Implementation Guide**: `001-heard-repeats-implementation-guide.md`

---

## What This Feature Does

When you send a message on a channel (flood routing), the app will display:

```
┌─────────────────────────────────┐
│ Hey that's good news!           │ (your message bubble)
└─────────────────────────────────┘
  Delivered • Heard 3 repeats ✓   (status line)
```

This shows that your companion device's LoRa radio heard 3 different repeaters retransmitting your message, indicating good mesh network coverage.

---

## How It Works (Technical)

### The Radio Listening Mechanism

1. **You send** a channel message via your MeshCore device
2. **Device transmits** the packet once on LoRa
3. **Repeaters hear** your packet and relay it (flood routing)
4. **Your device's radio** hears these repeated transmissions
5. **Firmware recognizes**: "This is MY packet being repeated!"
6. **Firmware sends** ACK events (0x82) via BLE to the app
7. **MessageService** receives multiple ACKs with same code
8. **Counter increments**: `heardRepeats++`
9. **UI displays** the count

**Key Point**: Your device is **listening to LoRa transmissions** from repeaters, not receiving mesh acknowledgments. The count only includes repeaters within radio range of your device.

---

## Why This Matters

### Network Health Indicator

- **0-1 repeats**: Sparse or isolated network
- **2-4 repeats**: Moderate mesh coverage
- **5+ repeats**: Healthy, dense mesh network
- **10+ repeats**: Very dense urban deployment

### User Benefits

- ✅ Confidence that messages are propagating
- ✅ Visibility into mesh network activity
- ✅ Feedback on repeater placement effectiveness
- ✅ Understanding of local radio coverage

---

## Implementation Status

### ✅ Already Implemented (90%)

- **Data model**: `Message.heardRepeats` property exists
- **Backend logic**: `MessageService` tracks and counts repeats
- **Database**: Persists repeat count via SwiftData
- **Protocol handling**: ACK events properly handled
- **Grace period**: 60-second tracking window

### ❌ Missing (10%)

- **UI display**: Need to add count to `UnifiedMessageBubble`

---

## Files to Change

**Primary File**: `UnifiedMessageBubble.swift`
- Modify `statusRow` computed property
- Add conditional display for repeat count
- Only show for channel messages with `heardRepeats > 1`

**Estimated Effort**: 2-4 hours
- Code changes: 30 minutes
- Testing with hardware: 1-2 hours
- Edge case validation: 1 hour

---

## Display Rules

### When to Show

✅ Show "Heard N repeats" if:
- Message direction is **outgoing**
- Message is a **channel message** (not DM)
- `heardRepeats > 1` (more than just delivery confirmation)
- Message status is **delivered**

❌ Don't show if:
- Message is incoming
- Message is a direct message (path routing)
- `heardRepeats <= 1` (redundant with "Delivered")
- Message failed or is still sending

### Format

```swift
// For heardRepeats = 1
"Delivered ✓"

// For heardRepeats = 2+
"Delivered • Heard 3 repeats ✓"
```

---

## Testing Scenarios

### Scenario 1: Normal Mesh (3 repeaters)
```
Action: Send channel message
Expected: "Heard 3 repeats" appears within 2-5 seconds
```

### Scenario 2: Isolated Device (no repeaters)
```
Action: Send channel message
Expected: "Delivered" only (no repeat count)
```

### Scenario 3: Direct Message
```
Action: Send DM to contact
Expected: "Delivered" only (no repeat count)
```

### Scenario 4: Gradual Repeats
```
Action: Send message in sparse network
Expected: Count increases over time (1→2→3) within 60s
```

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Zero repeats | Show "Delivered" only |
| One repeat | Show "Delivered" only (don't show "Heard 1 repeat") |
| DM with flood fallback | Show "Delivered" only (DM semantics differ) |
| Failed message | No repeat count |
| Late ACK (>60s) | Use last known count (frozen) |
| App restart | Display persisted count (no live updates) |
| 10+ repeats | Show all: "Heard 12 repeats" (no limit) |

---

## Code Example

```swift
// In UnifiedMessageBubble.swift, statusRow:

if message.direction == .outgoing {
    HStack(spacing: 4) {
        // Status text
        Text(statusText)
            .font(.caption2)
            .foregroundStyle(.secondary)
        
        // NEW: Repeat count for channel messages
        if let channelIndex = message.channelIndex,
           message.heardRepeats > 1 {
            Text(" • Heard \(message.heardRepeats) repeats")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        
        // Checkmark
        if message.status == .delivered {
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}
```

---

## Upstream Merge Strategy

**Risk Level**: 🟢 **Low**

This feature is **purely additive**:
- ✅ No protocol changes
- ✅ No database schema changes
- ✅ No backend logic changes
- ✅ Only UI display modification
- ✅ Single file affected (`UnifiedMessageBubble.swift`)

**Merge Approach**:
1. Keep changes minimal and localized
2. Use clear, descriptive commit messages
3. Comment the conditional logic
4. Easy to cherry-pick or merge with upstream

**Potential Conflicts**:
- Other UI styling changes to `UnifiedMessageBubble`
- Changes to status row layout
- Resolution: Trivial (merge both display elements)

---

## Future Enhancements (Out of Scope)

### Phase 2: Repeater Details View
- Tap on "Heard N repeats" to show detail sheet
- List specific repeaters with names
- Show SNR values for each
- Display hop count information
- Visualize message path

**Challenge**: Current protocol only sends repeat count, not individual repeater metadata. Would require:
- Firmware protocol enhancement, OR
- Complex advertisement correlation logic, OR
- Approximate data from known contacts

**Priority**: Low (nice-to-have, not essential)

---

## Questions & Answers

### Q: Why only show for `heardRepeats > 1`?
**A**: "Heard 1 repeat" is semantically identical to "Delivered" - it just means the first confirmation was received. Only showing when multiple repeaters are heard provides useful additional information.

### Q: Why not show for direct messages?
**A**: Direct messages use path routing (targeted delivery), not flood routing. The semantics are different - a DM getting multiple ACKs means something different than a broadcast being repeated.

### Q: What if I have 20 repeaters?
**A**: Show it! "Heard 20 repeats" indicates an incredibly dense, healthy mesh network. No artificial limits.

### Q: How accurate is the count?
**A**: It only counts repeaters **you can hear** with your companion device's radio. Far-away repeaters that relay your message but are out of your radio range won't be counted. It's a measure of local mesh activity, not total propagation.

### Q: Why 60-second grace period?
**A**: Multi-hop routing introduces delays. A far repeater might take 30-45 seconds to hear and relay your message. 60 seconds balances catching late repeats while preventing unbounded memory growth.

---

## Related Native App Features

The native MeshCore app includes:
1. ✅ Repeat count display (this enhancement)
2. ⏳ Tap to view repeater details
3. ⏳ SNR values per repeater
4. ⏳ Hop count visualization
5. ⏳ Message path diagram

**MVP Scope**: Only implementing #1 (count display)  
**Future Work**: Could implement #2-5 with protocol enhancements

---

## Success Metrics

- [x] Infrastructure complete (data model, backend logic)
- [ ] UI displays count for channel messages
- [ ] Count updates in real-time as ACKs arrive
- [ ] No display for `heardRepeats <= 1`
- [ ] No display for direct messages
- [ ] No performance impact
- [ ] Matches native app behavior

---

## References

- **Native MeshCore App**: Screenshots in `.github/ISSUE_TEMPLATE/`
- **MeshCore Protocol**: `docs/ProtocolInternals.md`
- **Message Model**: `Models/Message.swift`
- **Message Service**: `Services/MessageService.swift`
- **UI Component**: `Views/UnifiedMessageBubble.swift`

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-28  
**Author**: @jtstockton
