# Heard Repeats: How It Actually Works

## ⚠️ Important Clarification

This document clarifies a **critical misunderstanding** about how the "Heard Repeats" feature works in MeshCore.

---

## ❌ Initial (Incorrect) Understanding

**What I originally thought:**

> "When you send a channel message, repeaters relay it through the mesh and send **acknowledgments (ACKs) back** to your device through the mesh network. Each repeater sends an ACK back, and your device counts them."

```
You → Repeater A → sends ACK back to you
   → Repeater B → sends ACK back to you  
   → Repeater C → sends ACK back to you
```

**This is WRONG!** ❌

---

## ✅ Actual Behavior

**How it really works:**

> "When you send a channel message, repeaters relay it. Your companion device's **LoRa radio directly hears these repeated transmissions** over the air. The firmware recognizes them as duplicates of your sent packet and generates ACK events locally."

```
You transmit once
    ↓
Repeater A hears and relays
Repeater B hears and relays  
Repeater C hears and relays
    ↓
YOUR RADIO HEARS ALL THREE RETRANSMISSIONS
    ↓
Firmware: "Hey, these are MY packet being repeated!"
    ↓
Generates 3 ACK events locally
```

**This is CORRECT!** ✅

---

## Key Differences

| Aspect | ❌ Wrong Understanding | ✅ Correct Understanding |
|--------|----------------------|------------------------|
| **ACK source** | Repeaters send ACKs back | Your radio hears repeats directly |
| **Network path** | ACKs travel back through mesh | No return path needed |
| **What's counted** | Acknowledgments from repeaters | Overheard retransmissions |
| **Range limitation** | Any repeater in mesh | Only repeaters YOU can hear |
| **Protocol** | Active ACK packets sent back | Passive listening to duplicates |
| **Firmware role** | Receives remote ACKs | Detects duplicate packets locally |

---

## Why This Matters

### Range Limitation

**Wrong understanding**: You count all repeaters in the entire mesh network  
**Correct understanding**: You only count repeaters **within radio range of your device**

This means:
- A far-away repeater that relays your message won't be counted if you can't hear it
- The count represents your **local mesh topology**, not global propagation
- It's a measure of **your radio coverage**, not total network reach

### No Return Path Needed

**Wrong understanding**: Repeaters need to route ACKs back to you  
**Correct understanding**: Your device just listens, no routing needed

This means:
- Simpler protocol (no ACK routing required)
- More reliable (no packet loss on return path)
- Immediate (no multi-hop delays)
- No network overhead (no additional packets)

### Firmware Intelligence

**Wrong understanding**: Firmware just receives ACK packets  
**Correct understanding**: Firmware detects and deduplicates packets

The firmware:
1. Transmits your packet with unique identifier
2. Continues listening on LoRa frequency
3. Receives identical packets from repeaters
4. Recognizes: "Same identifier, different source, it's a repeat!"
5. Increments internal counter
6. Sends ACK event to app via BLE

---

## Practical Implications

### Testing

**Wrong**: Test with repeaters far away (out of radio range)  
**Right**: Test with repeaters you can directly hear

### Network Health Metrics

**Wrong**: "Heard 5 repeats" = message reached 5 nodes total  
**Right**: "Heard 5 repeats" = 5 nearby repeaters can hear YOU

### Debugging

**Wrong**: Look for ACK routing issues in mesh  
**Right**: Look for local radio reception issues

### User Understanding

**Wrong**: "Your message reached 5 repeaters in the network"  
**Right**: "5 nearby repeaters heard and relayed your message"

---

## The Radio Listening Process

### Step-by-Step Breakdown

**T=0s**: You press Send
```
App → BLE → Device firmware
Device firmware: "Transmit packet with ACK code 0xABCD1234"
LoRa radio: *transmits once*
```

**T=0.5s**: Repeater A hears your transmission
```
Repeater A radio: *receives packet*
Repeater A: "This is a flood message, relay it!"
Repeater A radio: *retransmits same packet*
```

**T=0.6s**: Your device hears Repeater A's transmission
```
Your radio: *receives packet*
Your firmware: "Wait, this ACK code is 0xABCD1234... that's mine!"
Your firmware: "Count: 1 repeat heard"
Your firmware → BLE → App: ACK event #1
```

