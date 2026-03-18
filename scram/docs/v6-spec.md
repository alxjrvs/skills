# SCRAM v6.0.0 — Restructuring Specification

This document is the authoritative specification for the SCRAM v6.0.0 restructuring. It describes the final state of all changed files and artifacts. Developers build against this document; it is precise enough to derive TDD tests from.

**Source ADRs:** ADR-001 through ADR-005 in `scram/docs/adr/`
**Breaking change:** Agent identifiers `scram:developer-reviewer`, `scram:developer-breakdown`, and `scram:developer-impl` replace `scram:developer`.

---

## 1. Split Developer Agent (ADR-001)

### 1.1 Overview

`scram/agents/developer.md` is replaced by three focused agent files. The monolith is deleted. No content is added to any file; content moves from `developer.md` to the appropriate focused file.

| File | Agent Identifier | Dispatch Mode |
|------|-----------------|---------------|
| `scram/agents/developer-reviewer.md` | `scram:developer-reviewer` | G1 and G2 doc review |
| `scram/agents/developer-breakdown.md` | `scram:developer-breakdown` | G3 story breakdown and context brief authoring |
| `scram/agents/developer-impl.md` | `scram:developer-impl` | Concurrent streams — TDD implementation |

### 1.2 `developer-reviewer.md`

**Frontmatter:**

```yaml
---
name: developer-reviewer
description: Developer reviewer for G1 ADR review and G2 doc review. Evaluates docs for feasibility, testability, ambiguity, and architecture fit. Read-only — writes review reports to SCRAM_WORKSPACE only.
model: sonnet
tools:
  - Read
  - Glob
  - Grep
---
```

**Sections:**

- `## Role` — brief identity statement: developer reviewer for G1/G2, read-only, no code changes
- `## Review Criteria` — the four criteria from current `developer.md`'s "Doc Review" section:
  - Feasibility — can this be implemented as described?
  - Testability — can TDD tests be derived from these docs?
  - Ambiguity — gaps, contradictions, underspecified behaviors?
  - Architecture — does the described API fit existing codebase patterns?
- `## Process` — read the docs or ADRs, evaluate each criterion, write the report
- `## Report Format` — structured report block (see 1.5)
- `## Constraints` — no file writes to the repo; write only to `SCRAM_WORKSPACE/`; no git operations; no `isolation` context applies to this agent

**No isolation contract section.** No TDD phase descriptions. No story checklists. No commit instructions.

### 1.3 `developer-breakdown.md`

**Frontmatter:**

```yaml
---
name: developer-breakdown
description: Developer for G3 story breakdown and context brief authoring. Sizes stories, tags complexity, writes context brief files to SCRAM_WORKSPACE/briefs/. Read-only on the repo — writes only to SCRAM_WORKSPACE.
model: sonnet
tools:
  - Read
  - Write
  - Glob
  - Grep
---
```

**Sections:**

- `## Role` — brief identity statement: story breakdown and context brief authoring at G3
- `## Story Sizing` — rules from current `developer.md`'s "Story Breakdown" section:
  - Each story touches no more than 3-5 files (excluding tests)
  - Completable in a single session
  - Flag splitting needs
- `## Complexity Tagging` — simple/moderate/complex tags and when to apply each
- `## Context Brief Format` — the full brief template (reproduced from SKILL.md G3 section, which is the authoritative source; the brief format in the agent must match exactly):

```markdown
# <Story Title>

## Story
<description and acceptance criteria>

## Doc Section
<reference to the approved doc section this story maps to>

## Files
- <file path> — <why it's relevant>

## Locators
Use content-stable grep anchors. **Never use line numbers.**
- Good: "Find the sentence beginning with 'X' and change to..."
- Bad: "Line 42 of foo.ts"

## Types & Interfaces
- <key type/interface signatures>

## Dependencies
- <stories this depends on, and whether they're merged>

## Architecture
<summary of relevant architecture and relevant ADRs from G1>

## Checklist
<story-specific checklist items, if applicable — see categories below>

## UI/UX Context (if tagged)
<relevant design ADRs, existing UI patterns, component references — only populated if the story is tagged as UI/UX>

## Deliverables
- [ ] <file> — <specific change>
```

- `## Checklist Categories` — the four checklist types that move from `developer.md`'s "Story-Specific Checklists" section. These are reproduced verbatim in this section so the breakdown agent can populate the `## Checklist` field in each brief with only the relevant items:
  - **Shared-state stories** (DB, shared config, global state): read current version from integration branch before writing changes; do NOT modify non-test files to make tests pass; summarize each fixture/migration change semantically before committing
  - **Call-boundary stories** (removing/renaming handlers, endpoints, exports): verify all callers have been updated or removed; check both sides of every call boundary
  - **Async/lifecycle stories** (React hooks, timers, event handlers, queues): no async calls inside setState updaters; closures in timers/callbacks read from refs; beforeunload/cleanup handlers flush pending work; creation guards prevent duplicate concurrent async operations
  - **Test-update stories**: do NOT modify application code to make tests pass; if a test cannot pass without changing application code, escalate

