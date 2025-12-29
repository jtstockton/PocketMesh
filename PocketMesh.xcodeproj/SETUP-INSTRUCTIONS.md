# Enhancement 001: Setup Instructions

## The files I created aren't on your filesystem

The Xcode assistant can't directly write to your filesystem. Here's how to get all the documentation:

## Quick Setup (5 minutes)

### Step 1: Create Directory Structure

```bash
cd ~/path/to/PocketMesh
mkdir -p docs/enhancements
mkdir -p .github/ISSUE_TEMPLATE
```

### Step 2: Get the Documentation Files

I'll provide you with all the content below. For each file, create it and paste the content.

---

## FILE 1: .github/ISSUE_TEMPLATE/enhancement.md

Create: `.github/ISSUE_TEMPLATE/enhancement.md`

```markdown
---
name: Enhancement
about: Propose a new feature or improvement
title: '[ENHANCEMENT] '
labels: enhancement
assignees: ''
---

## Summary
<!-- Brief description of the enhancement -->

## Motivation
<!-- Why is this enhancement needed? What problem does it solve? -->

## Proposed Solution
<!-- Describe your proposed implementation approach -->

## Design Considerations
<!-- Any design decisions, trade-offs, or alternatives considered -->

## Implementation Plan
<!-- Break down the work into tasks if applicable -->
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Upstream Compatibility
<!-- Does this enhancement affect merge compatibility with upstream Avi0n/PocketMesh? -->

## Related Issues/PRs
<!-- Link any related issues or pull requests -->

## Additional Context
<!-- Add any other context, screenshots, or examples -->
```

---

## FILE 2: GitHub Issue for Enhancement 001

**Where to use this**: Copy this directly into GitHub when creating the issue at:
https://github.com/jtstockton/PocketMesh/issues/new

**Title**: `[FEATURE] Display heard repeat count for flooded channel messages`

**Labels**: `enhancement`, `ui`, `messaging`

**Body**: (See the content in the file you're currently viewing: `docsenhancements001-heard-repeats-display.md`)

Just copy the entire contents of the current file and paste it into the GitHub issue!

---

## Simpler Approach: Just Create the GitHub Issue Now

Since you already have the main documentation in the file you're viewing (`docsenhancements001-heard-repeats-display.md`), you can:

1. **Copy the entire content** of the file you're currently in
2. **Go to**: https://github.com/jtstockton/PocketMesh/issues/new
3. **Paste it** as the issue body
4. **Set**:
   - Title: `[FEATURE] Display heard repeat count for flooded channel messages`
   - Labels: `enhancement`, `ui`, `messaging`
   - Assignee: yourself
5. **Attach your 4 screenshots**
6. **Submit**

---

## The Implementation Is Simple Anyway

You don't actually need all the documentation files on disk to implement this. The key info is:

### What to Change

**File**: `UnifiedMessageBubble.swift`  
**Location**: In the `statusRow` computed property

**Add this code** after the status text:

```swift
// Show heard repeats for channel messages
if let channelIndex = message.channelIndex,
   message.heardRepeats > 1,
   message.status == .delivered {
    Text(" • Heard \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

That's literally it! The backend already tracks everything.

---

## Want Me to Show You the Actual Implementation?

Instead of creating documentation files that don't actually save to disk, I can:

1. **Open `UnifiedMessageBubble.swift`** 
2. **Show you exactly where to add the code**
3. **Make the change for you**

Would you like me to do that instead?
