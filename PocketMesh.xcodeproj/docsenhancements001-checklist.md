# Implementation Checklist: Heard Repeats Display

Use this checklist to track your progress implementing the heard repeats feature.

## Phase 1: Documentation & Planning ✅

- [x] Read enhancement specification
- [x] Understand data flow architecture
- [x] Review implementation guide
- [x] Review visual diff
- [x] Understand upstream merge implications

## Phase 2: Setup

- [ ] Create GitHub issue
  - [ ] Copy template from `001-github-issue-template.md`
  - [ ] Add screenshots from native app
  - [ ] Post to https://github.com/jtstockton/PocketMesh/issues
  - [ ] Note issue number: #____

- [ ] Create feature branch
  ```bash
  git checkout main
  git pull origin main
  git checkout -b feature/heard-repeats-display
  ```

- [ ] Review current code
  - [ ] Open `UnifiedMessageBubble.swift`
  - [ ] Locate `statusRow` computed property
  - [ ] Verify context menu already shows repeats

## Phase 3: Implementation

### Code Changes

- [ ] **Add helper property** (after `textColor` around line 148)
  ```swift
  private var shouldShowHeardRepeats: Bool {
      message.isOutgoing &&
      message.isChannelMessage &&
      message.status == .delivered &&
      message.heardRepeats > 0
  }
  ```

- [ ] **Update statusRow** (around line 214)
  - [ ] Add repeat count display in `HStack`
  - [ ] Use conditional `if shouldShowHeardRepeats`
  - [ ] Add bullet separator `Text("•")`
  - [ ] Add checkmark icon `Image(systemName: "checkmark")`
  - [ ] Add repeat text with correct grammar (singular/plural)

- [ ] **Verify styling**
  - [ ] All text uses `.font(.caption2)`
  - [ ] All elements use `.foregroundStyle(.secondary)`
  - [ ] Spacing looks consistent with existing status text

### Build & Compile

- [ ] Clean build folder (`Cmd+Shift+K`)
- [ ] Build project (`Cmd+B`)
- [ ] Resolve any compiler errors
- [ ] No new warnings introduced

## Phase 4: Testing

### Xcode Previews

- [ ] Add preview for channel message with 1 repeat
  ```swift
  #Preview("Channel - 1 Repeat") { ... }
  ```

- [ ] Add preview for channel message with 2+ repeats
  ```swift
  #Preview("Channel - Multiple Repeats") { ... }
  ```

- [ ] Add preview for channel message with 0 repeats
  ```swift
  #Preview("Channel - No Repeats") { ... }
  ```

- [ ] Add preview for DM with repeats (should NOT show)
  ```swift
  #Preview("Direct - Should Not Show Repeats") { ... }
  ```

- [ ] Verify all previews render correctly
- [ ] Check both light and dark mode

### Simulator Testing

- [ ] Run app in simulator
- [ ] Navigate to a channel
- [ ] Verify status row renders correctly (even without repeats)
- [ ] Check layout doesn't break
- [ ] Test both orientations (portrait/landscape)

### Real Hardware Testing

- [ ] Connect to MeshCore device
- [ ] Verify device has active mesh network with repeaters
- [ ] Send test message on channel
- [ ] Verify "Delivered" status appears
- [ ] Wait for repeat count to appear
- [ ] Verify count increments as more ACKs arrive
- [ ] Take screenshot for documentation

#### Test Cases

- [ ] **Test 1: Normal Operation**
  - Expected: "Delivered • ✓ Heard N repeats"
  - Actual: _____________________

- [ ] **Test 2: No Active Repeaters**
  - Expected: "Delivered" (no repeat count)
  - Actual: _____________________

- [ ] **Test 3: Direct Message**
  - Expected: "Delivered" (no repeat count)
  - Actual: _____________________

- [ ] **Test 4: Failed Message**
  - Expected: "Failed" with retry button
  - Actual: _____________________

- [ ] **Test 5: Grammar Check**
  - Send message, get 1 repeat
  - Expected: "Heard 1 repeat" (singular)
  - Actual: _____________________

- [ ] **Test 6: Incremental Updates**
  - Watch repeat count increase over time
  - Expected: Updates smoothly as ACKs arrive
  - Actual: _____________________

### Edge Cases

