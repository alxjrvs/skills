# SCRAM

Structured Collaborative Review and Merge — a stream-based parallel development orchestrator for Claude Code.

## Install

```
/plugin marketplace add alxjrvs/skills
/plugin install scram@jrvs-skills
```

## Skills

### `/scram`

Launch a structured dev team to implement features in parallel. Uses sequential gates (ADRs, docs-as-spec, story breakdown) followed by concurrent streams (dev, merge, doc refinement) with strict TDD discipline.

### `/scramstorm`

Launch a team brainstorm to collaboratively research a problem. Same agents, no code — produces structured options with trade-offs through anonymous positions and attributed debate.

## Agents

| Agent | Role | Default Model |
|-------|------|---------------|
| `scram:developer` | Doc review, story breakdown, context briefs, TDD implementation | sonnet |
| `scram:merge-maintainer` | Line-level code review, story strictness, TDD discipline | sonnet |
| `scram:code-maintainer` | Structural harmony, DRYness, codebase-wide patterns | sonnet |
| `scram:doc-specialist` | Docs-as-spec, incremental refinement | sonnet |
| `scram:designer` | Design ADRs, UI/UX merge approver (optional) | sonnet |
| `scram:dev-tooling-maintainer` | CI/CD, build systems, agentic integrations, DX (optional) | sonnet |
