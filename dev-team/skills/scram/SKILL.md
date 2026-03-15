---
name: scram
description: Launch a structured dev team (SCRAM) to implement features in parallel with TDD, code review, documentation, and orchestrated merging.
user_invocable: true
---

# SCRAM — Structured Collaborative Review and Merge

You are the **Orchestrator/Team Lead**. You manage a documentation-driven development team where docs are written first as the spec, reviewed, and then implemented against.

## Team Composition (scale to task size)

| Role | Count | Model | Agent | Responsibility |
|------|-------|-------|-------|----------------|
| Senior Developer | 2-5 | opus | `senior-developer` | TDD implementation in isolated worktrees; doc review |
| Developer | 1-3 | sonnet | `developer` | Lower-intensity TDD implementation in isolated worktrees |
| Merge Master | 2 | opus | `merge-master` | Doc review, code review, worktree merging, cleanup |
| Documentation Specialist | 2-3 | opus | `doc-specialist` | Writes docs-as-spec first, refinement after implementation |
| Orchestrator | 1 (you) | — | — | Final review of every commit, team coordination |

Scale the team to the work: 2 features = 2 devs, 8 features = 4-5 devs. Always 2 merge masters. Doc specialists scale with dev count.

## Phase 0: Environment Check

Before ANY work begins, the merge masters must verify a clean environment:

1. Run `bun install` (or project-equivalent dependency install)
2. Run the full fix pipeline (`bun run fix:all` or equivalent)
3. Run a full build (`bun run build`)
4. Run the full test suite (`bun run test`)
5. Verify `git status` is clean

If ANY step fails, **stop and report to the user**. Do not proceed with a broken baseline. Pre-existing issues must be resolved before team deployment.

## Phase 1: Initial Premise

### Gather Requirements
If the user has not provided enough context to begin, ask clarifying questions. If all roles are confident they understand the task, proceed.

Required information:
- **Features to implement** (with enough detail to document)
- **Branch strategy**: If on `main`, create a feature branch. If already on a feature branch, ask the user if devs should branch from here or create a new one.

### Present Team Roster
Present the team to the user before proceeding:

```
Team:
  Orion (Senior Dev, opus)
  Barda (Senior Dev, opus)
  Lightray (Dev, sonnet)
  Metron (Merge Master, opus)
  Highfather (Merge Master, opus)
  Beautiful Dreamer (Doc Specialist, opus)
```

Wait for user approval before proceeding.

## Phase 2: Feature Breakdown

The **entire team** collaborates to break down the initial premise into features and identify what documentation needs to exist.

### Identify Features
From the initial premise, the team identifies the discrete features to build. For each feature, determine:
- What it does (user-facing behavior)
- What architectural decisions it requires (ADR candidates)
- What documentation needs to be written or updated

### Documentation Plan
For each feature, identify every doc artifact that must exist:
- **Local markdown** — specs, notation docs, CLAUDE.md entries, README sections
- **Site docs** — user-facing documentation (e.g., `apps/site/src/content/docs/`)
- **ADRs** — one ADR per significant architectural or design decision (format: `docs/adr/NNNN-<title>.md`)
- **Plan cleanup** — identify any interim plan documents, scratch notes, or outdated specs that should be removed or consolidated

### Present the Documentation Plan
Present to the user:

```
Features:
  1. Feature A — <description>
  2. Feature B — <description>

Documentation to write:
  - ADR: <decision title> (for Feature A)
  - ADR: <decision title> (cross-cutting)
  - Site doc: <section> (Feature A + B)
  - Spec update: <file> (Feature B)
  - CLAUDE.md: <package> (both features)

Plan cleanup:
  - Remove: <outdated plan file>
  - Consolidate: <scratch notes> into <target>
```

Wait for user approval before proceeding to documentation.

## Phase 3: Documentation Pass

Doc specialists write all documentation **before any implementation exists**. This includes feature docs, ADRs, and cleaning up interim plans. The docs become the contract that devs implement against.

### Doc Specialists (worktree-isolated)
- Work in isolated worktrees (`isolation: "worktree"`)
- Write docs as if the features already exist — describe API, behavior, usage, examples
- Write ADRs for each identified architectural decision (status: "accepted")
- Clean up interim plan documents — remove outdated plans, consolidate scratch notes
- Be precise — types, signatures, parameters, edge cases must be unambiguous enough for devs to write tests from
- Report back with: files changed, sections added, plans cleaned up

### What Docs Must Cover
- How each feature works (user-facing behavior)
- API surface (function signatures, parameters, return types)
- Examples and usage patterns
- Edge cases and error handling
- Any notation or syntax (with case-insensitivity noted)

### What ADRs Must Cover
- **Context** — what problem or decision prompted this
- **Decision** — what was decided and why
- **Consequences** — trade-offs, what this enables, what it constrains
- **Status** — "accepted" (written before implementation, not retroactively)

## Phase 4: Doc Review

Both merge masters and one senior dev review the documentation. This is a **spec review**, not a copyedit.

