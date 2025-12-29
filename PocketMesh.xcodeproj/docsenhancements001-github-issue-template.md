---
**Title**: [ENHANCEMENT] Display "Heard N Repeats" for Channel Messages
**Labels**: enhancement, ui, good-first-issue
**Milestone**: v1.1
---

## Summary

Add visual display of mesh repeat count for outgoing channel/flood messages, matching the native MeshCore app functionality. When sending a message on a channel, display "Heard N repeats ✓" below the message bubble to show how many mesh repeaters retransmitted it.

## Screenshots from Native App

<img src="path/to/screenshot1.jpg" width="300" alt="Message with heard 2 repeats">
<img src="path/to/screenshot2.jpg" width="300" alt="Repeater detail view">

## Motivation

This feature provides valuable feedback about:
- **Mesh network health**: How many repeaters are active and relaying messages
- **Message propagation**: Confirmation that messages are spreading through the mesh
- **Network topology understanding**: Which messages reach more of the network

Users coming from the native MeshCore app expect this feature.

## Current Status

✅ **Good news**: The infrastructure is already ~90% implemented!

**What's Working**:
- ✅ `Message` model has `heardRepeats: Int` property
- ✅ `MessageService` tracks repeat ACKs and increments counter
- ✅ `PersistenceStore` persists repeat count to database
- ✅ Protocol handling for duplicate ACKs is complete

**What's Missing**:
- ❌ UI doesn't display the repeat count
- ❌ No drill-down view for repeater details (future enhancement)

## Proposed Implementation

### Changes Required

**Single file**: `UnifiedMessageBubble.swift`

Add repeat count display to the `statusRow` computed property:

```swift
// Add this computed property:
private var shouldShowHeardRepeats: Bool {
    message.isOutgoing &&           // Only for outgoing messages
    message.isChannelMessage &&     // Only for channel messages  
    message.status == .delivered && // Only when delivered
    message.heardRepeats > 0        // Only if we heard repeats
}

// Then in statusRow, after the status text:
if shouldShowHeardRepeats {
    Text("• Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

### UI Design

```
┌─────────────────────────────────┐
│ Hey that's good news!           │ ← Blue bubble (outgoing)
└─────────────────────────────────┘
  Delivered • Heard 2 repeats ✓    ← Gray text below bubble
```

### Behavior Specification

**Display When**:
- ✅ Outgoing message
- ✅ Channel message (not DM)
- ✅ Status is `.delivered`
- ✅ `heardRepeats > 0`

**Don't Display When**:
- ❌ Direct messages (even with flood routing)
- ❌ Incoming messages
- ❌ `heardRepeats == 0`
- ❌ Message pending/failed/retrying

## Testing Plan

### Xcode Previews
Add SwiftUI previews for:
- Channel message with 1 repeat
- Channel message with 2+ repeats
- Channel message with 0 repeats (should NOT show)
- Direct message (should NOT show repeat count)

### Manual Testing
1. Connect to device with active mesh network
2. Send message on public channel
3. Verify repeat count displays and increments
4. Send direct message - verify NO repeat count shows
5. Test with no active repeaters - verify "Delivered" only

## Implementation Guide

Full implementation details available in:
- 📄 `/docs/enhancements/001-heard-repeats-display.md` - Complete specification
- 📄 `/docs/enhancements/001-heard-repeats-implementation-guide.md` - Step-by-step code changes

## Upstream Compatibility

**Impact**: ✅ Low - UI-only change

This enhancement:
- Doesn't modify data models (property already exists)
- Doesn't change protocol handling
- Only adds optional display logic
- Changes are isolated to one file

**Merge strategy**: Changes are additive and self-contained, should not conflict with upstream.

## Acceptance Criteria

- [ ] Repeat count displays below outgoing channel messages
- [ ] Shows "Heard 1 repeat" (singular) and "Heard 2 repeats" (plural)
- [ ] Only displays when `heardRepeats > 0`
- [ ] Does NOT display for direct messages
- [ ] Matches native app style (gray text, small font)
- [ ] Works in both light and dark mode
- [ ] Xcode previews added
- [ ] Tested on real hardware with mesh network

## Future Enhancements

After this basic display is implemented, consider:
- Phase 2: Add tappable detail view showing individual repeaters
- Show repeater names, hop counts, and SNR
- Add network health indicators based on repeat counts
- Visualize repeater topology on map view

## Related

- Native MeshCore app (reference implementation)
- Contact management (for Phase 2 repeater names)
- Network statistics tracking

---

**Estimated Effort**: Small (1-2 hours)  
**Difficulty**: Easy  
**Priority**: Medium
