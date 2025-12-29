# Enhancement: Display "Heard N Repeats" for Channel Messages

**Status**: Planning  
**Priority**: Medium  
**Upstream Impact**: Low (UI-only feature, shouldn't conflict with upstream merges)

## Summary

Add visual display of mesh repeat count for outgoing channel/flood messages, similar to the native MeshCore app. When a user sends a message on a channel (using flood routing), the app should display "Heard N repeats" below the message bubble to indicate how many times the companion device's radio heard repeaters retransmitting the message.

## How It Actually Works

**Important clarification**: The repeaters do NOT send acknowledgments back through the mesh. Instead:

1. **You send** a channel message (flood routing)
2. **Repeaters hear and relay** the same packet via LoRa
3. **Your device's radio hears** these repeated transmissions
4. **Firmware recognizes** "This is MY packet being repeated!"
5. **Firmware sends ACK event** via BLE to the app for each repeat heard
6. **App counts** the ACK events: `heardRepeats++`

**Key Insight**: Your companion device directly listens to LoRa transmissions from repeaters on the same frequency. The count represents how many repeaters are **within radio range of your device**.

## Motivation

This feature provides valuable feedback to users about:
- **Mesh network health**: How many repeaters are active and can hear your messages
- **Message propagation**: Confirmation that the message is spreading through the mesh
- **Radio coverage**: Which messages reach repeaters you can hear
- **Repeater placement effectiveness**: Understanding your local mesh topology

This matches functionality in the native MeshCore app and is a key feature for mesh networking awareness.

## Reference: Native MeshCore App

The native app displays this feature as:
1. **Summary view**: "Heard 2 repeats ✓" shown below outgoing channel message bubbles
2. **Detail view**: Tappable to show full list of repeaters with:
   - Repeater node names
   - Hop count for each repeater
   - Signal strength (SNR in dB)
   - Visual signal indicators

See attached screenshots in issue for reference.

## Current Implementation Status

**Good news**: The infrastructure is already 90% implemented! 

### What's Already Working ✅

1. **Data Model**: `Message` model already has `heardRepeats: Int` property
2. **Protocol Handling**: `MessageService` already tracks repeat ACKs:
   - `PendingAck` struct tracks `heardRepeats` count
   - `handleAcknowledgement()` increments repeat count when duplicate ACK events arrive
   - `updateMessageHeardRepeats()` persists count to database
3. **Repeat Detection**: When the device's LoRa radio hears its own packet repeated by mesh nodes, firmware generates ACK events
4. **Grace Period**: 60-second tracking window after initial delivery to catch late repeats

### What's Missing ❌

1. **UI Display**: `UnifiedMessageBubble` doesn't show the repeat count
2. **Detail View**: No drill-down view to show which specific repeaters relayed the message
3. **Repeater Metadata**: Current implementation only tracks count, not individual repeater details (names, SNR, hop info)

## Proposed Solution

### Phase 1: Basic UI Display (MVP)
Display the heard repeats count below outgoing channel messages.

**Changes Required**:
1. Update `UnifiedMessageBubble.swift` to show repeat count in status row
2. Only display for:
   - Outgoing messages (`message.isOutgoing`)
   - Channel messages (`message.isChannelMessage`)
   - Messages with `heardRepeats > 0`
   - Messages with status `.delivered`

**UI Design**:
```
┌─────────────────────────────────┐
│ Hey that's good news!           │ (blue bubble)
└─────────────────────────────────┘
  Heard 2 repeats ✓              (gray text, small font)
```

### Phase 2: Detailed Repeater View (Future)
Add tappable interaction to show which repeaters relayed the message.

**Challenges**:
- Current protocol only sends duplicate ACKs, not repeater metadata
- May require firmware support or protocol enhancement
- Could track repeater info from advertisements if we correlate timestamps

**Possible Approaches**:
1. **Option A**: Track repeaters via advertisement correlation (complex, may be unreliable)
2. **Option B**: Request protocol enhancement from MeshCore firmware team
3. **Option C**: Show simplified view with just contact names from known repeaters

## Implementation Plan

### Phase 1: Basic Display (This Issue)
- [ ] Update `UnifiedMessageBubble.swift` status row logic
- [ ] Add conditional display: only for outgoing channel messages with repeats
- [ ] Style to match native app (gray text, checkmark icon)
- [ ] Test with real hardware on active mesh network
- [ ] Add preview for Xcode canvas
- [ ] Update documentation/screenshots

### Phase 2: Detailed View (Future Issue)
- [ ] Design repeater detail sheet UI
- [ ] Research protocol capabilities for repeater metadata
- [ ] Implement data model for tracking individual repeaters
- [ ] Add tap gesture to show detail sheet
- [ ] Display repeater names, hop counts, SNR

## Design Considerations

### 1. Message Type Filtering
**Decision**: Only show for channel messages, not DMs  
**Rationale**: 
- Channel messages use flood routing, so repeats are expected and meaningful
- Direct messages typically use path routing, where repeats indicate retransmission attempts (different semantic meaning)
- Matches native app behavior

**Alternative Considered**: Show for all flood-routed messages (including DMs with flood fallback)  
**Rejected Because**: User confusion - repeats for DMs indicate routing failure, not network health

### 2. Display Timing
**Decision**: Show immediately after first repeat is heard  
**Rationale**: Provides real-time feedback as message propagates

**Edge Case**: Message may be delivered but show "0 repeats" if no repeaters are active  
**Handling**: Only display repeat count if `> 0`, otherwise show standard "Delivered" status

### 3. Count Accuracy
**Limitation**: Count represents ACKs heard by companion device, not total mesh propagation  
**Implication**: 
- If user's device is in poor position, it may not hear all repeats
- This is expected behavior and matches native app
- Actual mesh propagation may be larger than displayed count

### 4. Grace Period
**Current Implementation**: 60-second window after initial delivery  
**Rationale**: Allows time for repeater ACKs to arrive, but prevents indefinite tracking

## Technical Details

### Code Locations

**UI Layer**:
- `UnifiedMessageBubble.swift` - Message bubble component (modify status row)
- `ChatView.swift` - Direct message chat view
- `ChannelChatView.swift` - Channel message view

**Data Layer**:
- `Message.swift` - Already has `heardRepeats` property ✅
- `MessageDTO` - Already includes `heardRepeats` in DTO ✅

**Business Logic**:
- `MessageService.swift` - Already tracks repeats via `handleAcknowledgement()` ✅
- `PersistenceStore.swift` - Already has `updateMessageHeardRepeats()` ✅

### Protocol Flow

```
1. User sends channel message
   └─> MessageService.sendChannelMessage()
       └─> Creates PendingAck with ackCode

2. Device sends message to mesh
   └─> Message floods through network
       └─> Repeaters retransmit

3. Repeaters send ACK back
   └─> BLE receives duplicate ACK events
       └─> MessageService.handleAcknowledgement(code)
           ├─> First ACK: Sets isDelivered = true, heardRepeats = 1
           └─> Subsequent ACKs: Increments heardRepeats
               └─> PersistenceStore.updateMessageHeardRepeats()
                   └─> Saves to SwiftData

4. UI observes message changes
   └─> ChatView sees messageEventBroadcaster updates
       └─> Reloads messages
           └─> UnifiedMessageBubble renders with updated heardRepeats
```

## Upstream Compatibility

**Merge Impact**: Low ✅

This is a **UI-only enhancement** that:
- Doesn't modify the data model (property already exists)
- Doesn't change any protocol handling
- Only adds optional display logic to message bubbles

**Merge Strategy**:
- Changes are isolated to `UnifiedMessageBubble.swift`
- If upstream modifies the same component, conflicts should be minimal
- Changes are additive (adding new UI, not modifying existing behavior)

**Recommendation**: 
- Implement in a way that's easy to disable (feature flag or conditional)
- Keep display logic self-contained in separate computed property or view modifier
- Document changes clearly for future merge reference

## Testing Plan

### Manual Testing
1. **Happy Path**:
   - Connect to device with active mesh network
   - Send message on public channel
   - Verify repeat count displays and increments
   - Verify message status updates properly

2. **Edge Cases**:
   - Message sent with no active repeaters (should show "Delivered" only)
   - Message sent on channel with 1 repeater (should show "Heard 1 repeat")
   - Message sent on channel with many repeaters (verify count accuracy)
   - Direct message (should NOT show repeat count)

3. **UI States**:
   - Outgoing channel message - pending
   - Outgoing channel message - sent (no repeats yet)
   - Outgoing channel message - delivered (0 repeats)
   - Outgoing channel message - delivered (1+ repeats)
   - Outgoing channel message - failed

### Automated Testing
- Add SwiftUI preview for message with repeats
- Consider adding unit test for display logic (if extracted to view model)

## Related Issues/PRs

- Related to message delivery status tracking
- May inform future work on network topology visualization
- Connects to contact management (if we implement Phase 2 repeater details)

## Additional Context

### Questions to Resolve

1. **Should DMs with flood routing show repeat count?**
   - Initial decision: No (matches native app)
   - Open to feedback from testing

2. **What icon should we use?**
   - Native app uses checkmark
   - Consider: "arrow.triangle.branch" (mesh icon), "antenna.radiowaves.left.and.right", or just text

3. **Should we show "0 repeats" or hide entirely?**
   - Initial decision: Hide if 0, only show if > 0
   - Alternative: Always show for channel messages to indicate flood routing was used

### Screenshots from Native App

[Reference screenshots provided show]:
- "Heard 2 repeats ✓" displayed below outgoing message bubbles
- Detailed view showing individual repeaters with hop counts and SNR
- Path visualization showing message flow through repeaters

### Future Enhancements

Beyond basic display, we could:
1. Add repeater detail sheet (Phase 2)
2. Show repeat count in conversation list preview
3. Add network statistics view showing average repeat counts
4. Visualize repeater topology on map view
5. Add notification when repeat count is unusually low (network health alert)

---

## Implementation Checklist

When implementing this enhancement:
- [ ] Read through this entire document
- [ ] Review native app screenshots for UI reference
- [ ] Examine existing `heardRepeats` tracking in `MessageService`
- [ ] Modify `UnifiedMessageBubble` status row
- [ ] Test on real hardware with active mesh
- [ ] Add SwiftUI previews
- [ ] Update README or user documentation
- [ ] Consider adding this feature to onboarding/tips
- [ ] Take screenshots for App Store if applicable

---

**Last Updated**: 2025-12-28  
**Document Version**: 1.0  
**Author**: jtstockton
