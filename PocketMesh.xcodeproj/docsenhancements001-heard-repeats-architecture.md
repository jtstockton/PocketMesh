# Heard Repeats Feature - Architecture & Data Flow

Visual documentation of how the "Heard Repeats" feature works in PocketMesh.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         PocketMesh App                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ BLE
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MeshCore Device                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  1. Transmits your message to mesh network               │  │
│  │  2. LoRa radio LISTENS for same packet repeated          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ LoRa Radio (Flood broadcast)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Mesh Network                              │
│                                                                   │
│  ┌─────────┐      ┌─────────┐      ┌─────────┐                 │
│  │Repeater1│─────▶│Repeater2│─────▶│Repeater3│                 │
│  └─────────┘      └─────────┘      └─────────┘                 │
│       │                │                │                        │
│       │ Retransmits    │ Retransmits    │ Retransmits           │
│       │ same packet    │ same packet    │ same packet           │
│       ▼                ▼                ▼                        │
│    ┌──────────────────────────────────────┐                     │
│    │  YOUR DEVICE HEARS THESE REPEATS!    │                     │
│    │  (via LoRa radio, not BLE)           │                     │
│    └──────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                         │
                         │ Device detects duplicate packet
                         │ from different repeaters
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MeshCore Device                             │
│  • Receives original packet from repeaters (duplicates)          │
│  • Firmware tracks: "I already sent this, it's a repeat!"       │
│  • Sends ACK event for EACH heard repeat                         │
└─────────────────────────────────────────────────────────────────┘
                         │
                         │ BLE notifications (0x82 ACK events)
                         │ One ACK per repeat heard
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PocketMesh App                              │
│  MessageService receives multiple ACK events with same code      │
│  Counts them: heardRepeats++                                     │
└─────────────────────────────────────────────────────────────────┘
```

**Key Insight**: The repeaters are NOT sending ACKs back. Instead, your companion device **directly hears the repeated LoRa transmissions** from repeaters on the same frequency, recognizes them as duplicates of your sent message, and generates ACK events for each one.

## Data Flow Diagram

```
User Sends Channel Message
         │
         ▼
┌──────────────────────┐
│  ChatViewModel       │
│  .sendMessage()      │
└──────────────────────┘
         │
         ▼
┌──────────────────────┐
│  MessageService      │
│  .sendChannelMessage │
└──────────────────────┘
         │
         ├─────────────────────────────┐
         │                             │
         ▼                             ▼
┌──────────────────────┐    ┌──────────────────────┐
│  SwiftData           │    │  MeshCoreSession     │
│  Create Message      │    │  Send to device      │
│  heardRepeats = 0    │    └──────────────────────┘
└──────────────────────┘               │
                                       ▼
                            ┌──────────────────────┐
                            │  BLE Transport       │
                            │  Write packet        │
                            └──────────────────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │  MeshCore Device     │
                            │  Floods message      │
                            └──────────────────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │  Mesh Network        │
                            │  Repeaters relay     │
                            └──────────────────────┘
                                       │
                  ┌────────────────────┼────────────────────┐
                  │                    │                    │
                  ▼                    ▼                    ▼
          ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
          │ Repeater 1   │    │ Repeater 2   │    │ Repeater 3   │
          │ Sends ACK    │    │ Sends ACK    │    │ Sends ACK    │
          └──────────────┘    └──────────────┘    └──────────────┘
                  │                    │                    │
                  └────────────────────┼────────────────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │  MeshCore Device     │
                            │  Receives ACKs       │
                            └──────────────────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │  BLE Transport       │
                            │  Notify app          │
                            └──────────────────────┘
                                       │
                  ┌────────────────────┼────────────────────┐
                  │                    │                    │
                  ▼                    ▼                    ▼
          ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
          │ ACK Event 1  │    │ ACK Event 2  │    │ ACK Event 3  │
          │ (First)      │    │ (Repeat)     │    │ (Repeat)     │
          └──────────────┘    └──────────────┘    └──────────────┘
                  │                    │                    │
                  ▼                    ▼                    ▼
