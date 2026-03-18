---
name: scram-escalation
description: Escalation handling reference for SCRAM — failure taxonomy, escalation path, and escalation brief format.
user_invocable: false
---

# SCRAM Escalation Handling

This sub-skill is a reference document for SCRAM escalation handling. It is read by the orchestrator and maintainers when failure taxonomy, escalation path, or escalation brief format detail is needed. It is not invoked as a standalone procedure.

## Failure Taxonomy

Agents report failures with a structured reason. Maintainers use the reason to decide next steps:

| Failure Reason | Action |
|---------------|--------|
| `context_exhaustion` | Redispatch with same model — agent ran out of context, not capability |
| `test_failure` | Review test output, redispatch at same or next tier |
| `build_error` | Check integration branch health before redispatching |
| `missing_dependency` | Verify dependency story is merged, update context brief, redispatch |
| `unclear_spec` | Flag to user for clarification, do not redispatch until resolved |
| `pre_flight_failure` | Investigate integration branch health before redispatching |

## Escalation Path

Default escalation path for capability failures: sonnet → opus. **If the same story fails review twice for the same root cause**, the orchestrator must write an escalation entry in `session.md`, diagnose the pattern, and adjust agent instructions before retrying. Do not blindly redispatch. If the same story fails twice at the same tier, maintainers escalate to user.

## Checkpoint Type Taxonomy

| Type | When to Use |
|------|------------|
| `human-verify` | Read and confirm, no action required from user |
| `decision` | User must choose between options |
| `human-action` | User must perform an action before the run can continue |

## Required Escalation Brief Format

When escalating to the user, use this structure so the user gets an actionable question, not a vague status update:

```markdown
## Escalation: <title>

**Attempted:** <what was tried>
**Failed because:** <root cause>
**Checkpoint type:** human-verify | decision | human-action
  - `human-verify` — read and confirm, no action required from you
  - `decision` — choose between the options below
  - `human-action` — you need to perform an action before the run can continue
**Decision needed:** <closed question with specific options>
**Options:**
1. <option A> — <consequence>
2. <option B> — <consequence>
3. <option C> — <consequence>
```
