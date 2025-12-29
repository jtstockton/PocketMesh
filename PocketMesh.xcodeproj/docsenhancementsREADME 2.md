# PocketMesh Enhancement Tracking

This directory contains detailed documentation for planned and implemented enhancements to PocketMesh.

## Active Enhancements

### 001: Heard Repeats Display
**Status**: 📋 Planning  
**Priority**: 🔵 Medium  
**Complexity**: 🟢 Low  

Display "Heard N repeats" below channel message bubbles to show mesh network activity.

- **Summary**: [README-001.md](README-001.md)
- **Feature Spec**: [001-heard-repeats-display.md](001-heard-repeats-display.md)
- **Architecture**: [001-heard-repeats-architecture.md](001-heard-repeats-architecture.md)
- **Implementation**: [001-heard-repeats-implementation-guide.md](001-heard-repeats-implementation-guide.md)
- **GitHub Issue**: [.github/ISSUE_TEMPLATE/001-heard-repeats-feature.md](../../.github/ISSUE_TEMPLATE/001-heard-repeats-feature.md)

**Quick Status**: 90% complete (backend done, needs UI display)

---

## Enhancement Status Key

- 📋 **Planning**: Design and documentation phase
- 🚧 **In Progress**: Active development
- ✅ **Complete**: Merged and shipped
- ⏸️ **On Hold**: Deferred for later
- ❌ **Cancelled**: Will not implement

## Priority Levels

- 🔴 **High**: Critical for core functionality
- 🔵 **Medium**: Valuable enhancement, not urgent
- 🟢 **Low**: Nice-to-have, future consideration

## Complexity Estimates

- 🟢 **Low**: < 1 day of work
- 🟡 **Medium**: 1-3 days of work
- 🔴 **High**: > 3 days of work

---

## How to Propose an Enhancement

1. **Create documentation** in this directory:
   - `NNN-feature-name-display.md` - Feature specification
   - `NNN-feature-name-architecture.md` - Technical architecture (optional)
   - `NNN-feature-name-implementation-guide.md` - Code changes needed
   - `README-NNN.md` - Quick reference summary

2. **Create GitHub issue** using template:
   - Copy `.github/ISSUE_TEMPLATE/001-heard-repeats-feature.md` as template
   - Update with your feature details
   - Link to documentation files

3. **Consider upstream impact**:
   - Will this conflict with Avi0n/PocketMesh merges?
   - Is it additive or does it modify core functionality?
   - Document merge strategy

4. **Get feedback** before implementing:
   - Discuss in GitHub issues
   - Consider alternatives
   - Validate technical approach

---

## Upstream Merge Considerations

PocketMesh is forked from [Avi0n/PocketMesh](https://github.com/Avi0n/PocketMesh). When planning enhancements:

### ✅ Low Merge Risk
- Additive UI features (new views, display options)
- Optional settings/preferences
- View layer modifications
- Documentation improvements

### ⚠️ Medium Merge Risk
- Service layer enhancements
- New data model properties (if schema compatible)
- Protocol handler extensions
- Build configuration changes

### ❌ High Merge Risk
- Core protocol changes
- Database schema breaking changes
- Transport layer modifications
- Significant architectural refactoring

**Strategy**: Favor low-risk, additive changes that can be easily cherry-picked or merged with upstream updates.

---

## Enhancement Template Structure

Each enhancement should include:

### 1. Feature Specification (`NNN-feature-name-display.md`)
- **Summary**: What does this do?
- **Motivation**: Why do we need this?
- **Current behavior**: What exists today?
- **Desired behavior**: What should change?
- **UI mockups**: Visual examples
- **Edge cases**: What could go wrong?

### 2. Architecture Document (`NNN-feature-name-architecture.md`)
- **System architecture**: How components interact
- **Data flow**: How data moves through the system
- **Protocol details**: Binary formats, packet structures
- **Code structure**: Which files are affected
- **Performance considerations**: Resource usage
- **Testing scenarios**: How to validate

### 3. Implementation Guide (`NNN-feature-name-implementation-guide.md`)
- **Files to modify**: Exact file paths
- **Code changes**: Before/after examples
- **Step-by-step instructions**: Detailed walkthrough
- **Testing checklist**: Validation steps
- **Commit strategy**: How to structure commits

### 4. Quick Reference (`README-NNN.md`)
- **TL;DR summary**: One-page overview
- **Status tracking**: Current progress
- **Quick links**: Navigation to details
- **FAQs**: Common questions answered

---

## Related Documentation

- **Project README**: [../README.md](../README.md)
- **Getting Started**: [../GettingStarted.md](../GettingStarted.md)
- **MeshCore Protocol**: [../MeshCore.md](../MeshCore.md)
- **Protocol Internals**: [../ProtocolInternals.md](../ProtocolInternals.md)
- **GitHub Issues**: [.github/ISSUE_TEMPLATE/](../../.github/ISSUE_TEMPLATE/)

---

## Changelog

### 2025-12-28
- Created enhancement tracking system
- Added Enhancement 001: Heard Repeats Display
- Established documentation standards
- Created GitHub issue template

---

**Maintainer**: @jtstockton  
**Last Updated**: 2025-12-28