┌────────────────────────────────────────────────────────────────┐
│                     MessageService                              │
│              .handleAcknowledgement(code)                       │
├────────────────────────────────────────────────────────────────┤
│  First ACK:                                                     │
│    • Set isDelivered = true                                     │
│    • Set heardRepeats = 1                                       │
│    • Update message status to .delivered                        │
│                                                                  │
│  Subsequent ACKs:                                               │
│    • Increment heardRepeats counter                             │
│    • Update message in database                                 │
└────────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌────────────────────────────────────────────────────────────────┐
│                     PersistenceStore                            │
│              .updateMessageHeardRepeats()                       │
│                                                                  │
│  UPDATE message SET heardRepeats = X WHERE id = Y               │
└────────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌────────────────────────────────────────────────────────────────┐
│                        SwiftData                                │
│  Message object updated, triggers view refresh                  │
└────────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌────────────────────────────────────────────────────────────────┐
│                       ChatView                                  │
│  Observes messageEventBroadcaster changes                       │
│  Reloads messages                                               │
└────────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌────────────────────────────────────────────────────────────────┐
│                  UnifiedMessageBubble                           │
│  Renders with updated heardRepeats value                        │
│                                                                  │
│  ┌────────────────────────────────────┐                        │
│  │ Hey that's good news!              │                        │
│  └────────────────────────────────────┘                        │
│    Delivered • Heard 3 repeats ✓      ← NEW DISPLAY            │
└────────────────────────────────────────────────────────────────┘
```

## State Machine: Message Delivery Status

```
┌────────────┐
│  PENDING   │  (Message created, not sent yet)
└────────────┘
      │
      │ send()
      ▼
┌────────────┐
│  SENDING   │  (Transmitted to device)
└────────────┘
      │
      │ device confirms sent
      ▼
┌────────────┐
│    SENT    │  (On mesh network, waiting for ACK)
└────────────┘  heardRepeats = 0
      │
      │ first ACK received
      ▼
┌────────────┐
│ DELIVERED  │  (Confirmed delivery)
└────────────┘  heardRepeats = 1
      │
      │ subsequent ACKs
      ▼
┌────────────┐
│ DELIVERED  │  (With repeat tracking)
└────────────┘  heardRepeats = 2, 3, 4...
      │
      │ 60 second grace period
      ▼
   [Finalized]  (No more repeat tracking)
```

## Code Structure

```
PocketMesh/
├── Models/
│   └── Message.swift
│       └── heardRepeats: Int ✅ (Already exists)
│
├── Services/
│   ├── MessageService.swift
│   │   ├── PendingAck ✅
│   │   │   └── heardRepeats counter
│   │   └── handleAcknowledgement() ✅
│   │       └── Increments repeat count
│   │
│   └── PersistenceStore.swift
│       └── updateMessageHeardRepeats() ✅
│
└── Views/
    └── UnifiedMessageBubble.swift ❌ (Needs modification)
        └── statusRow
            └── Add repeat count display HERE
```

## Protocol Details

### How It Works: Radio-Level Duplicate Detection

**The MeshCore firmware does the heavy lifting:**

1. **Your device transmits** a channel message (flood routing)
2. **Repeaters hear it** and retransmit the same packet
3. **Your device's LoRa radio hears** these retransmissions
4. **Firmware recognizes** "Hey, this is MY packet being repeated!"
5. **Firmware generates ACK event** for each heard repeat
6. **App receives** multiple ACK events with the same code

### ACK Event Structure

```
When device hears its own packet repeated by mesh:

Response Code: 0x82 (ACK)
┌──────────────────────────────────┐
│  Packet Type: 0x82 (ACK)         │
│  ACK Code: [4 bytes]             │  ← Matches your sent message
└──────────────────────────────────┘

Same ACK code = same original message
Multiple ACKs with same code = multiple repeaters heard
```

### Repeat Detection Flow

1. **Message Sent**: 
   - Device floods message with unique ACK code (4 bytes)
   - Radio transmits once
   - Device keeps listening on same frequency

2. **First Repeat Heard**: 
   - Radio receives identical packet (from Repeater A)
   - Firmware: "This matches my ACK code!"
   - Sends BLE notification: ACK event #1
   - App marks: heardRepeats = 1

3. **Second Repeat Heard**: 
   - Radio receives identical packet (from Repeater B)
   - Firmware: "Same ACK code, different source!"
   - Sends BLE notification: ACK event #2
   - App increments: heardRepeats = 2

4. **Third Repeat Heard**: 
   - Radio receives identical packet (from Repeater C)
   - Same process: ACK event #3
   - App increments: heardRepeats = 3

**Important**: The repeaters are NOT sending acknowledgments back. Your companion device is simply **hearing their retransmissions** of your original packet over the air.

### Grace Period Logic

```swift
// In MessageService
private let repeatTrackingGracePeriod: TimeInterval = 60.0