- `## Output Rules` — write each brief as a file at `SCRAM_WORKSPACE/briefs/<story-slug>.md`; never use line-number locators; reject any locator of the form `line \d+`, `:\d+$`, or `L\d+`
- `## Constraints` — no file writes to the repo; write only to `SCRAM_WORKSPACE/briefs/`; no git operations

**No isolation contract section.** No RED/GREEN/REFACTOR phases. No Story Report format.

### 1.4 `developer-impl.md`

**Frontmatter:**

```yaml
---
name: developer-impl
description: Developer for TDD implementation in isolated worktrees during concurrent streams. Follows strict Red-Green-Refactor discipline. Default model sonnet, scalable to opus based on story complexity.
model: sonnet
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - LS
---
```

**Sections:**

- `## Role` — brief identity statement: TDD implementation in isolated worktrees
- `## Setup` — combined single verification step (the duplicate step 3 and redundant branch-verification block from the current `developer.md` are resolved by merging into one step):
  1. Check out from the integration branch — run the two git commands (checkout integration branch, then create story branch)
  2. **Isolation Contract** — verify all four conditions before any file modifications:
     - `pwd` is within the assigned worktree path (not the main repo)
     - `git rev-parse --abbrev-ref HEAD` matches the story branch (`<integration-branch>/<story-slug>`)
     - `git status` shows no untracked files from other stories
     - NOT on the integration branch itself — must be on a story branch created FROM it
     - If ANY check fails, **STOP and report to the orchestrator**
  3. Re-verify before every commit — run `git rev-parse --abbrev-ref HEAD` again before `git commit`
- `## Pre-flight` — single pre-flight block (merged from the duplicate step 3 in current `developer.md`):
  - On the correct branch (story branch created from integration branch, NOT from `main`)
  - Context brief file exists at `SCRAM_WORKSPACE/briefs/<story-slug>.md`
  - Referenced doc section exists
  - Project builds cleanly
  - Existing tests pass
  - If any pre-flight check fails, report immediately with failure reason — do not proceed
- `## Reading` — read docs-as-spec, read context brief (including `## Checklist` section), read CLAUDE.md, find existing patterns
- `## RED — Write Failing Tests` — exact content from current `developer.md` Phase 1
- `## GREEN — Write Minimum Code to Pass` — exact content from current `developer.md` Phase 2
- `## REFACTOR — Improve Code Quality` — exact content from current `developer.md` Phase 3
- `## Escalation` — exact content from current `developer.md` Escalation section
- `## Context Management` — exact content from current `developer.md` Context Management section
- `## Story Report` — the structured report format (see 1.5)
- `## Constraints` — exact content from current `developer.md` Constraints section

