# scram-retro-respond Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a user-invocable project-level skill that consumes open retro issues, investigates via scramstorm, dispatches scram teams, bumps the SCRAM plugin version, comments on issues, commits, and pushes.

**Architecture:** Single SKILL.md file in `.claude/skills/scram-retro-respond/` that acts as a thin orchestrator. It delegates to existing skills (`/scramstorm`, `/scram-solo`, `/scram`) and uses `gh` CLI for GitHub operations. The only novel logic is the triage phase that maps scramstorm output to retro issue items.

**Tech Stack:** Claude Code skill (Markdown with YAML frontmatter), `gh` CLI, existing SCRAM skills

**Spec:** `docs/superpowers/specs/2026-03-24-scram-retro-respond-design.md`

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `.claude/skills/scram-retro-respond/SKILL.md` | The entire skill — frontmatter, all 6 phases, triage map schema |

This is a single-file deliverable. No scripts, agents, hooks, or supporting files.

---

### Task 1: Create the skill directory and frontmatter

**Files:**
- Create: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p /Users/jarvis/Code/JrvsSkills/.claude/skills/scram-retro-respond
```

- [ ] **Step 2: Write frontmatter and skill header**

Write the YAML frontmatter and introductory section. The frontmatter follows the pattern from existing skills like `scram-solo/SKILL.md` and `scramstorm/SKILL.md`.

```markdown
---
name: scram-retro-respond
description: Ingests open retro issues, investigates via scramstorm, dispatches scram team to address changes, bumps version, comments on issues, commits and pushes.
user_invocable: true
---

# SCRAM Retro Respond

You are the **Orchestrator** for retro issue resolution. This skill consumes open retrospective issues filed by `scram-retro` (the G5 gate of a SCRAM sprint), investigates them via scramstorm, dispatches a scram team to implement fixes, and closes the loop with version bumps and issue comments.

This is the **consumer** end of the retro lifecycle. `scram-retro` creates issues; you resolve them.

---

## Pipeline Overview

```
Phase 1: Observe   →  Query open retro issues from GitHub
Phase 2: Scramstorm →  Investigate retro items with the SCRAM team
Phase 3: Triage     →  Map scramstorm output to retro items, classify, determine semver
Phase 4: Execute    →  Dispatch scram-solo or scram-sprint to implement fixes
Phase 5: Finalize   →  Bump version, commit, push
Phase 6: Report     →  Comment on issues, close if fully addressed
```
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat: scaffold scram-retro-respond skill with frontmatter and overview"
```

---

### Task 2: Write Phase 1 (Observe)

**Files:**
- Modify: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Add Phase 1 section**

Append after the Pipeline Overview section:

```markdown
## Phase 1: Observe

Query GitHub for open retrospective issues:

```bash
gh issue list --repo alxjrvs/skills --label retrospective --state open --json number,title,body
```

**If no open retro issues exist:** inform the user and exit. There is nothing to respond to.

**If issues are found:** parse each issue body to extract individual retro items. Retro issues created by `scram-retro` use this structure:

- `### Agreed Changes` — numbered list of consensus items
- `### Disagreements` — numbered list of contested items
- `### Other Tickets` — numbered list of additional observations

Extract each numbered item as a discrete retro item with:
- `issue_number` — the GitHub issue number it came from
- `item_id` — its position within the issue (1, 2, 3...)
- `summary` — the item title
- `category` — process, tooling, communication, prompt_quality, missing_capability
- `section` — which section it appeared in (agreed, disagreed, other)

Present the extracted items to the user:

```
Found <N> open retro issue(s) with <M> total items:

Issue #38: retro(v7.1.0): 4 consensus changes from SCRAM run
  1. Git ref namespace conflict (tooling, agreed)
  2. Worktree isolation is advisory (process, agreed)
  3. P0 quality gate is narrative (process, agreed)
  4. No runtime verification for non-test-suite projects (prompt_quality, agreed)

Proceeding to scramstorm investigation.
```
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat(scram-retro-respond): add Phase 1 — observe open retro issues"
```

---

### Task 3: Write Phase 2 (Scramstorm)

**Files:**
- Modify: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Add Phase 2 section**

Append after Phase 1:

```markdown
## Phase 2: Scramstorm

Invoke `/scramstorm` to investigate the retro items. Frame the problem statement using the extracted items from Phase 1:

**Problem frame to provide scramstorm:**

```
Problem: The SCRAM plugin has <M> unaddressed retro items across <N> open issues.
These were identified by maintainers during retrospectives and need investigation
to determine the best fixes.

Items:
1. <summary> (from issue #<number>) — <category>
2. <summary> (from issue #<number>) — <category>
...

Desired outcome: For each item, determine whether it should be addressed (with a
specific fix proposal) or deferred (with rationale). Produce actionable stories
for the items worth fixing.
```

The scramstorm runs its full interactive pipeline — the user participates in confirming the team roster, problem frame, voting, and discussion. This is by design: retro response benefits from human judgment.

After the scramstorm completes, its `options.md` and `handoff.md` are available in the brainstorm workspace (`~/.scram/brainstorm--*`). Proceed to Phase 3.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat(scram-retro-respond): add Phase 2 — scramstorm investigation"
```

---

### Task 4: Write Phase 3 (Triage)

**Files:**
- Modify: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Add Phase 3 section**

Append after Phase 2:

```markdown
## Phase 3: Triage

Read the scramstorm output (`options.md` and `handoff.md` from the brainstorm workspace) and build a **triage map** — a structured in-context artifact that drives the remaining phases.

### Triage Map Schema

```yaml
triage:
  semver: minor | patch
  rationale: "<why this semver level>"
  issues:
    - number: <GitHub issue number>
      title: "<issue title>"
      items:
        - id: <item number within issue>
          summary: "<item title>"
          status: addressed | out-of-scope
          scramstorm_option: "<which scramstorm option was selected, if addressed>"
          reason: "<why out-of-scope, if deferred — null otherwise>"
  close_decisions:
    - number: <GitHub issue number>
      action: close | comment-only
      addressed_count: <n>
      total_count: <n>
```

### Classification Rules

For each retro item, check whether the scramstorm produced an actionable fix:
- **addressed** — the scramstorm's winning option includes a specific change for this item
- **out-of-scope** — the scramstorm determined the item is not actionable, requires external tooling, or was deprioritized during voting

### Semver Determination

- **minor** — any addressed item introduces new behavior, new process gates, new enforcement mechanisms, or new agent instructions
- **patch** — all addressed items are refinements, clarifications, or fixes to existing behavior

### Close Decision Logic

For each retro issue:
- If **all items** in the issue are `addressed` → `action: close`
- If **any item** is `out-of-scope` → `action: comment-only`

### User Checkpoint

Present the triage map to the user for approval before proceeding:

```
Triage Summary:
  Semver: <minor|patch> — <rationale>

  Issue #38 (4 items):
    [addressed] 1. Git ref namespace conflict → <scramstorm option>
    [addressed] 2. Worktree isolation is advisory → <scramstorm option>
    [addressed] 3. P0 quality gate is narrative → <scramstorm option>
    [out-of-scope] 4. No runtime verification → <reason>
  Decision: comment-only (3/4 addressed)

Proceed with execution?
```

Use `AskUserQuestion` to confirm. The user may:
- Reclassify items (addressed ↔ out-of-scope)
- Override the semver decision
- Approve and proceed
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat(scram-retro-respond): add Phase 3 — triage mapping with user checkpoint"
```

---

### Task 5: Write Phase 4 (Execute)

**Files:**
- Modify: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Add Phase 4 section**

Append after Phase 3:

```markdown
## Phase 4: Execute

Count the addressed items from the triage map and route:

### Solo Path (1-2 addressed items)

Invoke `/scram-solo` for each addressed item **sequentially**. For each item:

1. Frame the story description from the scramstorm's winning option for that item
2. Provide the target files identified by the scramstorm
3. Let the solo flow run its normal interactive pipeline (Assess → Brief → Implement → Review → Merge)

Wait for each solo run to complete before starting the next. This avoids branch conflicts.

### Sprint Path (3+ addressed items)

Invoke `/scram` (the router). The scramstorm's `handoff.md` is already in the brainstorm workspace (`~/.scram/brainstorm--*`), so the router will detect it at Step 2 (Scramstorm Handoff Check) and offer to import.

**Important:** Before invoking `/scram`, filter the scramstorm handoff to include only addressed items. Remove out-of-scope items from the handoff so the sprint backlog contains only actionable work.

The sprint runs its full interactive pipeline — the user participates as usual.

### Failure Policy