// After first ACK (first heard repeat):
// - Continue tracking pending ACK for 60 seconds
// - Accept additional ACK events with same code
// - Each additional ACK = another repeater heard your packet
// - After 60 seconds, stop tracking and clean up
//
// Why 60 seconds?
// - Repeaters may relay at different times
// - Multi-hop routing introduces delays
// - Far-away repeaters take longer to hear and relay
// - 60s gives enough time for mesh to propagate
```

### Difference from Direct Messages

**Channel Messages (Flood Routing):**
- Broadcast to entire network
- All repeaters relay it
- Your device hears multiple repeats
- Count shows mesh network health
- → Display: "Heard 3 repeats"

**Direct Messages (Path Routing):**
- Targeted to specific contact
- Routed along known path
- Single ACK from destination
- No repeater relaying (unless fallback to flood)
- → Display: "Delivered" only (no repeat count)

## UI Component Hierarchy

```
ChatView
 └── ScrollView
      └── LazyVStack
           └── ForEach(messages)
                └── UnifiedMessageBubble ← Modify this
                     ├── Timestamp (conditional)
                     ├── Sender name (for channels)
                     ├── Message bubble
                     │    ├── Text content
                     │    └── Context menu
                     └── Status row ← Add repeat count here
                          ├── Retry button (if failed)
                          ├── Spinner (if retrying)
                          ├── Status text
                          └── Heard repeats ← NEW
```

## Edge Cases Handled

### 1. **Zero Repeats (Isolated Device)**
```
Message sent but NO repeaters in radio range
→ No ACK events received at all
→ Show: "Sent" (not delivered, no repeats)
→ Don't show: Repeat count (nothing to count)
```

### 2. **One Repeat (Message Delivered)**
```
Message delivered successfully
→ First ACK event received
→ Show: "Delivered" 
→ Don't show: "Heard 1 repeat" (semantically redundant)
→ Only show count if heardRepeats > 1
```

### 3. **Direct Message with Flood Fallback**
```
DM sent with flood routing (after path routing failed)
→ May receive multiple ACKs
→ Show: "Delivered" only
→ Don't show: Repeat count (different semantic meaning for DMs)
```

### 4. **Failed Message**
```
Message never delivered (no ACK events)
→ Show: "Failed" with retry button
→ Don't show: Repeat count (not applicable)
```

### 5. **Late ACKs (After Grace Period)**
```
ACK arrives after 60 second grace period
→ Ignored (no longer tracking)
→ Count remains at last known value
→ Prevents unbounded tracking memory
```

### 6. **App Restart with Pending Message**
```
App closes with message sent but ACKs pending
→ heardRepeats count persisted in SwiftData
→ On restart, display last known count
→ No active tracking after restart (stale data)
```

### 7. **Very Active Mesh (Many Repeaters)**
```
10+ repeaters in range, all relay your message
→ App may receive 10+ ACK events rapidly
→ Count all of them: "Heard 12 repeats"
→ No artificial limit (count what you hear)
```

## Performance Considerations

### Memory Usage
- **PendingAck** struct: ~100 bytes each
- Typical load: 1-5 pending ACKs at a time
- Grace period cleanup: Prevents unbounded growth

### Database Operations
- **Write frequency**: Once per repeat ACK (low frequency)
- **Operation**: Single UPDATE by message ID (indexed, fast)
- **No impact**: Read-only for display, no queries

### UI Rendering
- **Conditional display**: Simple boolean check
- **No animations**: Static text display
- **Minimal overhead**: Adds ~20 bytes to view

## Testing Scenarios

### Scenario 1: Normal Operation (Multiple Repeaters)
```
Setup: Device with 3 active repeaters in range
1. Send channel message: "Hello mesh!"
2. Device transmits packet once
3. Repeater A hears it and relays → ACK #1
4. Repeater B hears it and relays → ACK #2  
5. Repeater C hears it and relays → ACK #3
6. Expected: "Heard 3 repeats" displayed after ~2-5 seconds
```

### Scenario 2: Isolated Device (No Repeaters)
```
Setup: Device with no repeaters in radio range
1. Send channel message: "Hello?"
2. Device transmits packet once
3. No repeaters hear it
4. No ACK events received
5. Expected: "Sent" (or "Failed" after timeout)
```

### Scenario 3: Mixed Routing in Same Chat
```
Setup: Active mesh network
1. Send DM to contact (path routing): "Hi Bob"
   → Expected: "Delivered" only (no repeat count)
