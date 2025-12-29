# Creating the GitHub Issue for Enhancement 001

## Overview

All documentation for the "Heard Repeats" feature has been created. Now you need to create the actual GitHub issue in your repository.

## Steps to Create Issue

### 1. Navigate to Your Repository
Go to: https://github.com/jtstockton/PocketMesh/issues

### 2. Click "New Issue"

### 3. Copy the Issue Template Content

The complete issue template is located at:
```
.github/ISSUE_TEMPLATE/001-heard-repeats-feature.md
```

Copy the entire content (it's already formatted for GitHub).

### 4. Set Issue Metadata

- **Title**: `[FEATURE] Display heard repeat count for flooded channel messages`
- **Labels**: 
  - `enhancement`
  - `ui`
  - `messaging`
- **Assignee**: Yourself (@jtstockton)
- **Milestone**: `v1.1` (or create if doesn't exist)
- **Projects**: Add to your project board if you have one

### 5. Attach Screenshots

Upload the 4 screenshots you have from the native app showing:
1. Message bubble with "Heard 2 repeats"
2. Detail view showing repeaters list
3. Path visualization (1 hop)
4. Path visualization (2 hops)

Add them to the "Visual Examples from Native App" section.

### 6. Review and Submit

Double-check:
- ✅ All links to documentation files are correct
- ✅ Screenshots are attached
- ✅ Labels are set
- ✅ Title is descriptive

Then click **"Submit new issue"**.

---

## After Creating the Issue

### Link Documentation to Issue

Update these files with the issue number:

**File: `docs/enhancements/README.md`**
```markdown
### 001: Heard Repeats Display
**Status**: 📋 Planning  
**GitHub Issue**: #XXX  <-- Add issue number here
```

**File: `docs/enhancements/README-001.md`**
```markdown
## Quick Links

- **GitHub Issue**: #XXX  <-- Add issue number here
```

### Reference in Commits

When you implement the feature, reference the issue in commits:
```bash
git commit -m "feat: display heard repeat count for channel messages

Adds 'Heard N repeats' display below channel message bubbles
to show mesh network activity.

Fixes #XXX"
```

### Update Status as You Work

As you progress, update the issue:

**Planning → In Progress**:
```markdown
**Status**: 🚧 In Progress
**Branch**: `feature/heard-repeats-display`
**Started**: 2025-12-28
```

**In Progress → Complete**:
```markdown
**Status**: ✅ Complete
**Merged**: 2025-12-28
**Release**: v1.1.0
```

---

## Optional: Create a Project Board

For better tracking, create a GitHub Project:

### 1. Go to Projects Tab
https://github.com/jtstockton/PocketMesh/projects

### 2. Create New Project
- **Name**: "PocketMesh Enhancements"
- **Template**: "Board"

### 3. Add Columns
- 📋 **Planned**: Enhancement documented, not started
- 🚧 **In Progress**: Active development
- 🧪 **Testing**: Needs validation with hardware
- ✅ **Complete**: Merged and shipped

### 4. Add the Issue to Project
Drag Enhancement 001 issue to "Planned" column.

---

## Quick Issue Summary

For quick reference, here's what the issue covers:

**Problem**: PocketMesh doesn't show mesh repeat count like native app  
**Solution**: Display "Heard N repeats" below channel messages  
**Effort**: 2-4 hours (mostly UI change)  
**Risk**: Low (additive only, won't conflict with upstream)  
**Value**: High (network health visibility)  

**What's Done**: 90% (backend complete)  
**What's Needed**: UI display in `UnifiedMessageBubble.swift`

---

## Example Issue Screenshot

Your issue should look like this:

```
┌─────────────────────────────────────────────────────────────┐
│ [FEATURE] Display heard repeat count for flooded channel... │
│                                                               │
│ 🏷️ enhancement  🏷️ ui  🏷️ messaging                          │
│ 👤 @jtstockton  📍 Milestone: v1.1                           │
│                                                               │
│ ## Feature Description                                       │
│ Display **"Heard N repeats"** below channel message bubbles  │
│ when the companion device hears repeated LoRa transmissions  │
│ from mesh repeaters...                                       │
│                                                               │
│ [Screenshots attached]                                       │
│                                                               │
│ ## Technical Background                                      │
│ ...                                                          │
│                                                               │
│ ## Implementation Plan                                       │
│ - [ ] Update UnifiedMessageBubble.swift                      │
│ - [ ] Test with real hardware                                │
│ ...                                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Issue Template Not Showing Up?

GitHub issue templates need to be in `.github/ISSUE_TEMPLATE/` with `.md` extension.

Check:
```bash
ls -la .github/ISSUE_TEMPLATE/
# Should show: 001-heard-repeats-feature.md
```

### Can't Add Screenshots?

You can:
1. Drag & drop directly into the issue description
2. Use "Attach files" button
3. Upload to repo and link: `![Screenshot](docs/images/screenshot.png)`

### Links Not Working?

Relative links in issues need to be full URLs:
```markdown
# Instead of:
[Documentation](docs/enhancements/001-heard-repeats-display.md)

# Use:
[Documentation](https://github.com/jtstockton/PocketMesh/blob/main/docs/enhancements/001-heard-repeats-display.md)
```

---

## Next Steps After Issue Created

1. **Clone repo** (if you haven't): `git clone https://github.com/jtstockton/PocketMesh.git`
2. **Create feature branch**: `git checkout -b feature/heard-repeats-display`
3. **Open in Xcode**: `open PocketMesh.xcodeproj`
4. **Locate file**: `Views/UnifiedMessageBubble.swift`
5. **Make changes**: Follow implementation guide
6. **Test**: Run on real hardware with active mesh
7. **Commit**: Reference issue in commit message
8. **Push**: `git push origin feature/heard-repeats-display`
9. **Create PR**: Compare against your `main` branch
10. **Merge**: After testing and review

---

**Ready to Create Issue?** ✅

You now have:
- ✅ Complete issue template
- ✅ Detailed documentation
- ✅ Architecture diagrams
- ✅ Implementation guide
- ✅ Testing scenarios
- ✅ Upstream merge strategy

**Time to create that issue!** 🚀