- **Solo failure** (dev agent failure, review rejection): skip the failed item, mark it as `failed` in the triage map, continue with remaining items. Failed items are reported in Phase 6.
- **Sprint failure**: halt the pipeline and surface the failure to the user. Sprint failures are too complex to skip past — the user must decide how to proceed.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat(scram-retro-respond): add Phase 4 — execute via solo or sprint"
```

---

### Task 6: Write Phase 5 (Finalize)

**Files:**
- Modify: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Add Phase 5 section**

Append after Phase 4:

```markdown
## Phase 5: Finalize

After all scram runs complete successfully:

### 1. Determine New Version

Read the current version from `scram/.claude-plugin/plugin.json`. Apply the semver bump from the triage map:

- **patch**: `X.Y.Z` → `X.Y.(Z+1)`
- **minor**: `X.Y.Z` → `X.(Y+1).0`

### 2. Bump Version

Edit `scram/.claude-plugin/plugin.json` — update only the `version` field.

### 3. Commit

```bash
git add scram/.claude-plugin/plugin.json
git commit -m "chore(scram): bump version to <new_version>"
```

### 4. Push

```bash
git push
```

The scram runs have already committed their implementation changes directly to main (solo path) or via integration branch merge at G4 (sprint path). The version bump is the final commit on top.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat(scram-retro-respond): add Phase 5 — version bump, commit, push"
```

---

### Task 7: Write Phase 6 (Report)

**Files:**
- Modify: `.claude/skills/scram-retro-respond/SKILL.md`

- [ ] **Step 1: Add Phase 6 section**

Append after Phase 5:

```markdown
## Phase 6: Report

Iterate over each retro issue from the triage map and take action based on the close decision.

### All items addressed → comment and close

```bash
gh issue comment <number> --repo alxjrvs/skills --body "All items addressed in v<version>."
gh issue close <number> --repo alxjrvs/skills
```

### Partial — some out-of-scope or failed → comment and leave open

Build a comment body listing what was addressed and what was deferred:

```bash
gh issue comment <number> --repo alxjrvs/skills --body "v<version> addressed <N>/<total> items:

Addressed:
- Item 1: <summary>
- Item 2: <summary>

Deferred:
- Item 3: <summary> — <reason>

Failed:
- Item 4: <summary> — scram-solo run failed

Leaving open for remaining items."
```

### Lifecycle Note

On subsequent `/scram-retro-respond` runs, open issues are picked up again. The new scramstorm will re-evaluate deferred and failed items. Issues may accumulate multiple version comments across runs — this is expected and provides an audit trail.

### Completion

After all issues are commented on, present a summary to the user:

```
Retro Response Complete:
  Version: <old_version> → <new_version> (<semver level>)
  Issues processed: <count>
  Issues closed: <count>
  Issues remaining open: <count>
  Items addressed: <count>
  Items deferred: <count>
  Items failed: <count>
```
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "feat(scram-retro-respond): add Phase 6 — report on issues and close"
```

---

### Task 8: Validate the skill

**Files:**
- Read: `.claude/skills/scram-retro-respond/SKILL.md` (verify complete)

- [ ] **Step 1: Read the full SKILL.md and verify completeness**

Read the entire file and check:
- Frontmatter has `name`, `description`, `user_invocable: true`
- All 6 phases are present and in order
- Phase 3 includes the triage map schema and user checkpoint
- Phase 4 includes both solo and sprint paths with failure policy
- Phase 6 includes both close and comment-only paths
- No references to files or paths that don't exist

- [ ] **Step 2: Verify the skill is discoverable**

```bash
ls -la /Users/jarvis/Code/JrvsSkills/.claude/skills/scram-retro-respond/SKILL.md
```

Expected: file exists and is non-empty.

- [ ] **Step 3: Final commit if any fixes were needed**

If any corrections were made during validation, commit them:

```bash
git add .claude/skills/scram-retro-respond/SKILL.md
git commit -m "fix(scram-retro-respond): address validation findings"
```

---

### Task 9: Create scram-solo run for issue #38

After the skill is written and committed, use it immediately:

- [ ] **Step 1: Invoke `/scram-retro-respond`**

Run the skill against the currently open retro issue #38. This serves as both the first real use of the skill and addresses the user's request to handle the outstanding retro feedback.

This step is interactive — follow the skill's pipeline and participate in each phase.