2. Send channel message (flood routing): "Hi everyone"
   → Expected: "Delivered • Heard N repeats"
3. Both in same conversation view
```

### Scenario 4: Delayed Repeats (Sparse Network)
```
Setup: Repeaters with varying distances/delays
1. Send channel message at T=0s
2. Close repeater relays at T=1s: "Heard 1 repeat"
3. Medium repeater relays at T=5s: "Heard 2 repeats"
4. Far repeater relays at T=15s: "Heard 3 repeats"
5. Very far repeater relays at T=45s: "Heard 4 repeats"
6. After T=60s: Count freezes at 4 (grace period expired)
7. If late ACK at T=90s: Ignored (still shows 4)
```

### Scenario 5: Dense Mesh (Many Repeaters)
```
Setup: Urban deployment with 10+ repeaters
1. Send channel message
2. Rapid succession of ACKs: 1, 2, 3, 4...
3. Expected: "Heard 10 repeats" (or more)
4. Indicates healthy, dense mesh network
```

### Scenario 6: App Backgrounding During ACKs
```
Setup: Message sent, then app backgrounded
1. Send message at T=0s
2. First ACK at T=1s (app in foreground): "Heard 1 repeat"
3. User switches to another app at T=2s
4. Background ACKs arrive at T=5s, T=8s, T=10s
5. User returns to app at T=15s
6. Expected: Display catches up: "Heard 4 repeats"
```

## Monitoring & Debugging

### Log Messages
```swift
// MessageService logs:
logger.info("First ACK received, message delivered")
logger.debug("Heard repeat #\(repeatCount) for message")
logger.warning("Received ACK for unknown message")
logger.debug("Grace period expired for ACK tracking")
```

### SwiftData Queries for Analysis
```swift
// Fetch messages with repeats for network health analysis
let messages = try await dataStore.fetchMessages(
    deviceID: deviceID,
    where: { $0.heardRepeats > 0 }
)

// Find messages with many repeats (good mesh coverage)
let wellPropagated = messages.filter { $0.heardRepeats > 3 }

// Find messages with low repeats (sparse network)
let poorPropagation = messages.filter { 
    $0.heardRepeats == 1 && $0.direction == .outgoing 
}
```

### Network Health Metrics (Future Enhancement)
```swift
// Average repeat count per channel message
let channelMessages = messages.filter { $0.channelIndex != nil }
let avgRepeats = channelMessages.map(\.heardRepeats).reduce(0, +) / channelMessages.count

// Interpretation:
// • avgRepeats > 5  = Dense mesh, excellent coverage
// • avgRepeats 2-4  = Moderate mesh, good coverage  
// • avgRepeats 1-2  = Sparse mesh, minimal repeaters
// • avgRepeats 0-1  = Isolated or poor placement
```

### Debug Panel Ideas (Future)
```swift
// Per-message repeat tracking visualization
struct RepeatDebugView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Sent: \(message.createdAt)")
            Text("First ACK: \(message.firstAckTimestamp ?? "None")")
            Text("Heard Repeats: \(message.heardRepeats)")
            Text("Grace Period: \(gracePeriodRemaining)s remaining")
            
            // Timeline view showing when each repeat was heard
            RepeatTimelineView(ackTimestamps: message.ackTimestamps)
        }
    }
}
```

### Understanding Repeat Counts

**What the count tells you:**

- **0 repeats**: Message sent but nobody relayed it
  - Possible isolated network
  - Or all repeaters out of range
  
- **1-2 repeats**: Minimal mesh activity
  - Small network or sparse coverage
  - Message barely propagated
  
- **3-5 repeats**: Healthy mesh
  - Good repeater coverage
  - Normal network operation
  
- **6-10 repeats**: Dense mesh
  - Many active repeaters
  - Excellent network coverage
  
- **10+ repeats**: Very dense mesh
  - Urban deployment
  - Lots of nearby repeaters

**Note**: The count represents repeaters within **radio range of YOUR companion device**, not the total network. A far-away repeater that relays your message won't be counted if you can't hear it.

---

**Related Files**:
- `001-heard-repeats-display.md` - Feature specification
- `001-heard-repeats-implementation-guide.md` - Code changes
- `MessageService.swift` - ACK tracking implementation
- `UnifiedMessageBubble.swift` - UI component to modify

**Last Updated**: 2025-12-28
