# Enhancement Summary: Heard Repeats Display

## Quick Answers to Your Questions

### 1. Should this feature apply to DMs or only channels?
**Answer**: Only channel messages (flood routing), not DMs.

**Reasoning**:
- Channel messages use flood routing by design, so repeats indicate network propagation (positive metric)
- DM repeats occur during flood fallback after path routing fails (indicates routing problems, not network health)
- This matches the native MeshCore app behavior

### 2. UI Placement?
**Answer**: Below the message bubble, tappable in future Phase 2.

**Phase 1 (Now)**:
```
┌─────────────────────────────────┐
│ Hey that's good news!           │
└─────────────────────────────────┘
  Delivered • Heard 2 repeats ✓
```

**Phase 2 (Future)**:
- Tappable to show detail sheet
- List individual repeaters
- Show hop counts and SNR
- (Requires protocol enhancement or clever advertisement correlation)

### 3. Time window for listening?
**Answer**: Already implemented - 60 seconds grace period.

The code already has this:
```swift
private let repeatTrackingGracePeriod: TimeInterval = 60.0
```

After the first ACK (delivery confirmation), the app continues tracking duplicate ACKs for 60 seconds, then stops tracking to clean up memory.

### 4. Should repeat information be persisted?
**Answer**: Yes, and it already is! ✅

The `Message` model has `heardRepeats: Int` property and `PersistenceStore` saves it to SwiftData. The count is preserved across app restarts.

## What You Need to Do

### Immediate Action Items

1. **Create GitHub Issue**:
   - Copy content from `docs/enhancements/001-github-issue-template.md`
   - Post to your repository at: https://github.com/jtstockton/PocketMesh/issues
   - Add screenshots from native app

2. **Implement the Feature**:
   - Open `UnifiedMessageBubble.swift`
   - Add the repeat count display to `statusRow`
   - Follow `docs/enhancements/001-heard-repeats-implementation-guide.md`
   - **Estimated time**: 30 minutes - 1 hour

3. **Test**:
   - Add SwiftUI previews
   - Test on real hardware with active mesh network
   - Verify it works for channels but not DMs

4. **Submit PR**:
   - Include screenshots
   - Reference the GitHub issue
   - Update docs if needed

## Key Insights from Code Analysis

### ✅ Already Implemented (90% done!)

1. **Data Model**: `Message.heardRepeats` exists
2. **Protocol Handling**: `MessageService.handleAcknowledgement()` tracks repeats
3. **Database**: `PersistenceStore.updateMessageHeardRepeats()` persists count
4. **Event Flow**: ACK events properly increment counter
5. **Grace Period**: 60-second tracking window
6. **Context Menu**: Already shows repeat count in message context menu!

### ❌ Missing (Just UI Display)

Only missing the **visible display** below the bubble. The context menu already shows it:

```swift
// In UnifiedMessageBubble.swift contextMenuContent
if message.status == .delivered && message.heardRepeats > 0 {
    Text("Heard: \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
}
```

So you just need to move this to the visible status row!

## Technical Implementation

### The Only File You Need to Change

**File**: `UnifiedMessageBubble.swift`  
**Location**: Around line 154 in the `statusRow` computed property

### The Code Change

Add this computed property:
```swift
private var shouldShowHeardRepeats: Bool {
    message.isOutgoing &&           
    message.isChannelMessage &&     
    message.status == .delivered && 
    message.heardRepeats > 0        
}
```

Then in `statusRow`, after the status text:
```swift
if shouldShowHeardRepeats {
    Text("• Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

That's it! No other changes needed.

## How It Works (Technical Flow)

```
1. User sends channel message
   ↓
2. MessageService creates PendingAck with unique ackCode
   ↓
3. Device sends message via LoRa (floods to all nodes)
   ↓
4. Repeaters receive and retransmit message
   ↓
5. Repeaters send ACK back to original sender
   ↓
6. Device receives multiple ACKs (same ackCode)
   ↓
7. BLE notifies app of each ACK
   ↓
8. MessageService.handleAcknowledgement():
   - First ACK → Sets delivered, heardRepeats = 1
   - Each subsequent ACK → Increments heardRepeats
   ↓
9. PersistenceStore updates Message in SwiftData
   ↓
10. SwiftUI observes change, re-renders UnifiedMessageBubble
   ↓
11. Bubble displays "Heard N repeats"
```

## Upstream Merge Compatibility

**Risk Level**: 🟢 Low

- Single file change (`UnifiedMessageBubble.swift`)
- UI-only modification
- No data model changes
- No protocol changes
- Additive feature (doesn't modify existing behavior)

**Merge Strategy**:
- Keep changes isolated to the `statusRow` computed property
- If upstream modifies message bubbles, conflicts should be minimal and obvious
- Changes are self-contained and can be easily reapplied if needed

## Documentation Created

I've created comprehensive documentation in your repo:

```
/repo/
├── .github/
│   └── ISSUE_TEMPLATE/
│       └── enhancement.md                    # GitHub issue template
└── docs/
    └── enhancements/
        ├── README.md                          # Overview and workflow
        ├── 001-heard-repeats-display.md       # Full specification
        ├── 001-heard-repeats-implementation-guide.md  # Step-by-step
        ├── 001-heard-repeats-architecture.md  # Diagrams and flow
        └── 001-github-issue-template.md       # Ready-to-post issue
```

All files are ready to commit and push to your GitHub repo.

## Next Steps

### Immediate (This Week)
1. [ ] Review the documentation
2. [ ] Create GitHub issue from template
3. [ ] Implement the UI changes
4. [ ] Test on real hardware
5. [ ] Submit PR

### Future (Phase 2)
- [ ] Add detailed repeater view (tappable)
- [ ] Show individual repeater names
- [ ] Display SNR and hop counts
- [ ] Consider protocol enhancement request to firmware team

## Resources

- **Native App Reference**: Screenshots you provided
- **Code Reference**: 
  - `Message.swift` - Data model
  - `MessageService.swift` - ACK tracking logic
  - `UnifiedMessageBubble.swift` - UI component to modify
- **Protocol Info**: MeshCore firmware repo (https://github.com/meshcore-dev/MeshCore)

## Questions or Issues?

If you encounter any problems:
1. Check the implementation guide for troubleshooting
2. Review the architecture diagram for data flow
3. Open a GitHub discussion
4. Feel free to ask me for clarification!

---

**Ready to implement?** Start with the implementation guide and you should have this working in under an hour! 🚀
