# tmux

Tmux integration for Claude Code — tab status, blinking notifications, and powerline helpers.

## Install

```
/plugin marketplace add alxjrvs/skills
/plugin install tmux@jrvs-skills
```

## Hooks

Automatically active after install:

| Event | Behavior |
|-------|----------|
| `PermissionRequest` | Blinks the tmux tab to signal attention needed |
| `Notification` | Blinks on elicitation dialogs |
| `UserPromptSubmit` | Clears blink state |
| `PostToolUse` / `PostToolUseFailure` | Clears blink state |
| `Stop` | Resets tab status on session end |

## Skills

### `tmux-claude-hooks`

Reference for what each hook event sets and clears — useful when building custom tmux status bars.

### `powerline-glyphs`

Recipe for powerline glyph color assignments — which side FG dominates, how to flow segments, and exact color patterns for transitions.

### `powerline-tips`

Practical patterns and gotchas for building tmux powerline format strings — value+label pairing, color blending, escaping, and dynamic per-window options.