**No doc review criteria.** No story breakdown instructions. No story-specific checklists (they are in the context brief's `## Checklist` section, written by `developer-breakdown`).

### 1.5 Report Formats

**`developer-reviewer` report:**

```
## Developer Review Report
- **Gate:** G1 | G2
- **Status:** approved | revisions_needed
- **Feasibility:** <assessment>
- **Testability:** <assessment>
- **Ambiguity flags:** <list or "none">
- **Architecture concerns:** <list or "none">
- **Blocking issues:** <list of items that would block implementation, or "none">
- **Suggested revisions:** <specific, actionable feedback, or "none">
```

**`developer-impl` Story Report** (unchanged from current `developer.md`):

```
## Story Report
- **Story:** <story-id>
- **Branch:** <branch name from git rev-parse --abbrev-ref HEAD>
- **Commit:** <commit SHA from git rev-parse HEAD>
- **Status:** completed | partial | failed
- **Phase reached:** RED | GREEN | REFACTOR
- **Failure reason:** none | context_exhaustion | test_failure | build_error | missing_dependency | unclear_spec | pre_flight_failure
- **Failure details:** <specific error message or description, if failed>
- **Files changed:**
  - <file path> — <brief description>
- **Tests:** <pass count>/<total count> passing
- **Pre-existing issues:** <list or "none">
- **Design decisions:** <any architectural choices made and why>
- **Remaining work:** <what's left, if partial>
- **Escalation notes:** <if escalated: what was different from previous attempt>
```

### 1.6 SKILL.md Dispatch Instruction Changes

The Team Composition table in SKILL.md is updated. The `Developer` row splits into three rows:

| Role | Count | Default Model | Flex To | Agent (`subagent_type`) | Responsibility |
|------|-------|---------------|---------|-------------------------|----------------|
| Developer (Reviewer) | 1-3 | sonnet | (fixed) | `scram:developer-reviewer` | G1 ADR review, G2 doc review |
| Developer (Breakdown) | 1-3 | sonnet | (fixed) | `scram:developer-breakdown` | G3 story sizing, context brief authoring |
| Developer (Impl) | 1-5 | sonnet | opus | `scram:developer-impl` | TDD implementation, escalation handling (max 5) |

In G1, dispatch `scram:developer-reviewer` (not `scram:developer`).
In G2, dispatch `scram:developer-reviewer` (not `scram:developer`).
In G3, dispatch `scram:developer-breakdown` (not `scram:developer`).
In concurrent streams, dispatch `scram:developer-impl` (not `scram:developer`).

The context brief template in the G3 section of SKILL.md gains a `## Checklist` section between `## Architecture` and `## Deliverables`:

```markdown
## Checklist
<Story-specific checklist items. Populate only the checklist(s) relevant to this story's domain.
If no special checklist applies, write "none". Available categories:
- Shared-state, Call-boundary, Async/lifecycle, Test-update (see developer-breakdown agent for item text)>
```

### 1.7 Deletion

`scram/agents/developer.md` is deleted. No content from it is lost — all content moves to the three new files.

---

## 2. Retro Facilitator Skill (ADR-002)

### 2.1 New Skill File

**Location:** `scram/skills/scram-retro/SKILL.md`
**Dispatch identifier:** `scram:scram-retro` (plugin name `:` skill directory name)

Skills are dispatched by their directory name, not the `name` field in frontmatter. The directory `scram/skills/scram-retro/` produces the identifier `scram:scram-retro`. References throughout this spec and SKILL.md use `scram:scram-retro` as the dispatch identifier.

**Frontmatter:**

```yaml
---
name: scram-retro
description: Standalone retrospective facilitator for SCRAM runs. Receives workspace context, reads in-flight.md if it exists, dispatches maintainers for ticket writing and discussion, compiles results, and presents consensus changes.
user_invocable: false
---
```

### 2.2 Retro Skill Content

The skill is self-contained. It does not require reading the main SKILL.md to function. It receives all inputs as dispatch arguments.

**Dispatch arguments received (from orchestrator):**
- `SCRAM_WORKSPACE` — absolute path to the SCRAM workspace
- `in_flight_path` — absolute path to `SCRAM_WORKSPACE/retro/in-flight.md` (may not exist; skill checks)
- `session_context` — object containing: `total_stories` (integer), `escalations` (integer), `halt_events` (integer, derived by counting `HALT` entries in session.md's Notes section), `feature_name` (string). The orchestrator computes these values by reading `SCRAM_WORKSPACE/backlog.md` (story counts, escalation counts) and `SCRAM_WORKSPACE/session.md` (HALT events logged in Notes section) before dispatching the retro facilitator.

**Skill sections:**

- `## Setup` — read `SCRAM_WORKSPACE/retro/in-flight.md` first if it exists; read `SCRAM_WORKSPACE/backlog.md` and `SCRAM_WORKSPACE/session.md`; these form the seed material for ticket writing
- `## Phase 1: Ticket Submission` — dispatch both maintainers as fresh one-shots, each receives: final backlog.md, final session.md, and the in-flight.md content (if it exists); each writes attributed tickets to `SCRAM_WORKSPACE/retro/tickets/<name>.md`
- `## Ticket Format` — the full ticket format (moved from SKILL.md G5):

```markdown
# Tickets — <Maintainer Name>

## 1. <short title>

### Category
process | tooling | communication | prompt_quality | missing_capability

### Observation
<what happened or didn't happen — factual>

### Impact
<how this affected the SCRAM run — time wasted, quality risk, friction>

### Suggested Improvement
<specific, actionable change to SKILL.md or an agent definition>
<include the file to change and what to change in it>

### Current Text
> <exact string from the file to be changed — required for agree/propose phase>

### Proposed Text
> <exact replacement string — required for agree/propose phase>
```

The `### Current Text` and `### Proposed Text` fields are required. They must contain exact string matches, not paraphrases. This enables future auto-application.

- `## Phase 2: Discussion` — dispatch both maintainers again; each reads all tickets; for each ticket they agree/disagree/refine; write discussion results to `SCRAM_WORKSPACE/retro/discussions/<topic-slug>.md`
- `## Discussion Format` — the full discussion format (moved from SKILL.md G5):

```markdown
# Discussion: <ticket title>

## Ticket
<original ticket text>

## Status
agreed | disagreed

## Proposed Change
**File:** <path to skill or agent file>
**Change:** <add | modify | remove>
**Current text:**
> <the existing text, if modifying or removing>

**Proposed text:**
> <the agreed text>

**Rationale:** <why this improves the prompt>

## Disagreement (if any)
- <maintainer>: <concern>
```

- `## Compile and Present` — orchestrator compiles results and presents to user (moved from SKILL.md G5)
- `## File Issue` — GitHub issue filing flow with `AskUserQuestion` (moved from SKILL.md G5); issue body is scrubbed of all business-specific information
- `## Constraints` — no business-specific information in tickets or issues; tickets must describe process improvements in generic terms

### 2.3 In-Flight Capture

**New workspace artifact:** `SCRAM_WORKSPACE/retro/in-flight.md`

This file is created lazily — maintainers append to it when friction occurs; it need not be created explicitly at G0. The `scram-init.sh` script creates the `retro/` directory but not the file itself.

**Instruction added to `merge-maintainer.md`** (in the section covering the merge stream, after the Report Format section):

> **In-Flight Capture:** When you encounter process friction during the stream — a confusing instruction, an unexpected git state, an ambiguous handoff, an isolation failure — append a one-liner to `SCRAM_WORKSPACE/retro/in-flight.md`. Format: `[timestamp] [role]: <observation>`. Example: `[14:23] Metron: story-auth-middleware dev committed to integration branch before story branch was confirmed`. Capture and continue. Synthesis happens at G5.

**Instruction added to `code-maintainer.md`** (in the same position — after the Report Format section):

> **In-Flight Capture:** When you encounter process friction during the stream — a confusing instruction, an unexpected git state, an ambiguous handoff — append a one-liner to `SCRAM_WORKSPACE/retro/in-flight.md`. Format: `[timestamp] [role]: <observation>`. Capture and continue. Synthesis happens at G5.

The format is identical in both files. The instruction is placed in the streams-facing section, not in any retro section.

### 2.4 Updated Workspace Structure

The SCRAM workspace structure (documented in SKILL.md) gains `retro/in-flight.md`:

```
~/.scram/
└── <project-dir>--<feature-name>--<invocation-id>/
    ├── session.md
    ├── backlog.md
    ├── briefs/
    │   └── <story-slug>.md
    ├── retro/
    │   ├── in-flight.md            # appended during streams; read by retro facilitator at G5
    │   ├── tickets/
    │   │   ├── metron.md
    │   │   └── highfather.md
    │   └── discussions/
    │       └── <topic-slug>.md
    └── events/                      # reserved for future use (created by scram-init.sh)
```

> **Note:** Section 6.3 contains the canonical final workspace structure. This diagram shows the retro-specific additions.

### 2.5 Collapsed G5 Section in SKILL.md

The current G5 section (approximately 134 lines) collapses to:

```markdown
## G5: Retrospective (optional)

If the user opted in to a retrospective during G0, dispatch `scram:scram-retro` with:
- `SCRAM_WORKSPACE` — absolute path to the workspace
- `in_flight_path` — `SCRAM_WORKSPACE/retro/in-flight.md` (pass the path; skill checks if the file exists)
- `session_context` — `{ total_stories, escalations, halt_events, feature_name }`

The retro facilitator is self-contained. It reads workspace artifacts, dispatches maintainers as fresh one-shots, compiles results, and presents consensus changes to the user. After the retro completes, update session manifest to `complete` and remove the `scram-session-*` memory reference.
```

---

## 3. SKILL.md Deduplication (ADR-003)

### 3.1 Sections Removed from SKILL.md

The following content blocks are removed from SKILL.md. Each is identified by a content anchor (the heading or first distinctive sentence of the block) since line numbers go stale.

**Removed: TDD phase descriptions in Dev Stream section**
- Anchor: the `#### Phase 1: RED — Write Failing Tests` through `#### Phase 3: REFACTOR — Improve Code Quality` subsections within "Dev Stream (Red-Green-Refactor)"
- Size: approximately 25 lines
- Replacement (single sentence): "Dispatch `scram:developer-impl` with the context brief — the agent follows its TDD discipline as defined in its agent file."

**Removed: 19-step merge stream review checklist**
- Anchor: the numbered list starting with "1. **Pre-review git health check**" and ending with "19. Update tracker if configured" in the "Merge Stream" section
- Size: approximately 27 lines
- Replacement (single sentence): "Dispatch Metron with the Story Report. Metron performs pre-review git health checks, dual-approval coordination, and merge execution per its agent definition."

**Removed: G0 environment check steps in New Session Setup**
- Anchor: the numbered list "1. `bun install`" through "9. Save a memory reference" in the G0 "New Session Setup" section
- Size: approximately 15 lines from the skill (the skill-level G0 steps reference both maintainers running environment checks)
- Replacement: "Both maintainers run environment checks and create the integration branch per their agent definitions. The orchestrator creates the SCRAM workspace using `scram-init.sh` and writes the session manifest."

**Removed: ADR review criteria in G1 section**
- Anchor: the bullet list "Are decisions well-reasoned with clear trade-offs?" through "If designer is active: designer reviews design ADRs" in G1 Review
- Size: approximately 8 lines
- Replacement: "Highfather reviews ADRs per code maintainer definition. Metron performs lightweight approval per merge maintainer definition. Dispatch one `scram:developer-reviewer` for the dev perspective. Once approved, code maintainer merges ADRs into the integration branch."
- Also update participant language from "one dev" to "one `scram:developer-reviewer`" in the G1 Review intro text.

**Removed: Doc review criteria in G2 section**
- Anchor: the two per-maintainer review lens blocks ("Code maintainer (Highfather) reviews for architectural coherence" and "Merge maintainer (Metron) reviews for implementability") in G2 Review
- Size: approximately 12 lines
- Replacement: "Both maintainers + one `scram:developer-reviewer` review docs per their agent definitions. If designer is active: designer reviews for design ADR alignment. Once approved, maintainers merge docs into the integration branch."
- Also update participant language from "one dev" to "one `scram:developer-reviewer`" in the G2 Review intro text.

### 3.2 Agent File Authority

**`merge-maintainer.md` is the authoritative file for shared merge mechanics.** The following sections in `merge-maintainer.md` are considered canonical:
- G0 procedure (full checklist)
- Approval tiers (simple vs. moderate/complex)
- Merging — atomic, per-story (full steps)
- Conflict resolution
- Tracker updates
- Commit format

**`code-maintainer.md` carries a selective version** of the same mechanics. Sections that both agents must execute independently (G0, approval tiers, conflict resolution, commit format) are retained at full length. Only sections where the code maintainer delegates to the merge maintainer are condensed:
- G0 procedure (same full checklist — both agents must independently execute this; condensing would create risk)
- Approval tiers (same — code maintainer must know when it needs to co-approve)
- Merging — reference to merge-maintainer as executor: "The merge maintainer executes the merge; you approve"
- Conflict resolution (same — code maintainer participates in conflict decisions)
- Tracker updates — condensed: "Merge maintainer handles tracker updates; report misses"
- Commit format (same — code maintainer may author commits in docs-only runs)

**Navigation note** added to the start of the "Merging" section in `code-maintainer.md`:

> The merge maintainer (`merge-maintainer.md`) is the authoritative executor for merges and maintains the canonical merge mechanics. This file carries the sections you need for independent dispatch; for full merge procedure detail, see merge-maintainer.md.

### 3.3 Constraints Block

The constraints block at the end of SKILL.md (currently approximately 15 bullets) is audited and cut to 6-8 bullets. Retained bullets are those **not** stated elsewhere in any agent definition. The surviving bullets cover:
1. Dev agents dispatched with `isolation: "worktree"` (Tier 1 implementation) — non-negotiable even for simple stories (this is a dispatch-level constraint the orchestrator owns, not the agent)
2. All developers use strict TDD — tests before implementation; for content-only stories, use the substitute discipline (stated here because it governs how the orchestrator evaluates agent output)
3. Never skip hooks or force-push (orchestrator-level constraint)
4. New commits only — never amend (orchestrator-level)
5. One atomic commit per story (orchestrator-level)
6. SCRAM workspace is outside the project repo — never committed to git (orchestrator-level, governs workspace path construction)
7. G2 doc work MUST use `scram:doc-specialist` agents — developers may not substitute (dispatch-routing constraint the orchestrator owns)
8. External service work — staging pattern (orchestrator-level approval gate)

Bullets removed from constraints (because they duplicate agent-specific content):
- Scale team size to task complexity (stated in Team Composition table)
- If uncertain about requirements, ask the user (general guidance, not a SCRAM-specific constraint)
- All agents must use their defined structured report format (agent files own this; the orchestrator does not need to enforce it in the skill)
- Backlog and context briefs are files in the SCRAM workspace, not inline context (stated in G3 section)

---

## 4. Two-Tier Dispatch (ADR-004)

### 4.1 Tier Definitions

**Tier 1 — Implementation (worktree isolation)**
- Applies to: `scram:developer-impl` dispatches in the concurrent streams phase
- Applies to: `scram:doc-specialist` dispatches at G1 and G2 (doc specialists write to the repo; isolation is warranted)
- Parameter: `isolation: "worktree"` on the Agent tool call
- Contract: four verification checks, re-verify before commit, HALT on failure

**Tier 2 — Read-only (no worktree isolation)**
- Applies to: `scram:developer-reviewer` at G1 and G2
- Applies to: `scram:developer-breakdown` at G3
- Parameter: no `isolation` parameter on the Agent tool call — standard one-shot dispatch
- Contract: reads files; writes only to `SCRAM_WORKSPACE/`; no git operations; no branch exists

### 4.2 SKILL.md Dispatch Instruction Changes

The G1 review section dispatch instruction explicitly states:

> Dispatch `scram:developer-reviewer` without worktree isolation — Tier 2 dispatch. The agent reads docs and ADRs and writes a review report to `SCRAM_WORKSPACE/`. No branch is created.

The G2 review section dispatch instruction:

> Dispatch `scram:developer-reviewer` without worktree isolation — Tier 2 dispatch. The agent reads docs and writes a review to `SCRAM_WORKSPACE/`. No branch is created.

The G3 breakdown dispatch instruction:

> Dispatch `scram:developer-breakdown` without worktree isolation — Tier 2 dispatch. The agent reads docs-as-spec and writes context briefs to `SCRAM_WORKSPACE/briefs/`. No branch is created.

### 4.3 No-Write Constraint Text

The following constraint appears in both `developer-reviewer.md` and `developer-breakdown.md` under `## Constraints`:

> You operate in Tier 2 — read-only dispatch. You have no worktree and no story branch. You MUST NOT write any files to the project repository. Write only to `SCRAM_WORKSPACE/` (review reports, context briefs). If you find a typo in docs, note it in your report — do not fix it in place. There is no isolation mechanism to contain repo modifications made from this dispatch.

### 4.4 Structural Enforcement

`developer-reviewer.md` has no isolation contract section. `developer-breakdown.md` has no isolation contract section. The isolation contract exists only in `developer-impl.md`. The tier distinction is enforced at the agent definition level — a reviewer or breakdown agent cannot accidentally apply the isolation contract because the contract text is not present.

The tools list in `developer-reviewer.md` omits `Write`, `Edit`, and `Bash` — removing the capability at the tool level, not just at the instruction level. `developer-breakdown.md` includes `Write` (to write brief files to `SCRAM_WORKSPACE/`) but omits `Edit`, `Bash`, and `LS`.

---

## 5. Scripts and Hooks Layer (ADR-005)

### 5.1 File Layout

```
scram/
├── scripts/
│   ├── halt-check.sh
│   ├── scram-init.sh
│   ├── scram-discover.sh
│   ├── pre-merge-check.sh
│   ├── brief-lint.sh
│   └── session-checkpoint.sh
└── hooks/
    └── hooks.json
```

Note: the hooks file lives in `scram/hooks/hooks.json` — a subdirectory, consistent with the tmux plugin convention. It is NOT at `scram/hooks.json`.

### 5.2 `hooks/hooks.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/halt-check.sh",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/brief-lint.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/session-checkpoint.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Hook behavior notes:**
- The `matcher` field is a regex matched against the tool name. `"Agent"` matches Agent tool calls; `"Write"` matches Write tool calls.
- There is no path-based filtering in the plugin hook system. `brief-lint.sh` fires on ALL Write calls. The script itself checks whether the file path is under `$SCRAM_WORKSPACE/briefs/` and exits 0 (no-op) if not. If `SCRAM_WORKSPACE` is unset, the script exits 0 (no-op).
- A non-zero exit from a `PreToolUse` hook blocks the tool call. This applies uniformly to all tool types (Agent, Write, etc.).
- The Stop hook uses a dedicated `session-checkpoint.sh` script (not `scram-init.sh` with a `checkpoint` flag) to keep script responsibilities clean.

### 5.3 Script Interfaces

#### `halt-check.sh`

**Purpose:** Block agent dispatch when a HALT condition is active.

**Arguments:** None.

**Environment required:**
- `SCRAM_WORKSPACE` — absolute path to the workspace directory

**Behavior:**
- If `$SCRAM_WORKSPACE/HALT` exists: print `HALT: <contents of HALT file>` to stderr; exit 1
- If `$SCRAM_WORKSPACE/HALT` does not exist: exit 0 silently

**Exit codes:**
- `0` — no HALT; dispatch may proceed
- `1` — HALT active; dispatch is blocked

**Notes:** Registered as `PreToolUse` on `Agent`. A non-zero exit from a `PreToolUse` hook blocks the tool call. If `SCRAM_WORKSPACE` is unset, the script exits 0 (no-op) rather than blocking all agent dispatch.

---

#### `scram-init.sh`

**Purpose:** Create the workspace directory structure and write the initial session manifest skeleton.

**Arguments:**
- `<workspace-path>` (positional, required) — absolute path where the workspace should be created

**Environment required:**
- None (workspace path is passed as argument)

**Behavior:**
1. Create directories: `<workspace-path>/`, `<workspace-path>/briefs/`, `<workspace-path>/retro/`, `<workspace-path>/events/`
2. Write `<workspace-path>/session.md` with the session manifest skeleton (frontmatter fields set to empty strings or defaults; timestamps set to current UTC time)
3. Print the created workspace path to stdout: `SCRAM_WORKSPACE: <absolute-path>`
4. Exit 0

**Exit codes:**
- `0` — success
- `1` — directory creation failed or session.md write failed (prints error to stderr)

**Stdout format:**

```
SCRAM_WORKSPACE: /Users/<user>/.scram/<project>--<feature>--<timestamp>
```

**Notes:** Used by the orchestrator at G0 instead of the prose `mkdir -p` instructions.

---

#### `session-checkpoint.sh`

**Purpose:** Write a last-seen timestamp to an active SCRAM session manifest. Used by the Stop hook for cheap insurance against context exhaustion leaving stale state.

**Arguments:** None.

**Environment required:**
- `SCRAM_WORKSPACE` — absolute path to the workspace directory (set by the orchestrator at G0)

**Behavior:**
1. If `SCRAM_WORKSPACE` is unset or empty: exit 0 silently (no active session)
2. If `$SCRAM_WORKSPACE/session.md` does not exist: exit 0 silently (no active session)
3. If `session.md` exists: use `sed` to replace the `updated:` line in the YAML frontmatter with the current ISO-8601 timestamp. If no `updated:` line exists, append it before the closing `---`.
4. Exit 0

**Exit codes:**
- `0` — always (no-op if no session; success if updated)

**Notes:** Registered as a Stop hook. Fires on every conversation stop, including context exhaustion. Does not create new files — only updates existing frontmatter. The `sed` approach avoids YAML parsing complexity.

---

#### `scram-discover.sh`

**Purpose:** Find existing SCRAM sessions for the current project.

**Arguments:** None.

**Environment required:**
- `PWD` — current working directory (used to derive project name via `basename`)

**Behavior:**
1. Run `ls -d ~/.scram/$(basename "$PWD")--* 2>/dev/null`
2. For each directory found, extract `current_gate` and `updated` from `session.md` frontmatter using `grep` (e.g., `grep '^current_gate:' session.md | cut -d' ' -f2`). No YAML parser required — flat frontmatter fields are reliably extractable with grep/cut.
3. Print a structured list to stdout

**Exit codes:**
- `0` — always (even if no sessions found; empty output means no sessions)

**Stdout format:**

```
SCRAM_SESSIONS:
  1. /Users/<user>/.scram/<project>--<feature>--<timestamp>/ (gate: <current_gate>, last updated: <updated>)
  2. /Users/<user>/.scram/<project>--<feature2>--<timestamp2>/ (gate: complete, last updated: <updated>)
```

If no sessions exist:

```
SCRAM_SESSIONS: none
```

**Notes:** Replaces the `ls -d ~/.scram/$(basename "$PWD")--*` prose instruction in SKILL.md G0. The orchestrator passes this output directly to the user session selection flow.

---

#### `pre-merge-check.sh`

**Purpose:** Run three git reads to confirm a story branch is in a mergeable state.

**Arguments:**
- `<branch-name>` (positional, required) — the story branch name to check (e.g., `scram/auth-system/story-auth-middleware`)
- `<commit-sha>` (positional, required) — the commit SHA reported by the dev agent
- `<integration-branch>` (positional, required) — the integration branch to diff against (e.g., `scram/auth-system`)

**Environment required:**
- `PWD` must be within the project git repo

**Behavior:**
1. Check branch exists: `git branch --list <branch-name>` — fail if empty
2. Check SHA is on branch: `git log --oneline <branch-name> | grep <commit-sha>` — fail if not found
3. Check diff is non-empty: `git diff <integration-branch>...<branch-name>` — fail if empty

**Exit codes:**
- `0` — all three checks pass; merge may proceed
- `1` — one or more checks failed (prints structured failure to stdout)

**Stdout format (pass):**

```
PRE_MERGE: pass
  branch: <branch-name>
  sha: <commit-sha>
  diff: non-empty
```

**Stdout format (fail):**

```
PRE_MERGE: fail
  check: <branch_exists | sha_on_branch | diff_non_empty>
  reason: <human-readable failure description>
```

**Notes:** Replaces the prose pre-review git health check block (the block anchored by "Pre-review git health check — before anything else, confirm:") in the SKILL.md Merge Stream section.

---

#### `brief-lint.sh`

**Purpose:** Detect line-number references in a context brief file.

**Arguments:**
- `<brief-file-path>` (positional, required) — absolute path to the brief file to lint

**Environment required:**
- None

**Behavior:**
1. Grep the file for patterns: `line \d+` (case-insensitive), `:\d+$` (colon-number at end of line), `L\d+` (GitHub-style line anchor)
2. If any match found: print each match to stdout with line context; exit 1
3. If no matches: exit 0

**Exit codes:**
- `0` — no line-number references found; brief is clean
- `1` — line-number references detected; brief must be revised

**Stdout format (fail):**

```
BRIEF_LINT: fail <brief-file-path>
  Line-number references detected (use content-anchored locators instead):
  > <matching line 1>
  > <matching line 2>
```

**Stdout format (pass):**

```
BRIEF_LINT: pass <brief-file-path>
```

**Notes:** Registered as `PreToolUse` on `Write` (fires on ALL Write calls). The script receives the file path from the hook's input JSON (stdin). If the path is not under `$SCRAM_WORKSPACE/briefs/`, the script exits 0 immediately (no-op). If `SCRAM_WORKSPACE` is unset, the script exits 0 (no-op). This self-filtering approach replaces the need for path-based hook matching, which the plugin system does not support. The script reads the Write tool's input from stdin to extract the `file_path` field.

### 5.4 Environment Variables

| Variable | Source | Required By |
|----------|--------|-------------|
| `SCRAM_WORKSPACE` | Set by orchestrator at G0 (absolute path); written to session.md | `halt-check.sh`, `session-checkpoint.sh`, `brief-lint.sh` |
| `CLAUDE_PLUGIN_ROOT` | Set by Claude Code plugin system at plugin load | All scripts (via `${CLAUDE_PLUGIN_ROOT}/scripts/`) |
| `PWD` | Shell | `scram-discover.sh`, `pre-merge-check.sh` |

`CLAUDE_PLUGIN_ROOT` availability follows the tmux plugin pattern. If it is unavailable at hook execution time, scripts fall back to their absolute install paths (which is implementation risk, not a spec decision — flag during implementation).

### 5.5 Prose Instructions Replaced by Script References

The following SKILL.md prose blocks are replaced by script invocation references:

| Prose block (content anchor) | Replaced by |
|------------------------------|-------------|
| "check for existing SCRAM workspaces" (`ls -d ~/.scram/...`) in G0 Check for Existing Sessions | "Run `scram-discover.sh` and present output to user" |
| `mkdir -p "$SCRAM_WORKSPACE/briefs"` block in G0 New Session Setup | "Run `scram-init.sh <workspace-path>` — prints the created path to stdout; set `SCRAM_WORKSPACE` from that output" |
| "Pre-review git health check — before anything else, confirm:" numbered list in Merge Stream | "Run `pre-merge-check.sh <branch> <sha> <integration-branch>`. If result is `fail`, route back as git state issue and redispatch." |
| "Every dispatch path checks for this file before firing an Agent call" prose about HALT in Emergency Halt section | "The `halt-check.sh` PreToolUse hook enforces this automatically. The orchestrator need not check manually." |
| "Reject briefs that contain line-number locators" in G3 | "The `brief-lint.sh` hook (or orchestrator-invoked script) enforces this before brief files are written." |

---

## 6. Cross-Cutting Changes

### 6.1 Version Bump

`scram/.claude-plugin/plugin.json` version changes from `"5.0.0"` to `"6.0.0"`. This is a breaking change because the agent identifier `scram:developer` is removed and cannot be dispatched. Callers must update to `scram:developer-reviewer`, `scram:developer-breakdown`, or `scram:developer-impl`.

### 6.2 Plugin Validation

After all changes, `claude plugin validate ./scram` must pass. Validation confirms:
- All agent files referenced in skills exist
- All agent identifiers referenced in SKILL.md dispatch instructions match agent file names
- `plugin.json` is well-formed
- Skills and agents have required frontmatter fields

### 6.3 Workspace Structure (Final)

The canonical workspace structure after v6.0.0:

```
~/.scram/
└── <project-dir>--<feature-name>--<invocation-id>/
    ├── session.md                          # session manifest
    ├── backlog.md                          # story status
    ├── briefs/
    │   └── <story-slug>.md                # context briefs (one per story)
    ├── retro/
    │   ├── in-flight.md                   # NEW: stream friction observations
    │   ├── tickets/
    │   │   ├── metron.md
    │   │   └── highfather.md
    │   └── discussions/
    │       └── <topic-slug>.md
    └── events/                            # NEW: reserved for future use (created by scram-init.sh)
```

### 6.4 Agent Naming Convention (Updated)

The agent naming table in SKILL.md is updated:

**Devs (impl):** Orion, Barda, Scott, Lightray, Bekka, Forager, Bug, Serifan, Vykin, Fastbak
**Devs (reviewer):** Use the same name pool — a reviewer is a developer in a different mode
**Devs (breakdown):** Use the same name pool
**Merge Maintainer:** Metron
**Code Maintainer:** Highfather
**Doc Specialists:** Beautiful Dreamer, Mark Moonrider, Jezebelle
**Designers:** Esak
**Dev Tooling Maintainers:** Himon
**Retro Facilitator:** Dispatched as `scram:scram-retro` — not a named team member; one-shot at G5

---

## 7. Contradictions and Notes

### 7.1 Hooks File Location

The ticket (003) specifies `scram/hooks.json` at the root of the scram plugin. The ADR-005 and the tmux convention reference a `hooks/` subdirectory. This spec adopts `scram/hooks/hooks.json` (subdirectory). Implementation should verify against `claude plugin validate` output and correct if needed.

### 7.2 `worktree-init.sh`, `backlog-update.sh`, `session-update.sh` Deferred

The scramstorm ticket (003) lists seven scripts including `worktree-init.sh`, `backlog-update.sh`, and `session-update.sh`. ADR-005 explicitly defers these to a later pass. The v6.0.0 first pass implements six scripts: `halt-check.sh`, `scram-init.sh`, `scram-discover.sh`, `pre-merge-check.sh`, `brief-lint.sh`, and `session-checkpoint.sh`. The three deferred scripts are not in scope for v6.0.0.

### 7.3 Auto-Application of Retro Changes

The ticket (006) describes auto-application of retro changes (exact-match text substitution at G5). ADR-002 defers auto-application to a follow-on ADR. The `### Current Text` / `### Proposed Text` format is adopted now to enable future automation, but the retro facilitator skill does NOT implement auto-apply in v6.0.0. Consensus changes are presented to the user for manual application.

### 7.4 Brief Lint Self-Filtering

The Claude Code plugin hook system does not support path-based filtering. `brief-lint.sh` fires on ALL Write calls via the `PreToolUse` matcher on `"Write"`. The script self-filters by checking whether the target file path is under `$SCRAM_WORKSPACE/briefs/` and exiting 0 (no-op) if not. This means the script runs on every Write call during a SCRAM session — the overhead is negligible (a single path check), but implementors should ensure the stdin parsing is fast and does not block unrelated Write operations.

### 7.5 Session Checkpoint Environment

The `session-checkpoint.sh` Stop hook requires `SCRAM_WORKSPACE` to be set as a shell environment variable. The orchestrator must `export SCRAM_WORKSPACE=<path>` at G0 so it persists in the shell environment for hook scripts. If the variable is unset (e.g., non-SCRAM conversations), the script exits 0 silently.
