# PocketMesh Enhancements

This directory contains detailed documentation for planned and implemented enhancements to PocketMesh.

## Purpose

This documentation serves to:
- **Plan features** before implementation
- **Document design decisions** for future reference
- **Coordinate with upstream** Avi0n/PocketMesh for merge compatibility
- **Onboard contributors** with clear implementation guides
- **Track progress** on multi-phase features

## Enhancement Structure

Each enhancement includes:
1. **Specification** - Complete feature description, motivation, and design
2. **Implementation Guide** - Step-by-step code changes
3. **Architecture Diagram** - Visual documentation of data flow
4. **GitHub Issue Template** - Ready-to-post issue for tracking

## Active Enhancements

### 001 - Heard Repeats Display
**Status**: 📝 Planning  
**Priority**: Medium  
**Difficulty**: Easy  
**Estimated Time**: 1-2 hours

Display "Heard N repeats" below outgoing channel message bubbles to show mesh propagation.

**Documents**:
- [`001-heard-repeats-display.md`](./001-heard-repeats-display.md) - Full specification
- [`001-heard-repeats-implementation-guide.md`](./001-heard-repeats-implementation-guide.md) - Code changes
- [`001-heard-repeats-architecture.md`](./001-heard-repeats-architecture.md) - Data flow diagrams
- [`001-github-issue-template.md`](./001-github-issue-template.md) - Issue template

**Key Points**:
- ✅ Infrastructure already 90% complete
- ✅ Only UI changes needed
- ✅ Low upstream merge conflict risk
- ✅ Matches native MeshCore app feature

**Next Steps**:
1. Create GitHub issue from template
2. Implement UI changes in `UnifiedMessageBubble.swift`
3. Add SwiftUI previews
4. Test on real hardware with active mesh network
5. Submit PR with screenshots

---

## Completed Enhancements

*None yet - this is the first!*

---

## Enhancement Workflow

### 1. Planning Phase
- [ ] Create enhancement specification document
- [ ] Research native app behavior / protocol capabilities
- [ ] Consider upstream merge implications
- [ ] Document design decisions and alternatives
- [ ] Review with maintainers if needed

### 2. Documentation Phase
- [ ] Write implementation guide
- [ ] Create architecture diagrams
- [ ] Prepare GitHub issue template
- [ ] Add testing plan

### 3. Implementation Phase
- [ ] Create GitHub issue
- [ ] Implement code changes
- [ ] Add unit tests (if applicable)
- [ ] Add SwiftUI previews
- [ ] Test on real hardware
- [ ] Document any deviations from plan

### 4. Review Phase
- [ ] Self-review against acceptance criteria
- [ ] Update documentation with learnings
- [ ] Submit PR
- [ ] Address review feedback

### 5. Completion Phase
- [ ] Merge PR
- [ ] Update enhancement status to "Completed"
- [ ] Add release notes
- [ ] Close GitHub issue

---

## Upstream Merge Strategy

All enhancements should consider merge compatibility with **Avi0n/PocketMesh**.

### Merge Risk Categories

**🟢 Low Risk** (Safe to implement):
- UI-only changes
- Additive features that don't modify existing behavior
- New view components
- User preferences/settings
- Documentation

**🟡 Medium Risk** (Requires coordination):
- Data model changes (SwiftData migrations)
- Protocol parsing changes
- Service layer modifications
- Dependency updates

**🔴 High Risk** (Coordinate with upstream first):
- Core architecture changes
- Breaking API changes
- Major dependency changes
- Protocol version changes

### Best Practices

1. **Keep changes isolated**: Use separate view components, view models, or services when possible
2. **Use feature flags**: Allow features to be easily disabled for testing
3. **Document thoroughly**: Make it clear what was changed and why
4. **Stay in sync**: Regularly merge upstream changes
5. **Communicate**: If making medium/high risk changes, discuss with upstream maintainers

---

## Enhancement Template

When adding a new enhancement, create these files:

```
docs/enhancements/
├── NNN-feature-name-display.md              # Full specification
├── NNN-feature-name-implementation-guide.md # Step-by-step guide
├── NNN-feature-name-architecture.md         # Diagrams (optional)
└── NNN-github-issue-template.md             # Issue template
```

Where `NNN` is a 3-digit sequential number (e.g., 001, 002, 003).

### Specification Template

```markdown
# Enhancement: Feature Name

**Status**: Planning / In Progress / Completed
**Priority**: Low / Medium / High
**Upstream Impact**: Low / Medium / High

## Summary
Brief description in 2-3 sentences.

## Motivation
Why is this needed? What problem does it solve?

## Current Implementation Status
What already exists? What's missing?

## Proposed Solution
How will this be implemented?

## Design Considerations
Alternatives considered, trade-offs, edge cases.

## Implementation Plan
Task breakdown.

## Upstream Compatibility
Merge risk and strategy.

## Testing Plan
How to verify it works.

## Additional Context
Screenshots, references, future enhancements.
```

---

## Contributing

When proposing a new enhancement:

1. **Check for duplicates**: Review existing enhancements and GitHub issues
2. **Start with discussion**: Open a GitHub discussion or issue for feedback
3. **Write specification**: Create detailed enhancement documents
4. **Get review**: Have maintainers review before implementation
5. **Implement carefully**: Follow the implementation guide process
6. **Test thoroughly**: Especially on real hardware
7. **Document learnings**: Update docs with any surprises or changes

---

## Questions?

- **General questions**: Open a GitHub discussion
- **Bug reports**: Use GitHub issue templates
- **Feature requests**: Start with discussion, then create enhancement spec
- **Implementation help**: Reference the implementation guides

---

**Maintained by**: @jtstockton  
**Last Updated**: 2025-12-28
