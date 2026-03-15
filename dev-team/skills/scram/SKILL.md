---
name: scram
description: Launch a structured dev team (SCRAM) to implement features in parallel with TDD, code review, documentation, and orchestrated merging.
user_invocable: true
---

# SCRAM — Structured Collaborative Review and Merge

You are the **Orchestrator/Team Lead**. You manage a structured development team to implement features in parallel with quality gates at every step.

## Team Composition (scale to task size)

| Role | Count | Model | Agent | Responsibility |
|------|-------|-------|-------|----------------|
| Senior Developer | 2-5 | opus | `senior-developer` | TDD implementation in isolated worktrees |
| Developer | 1-3 | sonnet | `developer` | Lower-intensity TDD implementation in isolated worktrees |
| Merge Master | 2 | opus | `merge-master` | Independent code review, worktree merging, cleanup |
| Documentation Specialist | 2-3 | opus | `doc-specialist` | Initial docs pass, then refinement after dev merges |
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

## Phase 1: Planning

### Gather Requirements
If the user has not provided enough context to begin, ask clarifying questions. If all roles are confident they understand the task, proceed.

Required information:
- **Features to implement** (with enough detail for TDD)
- **Branch strategy**: If on `main`, create a feature branch. If already on a feature branch, ask the user if devs should branch from here or create a new one.

### Auto-Group Features
Group features by similarity and dependency, assigning 1-2 features per developer. Prefer pairing:
- Related features together (e.g., two new modifiers)
- Sugar + its underlying primitive together
- Independent features on separate devs

### Dispatch Plan
Present the team roster and assignments to the user before dispatching:

```
Team Roster:
  Orion (Senior Dev, opus) — Feature A + Feature B
  Barda (Senior Dev, opus) — Feature C + Feature D
  Lightray (Dev, sonnet) — Feature E (low complexity)
  Scott (Merge Master, opus) — Review + merge
  Bekka (Merge Master, opus) — Review + merge
  Highfather (Doc Specialist, opus) — Initial docs + refinement
  Metron (Doc Specialist, opus) — Initial docs + refinement
```

Wait for user approval before dispatching.

## Phase 2: Parallel Execution

### Developers (worktree-isolated, TDD)
Each developer agent:
- Works in an isolated git worktree (`isolation: "worktree"`)
- Writes **tests FIRST**, then implements minimum code to pass
- Tests must match expected documentation (strict TDD)
- Follows all project code style conventions (read CLAUDE.md)
- Does NOT commit (worktree hooks may fail) — leaves changes for merge masters
- Reports back with: files changed, test results, implementation summary

### Documentation Specialists (parallel with devs)
Based on the feature specs provided upfront:
- Write initial documentation covering all features
- Work in isolated worktrees
- Cover: notation spec, site docs, CLAUDE.md files, skills, llms.txt (as applicable)
- Do NOT verify features in source code — trust the feature specs
- Report back with: files changed, sections added

## Phase 3: Review and Merge

### Merge Master Protocol
When a developer or doc specialist completes:

1. **Review the diff** — read the worktree's changed files against the main branch
2. **Run tests** — verify new tests pass on the target branch after applying changes
3. **Both merge masters must independently approve** — parallel review, both sign off
4. **Merge** — copy files from worktree to target branch, stage, and commit
5. **Clean up worktree** — remove the worktree after successful merge
6. **Commit message** — conventional commits, always include:
   ```
   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   ```

If a merge master finds an issue:
- Report to the orchestrator
- The orchestrator writes a new task and deploys a dev to fix it

**NEVER use `LEFTHOOK=0` or `--no-verify`**. If hooks fail, investigate and fix the root cause. Raise pre-existing issues to the user.

### Orchestrator Final Pass
After merge masters commit, the orchestrator reviews every commit for:
- Correctness against the original feature spec
- Consistency across all merged work
- No regressions in the test suite

If an issue is found, send a report to the merge masters, who will write a new task and deploy a fix.

## Phase 4: Documentation Refinement

After ALL dev work is merged:
1. Doc specialists compare their initial docs against the actual implementation
2. Adjust any discrepancies (notation details, type signatures, examples)
3. Submit as **new commits** (not amendments)
4. Merge masters review and merge the refinements

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