- [ ] Message with heardRepeats = 0 (should NOT display)
- [ ] Message still pending (should NOT display)
- [ ] Message failed (should NOT display)
- [ ] Message in retrying state (should NOT display)
- [ ] Direct message with heardRepeats > 0 (should NOT display)

## Phase 5: Documentation

- [ ] Take screenshots of implementation
  - [ ] Message with 1 repeat
  - [ ] Message with multiple repeats
  - [ ] Comparison with native app

- [ ] Update any relevant docs
  - [ ] Add screenshots to README if applicable
  - [ ] Update CHANGELOG (if you have one)

- [ ] Document any deviations from plan
  - [ ] Note any unexpected challenges
  - [ ] Document any design decisions made during implementation

## Phase 6: Code Review (Self)

- [ ] Review code against specifications
- [ ] Check code style matches project conventions
- [ ] Verify no debug code left in
- [ ] Check for commented-out code
- [ ] Verify proper spacing and formatting
- [ ] Check all conditionals are correct
- [ ] Verify no hardcoded values
- [ ] Check accessibility (VoiceOver support if needed)

### Acceptance Criteria

- [ ] ✅ Repeat count displays below outgoing channel messages
- [ ] ✅ Shows "Heard 1 repeat" (singular) correctly
- [ ] ✅ Shows "Heard N repeats" (plural) correctly
- [ ] ✅ Only displays when `heardRepeats > 0`
- [ ] ✅ Does NOT display for direct messages
- [ ] ✅ Matches native app style (gray text, small font)
- [ ] ✅ Works in both light and dark mode
- [ ] ✅ Xcode previews render correctly
- [ ] ✅ Tested on real hardware with mesh network

## Phase 7: Commit & Push

- [ ] Stage changes
  ```bash
  git add UnifiedMessageBubble.swift
  ```

- [ ] Commit with descriptive message
  ```bash
  git commit -m "feat: Display heard repeats count for channel messages

  - Add repeat count display below outgoing channel message bubbles
  - Shows 'Heard N repeats' when heardRepeats > 0
  - Only displays for channel messages (not DMs)
  - Matches native MeshCore app functionality

  Closes #X"
  ```
  (Replace X with your issue number)

- [ ] Push to GitHub
  ```bash
  git push origin feature/heard-repeats-display
  ```

## Phase 8: Pull Request

- [ ] Create pull request on GitHub
  - [ ] Title: "feat: Display heard repeats count for channel messages"
  - [ ] Description includes:
    - [ ] Summary of changes
    - [ ] Screenshots (before/after)
    - [ ] Testing notes
    - [ ] Reference to issue number

- [ ] Fill out PR template
  - [ ] What changed
  - [ ] Why changed
  - [ ] How to test
  - [ ] Checklist items

- [ ] Add screenshots to PR
  - [ ] Implementation screenshot
  - [ ] Comparison with native app
  - [ ] Xcode preview screenshot

- [ ] Request review (if applicable)
- [ ] Link PR to issue (`Closes #X`)

## Phase 9: Post-Merge

- [ ] Verify issue auto-closed
- [ ] Update enhancement status to "Completed"
- [ ] Update `docs/enhancements/README.md`
- [ ] Add to completed enhancements list
- [ ] Celebrate! 🎉

## Phase 10: Future Work

Consider for Phase 2:
- [ ] Add tappable detail view
- [ ] Show individual repeater names
- [ ] Display SNR and hop counts
- [ ] Create new enhancement document for Phase 2

---

## Notes & Observations

Use this space to jot down any notes, issues encountered, or observations during implementation:

```
Date: ____________

Notes:
- 
- 
- 

Issues Encountered:
- 
- 

Solutions Found:
- 
- 

Time Spent: _____ hours
```

---

## Quick Reference

**Issue Number**: #_____  
**Branch**: `feature/heard-repeats-display`  
**File Changed**: `UnifiedMessageBubble.swift`  
**Lines Modified**: Approximately 10-15 lines added  

**Key Documentation**:
- Specification: `001-heard-repeats-display.md`
- Implementation: `001-heard-repeats-implementation-guide.md`
- Visual Diff: `001-visual-diff.md`
- Architecture: `001-heard-repeats-architecture.md`

**Testing Hardware**:
- [ ] Device Model: _________________
- [ ] Firmware Version: _____________
- [ ] Number of Repeaters: __________
- [ ] Network Configuration: ________

---

**Started**: ___________  
**Completed**: ___________  
**Total Time**: ___________ hours