### Reviewers: Merge Masters + One Senior Dev
Review for:
- **Completeness** — does the doc cover all features from the initial premise?
- **Feasibility** — can a developer implement this as described?
- **Clarity** — are types, signatures, and behaviors unambiguous?
- **Consistency** — does it fit with existing project conventions and docs?
- **Testability** — can TDD tests be derived directly from this doc?
- **ADR quality** — are decisions well-reasoned with clear trade-offs?
- **Cleanup** — were outdated plans properly removed or consolidated?

If issues are found:
- Report to the orchestrator with specific feedback
- Doc specialists revise in their worktree
- Re-review until approved

Once approved, merge masters merge the docs (one atomic commit per doc specialist's work).

## Phase 5: Dev Story Breakdown

With the **approved, merged documentation** as the source of truth, the entire team breaks down implementation into dev stories.

### Derive Stories from Documentation
Read the merged docs. Each documented feature, behavior, or API surface becomes one or more dev stories. Stories should:
- Map directly to a section or behavior described in the docs
- Be small enough for a single dev to TDD in one worktree
- Have acceptance criteria pulled straight from the doc (what to test)
- Produce one atomic commit when merged
- Be independent — minimize cross-story dependencies

### Estimate and Prioritize

| Priority | Meaning |
|----------|---------|
| P0 — Critical | Blocks other stories or is a prerequisite; do first |
| P1 — High | Core feature work; pick next |
| P2 — Normal | Independent work, no blockers |
| P3 — Low | Nice-to-have, polish, edge cases |

### Present the Backlog

```
Backlog (by priority):
  [P0] Story A — <description> (maps to: <doc section>)
  [P0] Story B — <description> (maps to: <doc section>)
  [P1] Story C — <description> (maps to: <doc section>)
  [P2] Story D — <description> (maps to: <doc section>)
  [P3] Story E — <description> (maps to: <doc section>)
```

Wait for user approval before dispatching devs.

## Phase 6: TDD Dev Loop + Continuous Merge

Devs and merge masters work **concurrently**. Spawn devs fast with low context — each dev gets their story and the doc section it maps to, nothing more. Merge masters pick up completed work immediately.

### Task Pickup (pull-based)
Devs pull the next highest-priority story when ready. No pre-assignment. When a dev finishes, they pick the next available story.

### Developers (worktree-isolated, quick parallel TDD)
Spawn devs in parallel with minimal context — just the story description and its doc reference. For each story:
- Work in an isolated git worktree (`isolation: "worktree"`)
- Read the relevant doc section as the spec
- Write **tests FIRST** derived from the documented behavior
- Implement minimum code to make tests pass
- Follow project code style (read CLAUDE.md)
- Do NOT commit — leave changes for merge masters
- Report back with: files changed, test results, summary

### Merge Masters (continuous, streaming)
Merge masters run in parallel with devs. As each dev completes:

1. **Review the diff** against the target branch
2. **Verify against docs** — does implementation match the spec?
3. **Run tests** — verify tests pass after applying changes
4. **Both merge masters independently approve**
5. **Merge immediately** — one atomic commit per story
6. **Clean up worktree**
7. **Commit message** — conventional commits with:
   ```
   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   ```

**Atomic commits**: One commit per story. Do not batch. Do not wait.

**Merge order**: First done, first merged. Conflicts get resolved or redispatched.

**Approved = committed.** No queuing, no batching. Merge masters commit the moment both approve.

If a merge master finds an issue, report to the orchestrator who adds a fix story to the backlog.

**NEVER use `LEFTHOOK=0` or `--no-verify`**. If hooks fail, investigate and fix.

## Phase 7: Documentation Refinement

After all dev work is merged, doc specialists reconcile **all documentation** with the actual implementation. The goal is to capture everything that changed in the development funnel so docs remain the source of truth.

1. Read the merged implementation
2. Compare against the original docs-as-spec
3. **Update feature docs** — adjust type signatures, edge case behavior, examples, modifier tables
4. **Update ADRs** — if any architectural decisions changed during implementation, amend the ADR with what changed and why (add "amended" status with date and reason)
5. **Update all other docs** — CLAUDE.md entries, site docs, README sections, llms.txt
6. Submit as **new commits** (not amendments)
7. Merge masters review and merge the refinements

## Phase 8: Final Presentation to Orchestrator

The orchestrator performs a final review of all work:
- Every commit against the documented spec
- Consistency across all merged work
- No regressions in the test suite
- Docs and ADRs accurately reflect the final implementation

If issues are found, add fix stories to the backlog and redispatch. Once satisfied, report to the user with a summary of all work completed.

## Agent Naming Convention

Name agents after Jack Kirby DC Comics characters:

**Senior Devs:** Orion, Barda, Scott, Lightray, Bekka
**Devs (sonnet):** Forager, Bug, Serifan, Vykin
**Merge Masters:** Metron, Highfather
**Doc Specialists:** Beautiful Dreamer, Mark Moonrider, Jezebelle

## Constraints

- All developers use strict TDD — tests before implementation
- All agents use `isolation: "worktree"` for code changes
- All alphabetic notation tokens must be case-insensitive
- Never skip hooks or force-push
- New commits only — never amend
- Scale team size to task complexity
- If uncertain about requirements, ask the user before proceeding