**T=1.0s**: Repeater B hears and relays
```
Repeater B radio: *retransmits*
Your radio: *receives*
Your firmware: "ACK code 0xABCD1234 again, different timing"
Your firmware: "Count: 2 repeats heard"
Your firmware → BLE → App: ACK event #2
```

**T=1.5s**: Repeater C hears and relays
```
Repeater C radio: *retransmits*
Your radio: *receives*
Your firmware: "ACK code 0xABCD1234 again!"
Your firmware: "Count: 3 repeats heard"
Your firmware → BLE → App: ACK event #3
```

**Result**: App displays "Heard 3 repeats"

---

## Why the Confusion?

### Terminology

The firmware uses **"ACK events"** (0x82 packet type) to notify the app, which suggests "acknowledgments sent back." But these are really **"duplicate detection events"**.

Better terminology might be:
- "Repeat detected event"
- "Duplicate heard event"
- "Retransmission event"

But the protocol uses "ACK," which is ambiguous.

### Native App UI

The native app shows:
- "Heard 2 repeats" ✅ (correct wording)
- Detail view shows repeater names and SNR

This could be interpreted as "repeaters sent data back" when really it's "we heard their retransmissions and recognized who they were."

### Protocol Documentation

The MeshCore protocol docs may not explicitly clarify this distinction between:
- Received acknowledgments (active response)
- Overheard duplicates (passive listening)

---

## Verification

### How to Confirm This Understanding

**Test 1: Radio Range**
1. Send message with 3 nearby repeaters → See "Heard 3 repeats"
2. Move repeaters out of radio range (but still in mesh)
3. Send message → See "Heard 0-1 repeats" (only what you can hear)

**Test 2: Radio Off**
1. Send message
2. Immediately turn off device's LoRa receiver (if possible)
3. Result: Count won't increase (because not listening)

**Test 3: SNR Values**
- Native app shows SNR (signal strength) for each repeat
- SNR measures YOUR reception of the repeat
- If repeaters sent ACKs back, SNR would be intermediate hops
- SNR being direct reception confirms local listening

---

## Updated Documentation

All documentation has been corrected to reflect this understanding:

### Updated Files

✅ `001-heard-repeats-architecture.md`
- Corrected system architecture diagram
- Updated protocol details section
- Clarified "how it works"

✅ `001-heard-repeats-display.md`
- Updated summary
- Corrected motivation section
- Fixed technical background

✅ `001-heard-repeats-implementation-guide.md`
- Added clarification note
- Updated "how it works" explanation

✅ `.github/ISSUE_TEMPLATE/001-heard-repeats-feature.md`
- Corrected technical background
- Updated data flow explanation
- Clarified testing scenarios

✅ `README-001.md`
- Complete rewrite of "How It Works" section
- Updated all references
- Added detailed radio listening explanation

---

## Questions This Clarification Answers

### Q: Why does the count sometimes seem low?

**A**: You only count repeaters within your radio range. Far-away repeaters that relay your message but are out of range won't be counted.

### Q: Can I count repeaters globally in the mesh?

**A**: No. The hardware limitation is your radio can only hear what's in range. This is actually a feature - it shows your local coverage.

### Q: Why don't I see repeats when I'm isolated?

**A**: If no repeaters are within radio range, you won't hear any retransmissions, so the count stays at 0-1 (just the delivery confirmation).

### Q: Does this work for direct messages?

**A**: Direct messages use path routing (targeted), not flood routing (broadcast). Different repeaters may relay them, but the semantics are different, so we don't display repeat counts for DMs.

### Q: What if a repeater is far away but has high power?

**A**: If you can hear it (SNR is good enough), it counts. If you can't hear it, it doesn't. Simple as that.

---

## Conclusion

**Key Takeaway**: The companion device's LoRa radio is a **passive listener** that overhears mesh retransmissions, not an active participant receiving routed acknowledgments.

This is actually a **better design** because:
- ✅ Simpler (no ACK routing logic)
- ✅ More reliable (no packet loss on return)
- ✅ Real-time (immediate detection)
- ✅ Efficient (no extra packets)
- ✅ Accurate (measures local coverage)

The firmware does the smart work of detecting duplicates, and the app just displays the count. Simple and elegant!

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-28  
**Corrected By**: @jtstockton  
**Thanks to**: User clarification about native app behavior
