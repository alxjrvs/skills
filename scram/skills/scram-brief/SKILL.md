---
name: scram-brief
description: Context brief format reference for SCRAM — brief template, complexity tagging, resolution modes, prioritization table, and backlog format.
user_invocable: false
---

# SCRAM Brief Format Reference

This sub-skill is the canonical reference for context brief authoring in SCRAM. It is used by `scram:developer-breakdown` agents and referenced by the orchestrator during G3 story breakdown. It can also be used standalone for non-SCRAM brief generation.

## Context Brief Format

For each story, write a brief to `SCRAM_WORKSPACE/briefs/<story-slug>.md`:

```markdown
# <Story Title>

## Story
<description and acceptance criteria>

## Doc Section
<reference to the approved doc section this story maps to>

## Budget
`tight | standard | open`
- `tight` — read only this brief and directly referenced files (use for simple, well-scoped stories)
- `standard` — normal codebase exploration permitted (default)
- `open` — full codebase exploration permitted (use for complex or cross-cutting stories)

## Scope Fence
<For stories that touch contested files: explicitly declare which sections/files/functions are OUT OF SCOPE for this story. Example: "Do not modify the authentication middleware — that is owned by story auth-2." Leave blank if no contested files.>

## Files
- <file path> — <why it's relevant>

## Locators
Use content-stable grep anchors. **Never use line numbers.**
- Good: "Find the sentence beginning with 'X' and change to..."
- Bad: "Line 42 of foo.ts"

## Types & Interfaces
- <key type/interface signatures>
- **If modifying any variant of a generated type (Row/Insert/Update), verify all variants have consistent column sets.** Note which variants exist and confirm parity.

## Dependencies
### Code dependencies
- <stories this depends on, and whether they're merged — do not dispatch until these are merged>

### Structural dependencies
- <brief-to-brief format dependencies: "this story extends the manifest format defined in story X">
- <merge order constraints: "must merge before story Y to avoid ancestry contamination">

## Hook Constraint Check
Can this story pass pre-commit hooks independently (without relying on changes from other stories)?
- Yes / No — <explain if No>
- If "No": note the export-before-deletion ordering constraint or other hook dependency. This story may need to be sequenced or its scope adjusted.

## Architecture
<summary of relevant architecture and relevant ADRs from G1>

## Checklist
<Story-specific checklist items. Populate only the checklist(s) relevant to this story's domain.
If no special checklist applies, write "none". Available categories:
- Shared-state, Call-boundary, Async/lifecycle, Test-update (see developer-breakdown agent for item text)>

## UI/UX Context (if tagged)
<relevant design ADRs, existing UI patterns, component references — only populated if the story is tagged as UI/UX>

## Deliverables
- [ ] <file> — <specific change>
```

**Brief review rule:** Reject briefs that contain line-number locators. They must use content-anchored references only. Never use locators of the form `line \d+`, `:\d+$`, or `L\d+`.

## Story Sizing

Each story should touch **no more than 3-5 files** (excluding tests), completable in a single focused session. Prefer **vertical slices** over horizontal slices. Stories must be independent — minimize cross-story dependencies. **If in doubt, split.**

## Complexity Tagging

Each story gets a complexity tag that determines the agent model:

| Complexity | Model | When |
|-----------|-------|------|
| Simple | sonnet | Clear pattern, few files, context brief covers everything |
| Moderate | sonnet | Some judgment needed, moderate file scope |
| Complex | opus | Cross-cutting, architectural judgment, ambiguous requirements |

## Resolution Mode Tagging

Each story gets a resolution mode:

| Mode | When | Handling |
|------|------|----------|
| `commit` | Story produces code/doc changes | Normal dev dispatch with worktree isolation |
| `verify-only` | Story requires only verifying acceptance criteria are already met | Orchestrator handles directly — no dev dispatch, no worktree. Check criteria, update tracker, record in backlog with no commit hash. |
| `conditional` | Story may or may not require changes depending on current state | Dev dispatched to investigate; may resolve as `verify-only` if criteria already met |

## UI/UX Story Tagging (when designer is active)

If a designer is on the team, flag any story that touches user-facing elements (GUI, TUI, CLI output, interactive prompts). These stories require designer approval during the merge stream in addition to standard maintainer approval(s). The designer also contributes design context to these stories' context briefs.

## Prioritization Table

| Priority | Meaning |
|----------|---------|
| P0 — Critical | Blocks other stories, touches shared interfaces/types; do first |
| P1 — High | Core feature work; pick next |
| P2 — Normal | Independent work, no blockers |
| P3 — Low | Nice-to-have, polish, edge cases |

**P0 stories run first as a separate wave** with a quality gate before P1+ begins. This gates complex work on a proven baseline.

## Backlog File Format

Write the backlog to `SCRAM_WORKSPACE/backlog.md`:

```markdown
# SCRAM Backlog — <feature-name>

| # | Story | Priority | Complexity | Resolution | Depends On | UI/UX | Status | Agent | Commit |
|---|-------|----------|------------|------------|------------|-------|--------|-------|--------|
| 1 | Story A | P0 | simple | commit | — | no | pending | — | — |
| 2 | Story B | P0 | complex | commit | — | no | pending | — | — |
| 3 | Story C | P1 | moderate | commit | 1, 2 | yes | pending | — | — |
| 4 | Story D | P2 | simple | verify-only | — | no | pending | — | — |
```

**Status values:** `pending` → `in_progress` → `in_review` → `merged` | `failed` → `escalated` → `in_progress`

Maintainers update this file as stories progress.
