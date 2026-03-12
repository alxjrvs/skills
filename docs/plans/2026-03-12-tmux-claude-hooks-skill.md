# tmux-claude-hooks Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the stub `tmux` skill with a developer-facing `tmux-claude-hooks` skill that documents how the tmux plugin's Claude Code hooks work.

**Architecture:** Single SKILL.md file in a new `tmux/skills/tmux-claude-hooks/` folder. The old `tmux/skills/tmux/` stub is removed. No code changes — this is pure documentation.

**Tech Stack:** Markdown, Claude Code plugin system (`claude plugin validate`)

---

### Task 1: Remove the old stub skill

**Files:**
- Delete: `tmux/skills/tmux/SKILL.md`
- Delete: `tmux/skills/tmux/` (directory)

**Step 1: Delete the stub file and directory**

```bash
rm -rf tmux/skills/tmux
```

**Step 2: Verify it's gone**

```bash
ls tmux/skills/
```

Expected output: empty or only other directories (not `tmux/`)

**Step 3: Validate plugin still passes**

```bash
claude plugin validate ./tmux
```

Expected: no errors (the old skill being gone is fine — it was a stub)

**Step 4: Commit**

```bash
git add -A tmux/skills/tmux
git commit -m "chore: remove stub tmux skill"
```

---

### Task 2: Create the tmux-claude-hooks skill

**Files:**
- Create: `tmux/skills/tmux-claude-hooks/SKILL.md`

**Step 1: Create the directory**

```bash
mkdir -p tmux/skills/tmux-claude-hooks
```

**Step 2: Write the skill file**

Create `tmux/skills/tmux-claude-hooks/SKILL.md` with the following content:

```markdown
---
description: Reference for Claude Code tmux hook behaviors — what each hook event sets and clears, for developers building custom tmux status bars or powerline setups.
---

# Claude Code tmux Hooks

This skill documents the hook-based signaling model used by the `tmux` plugin. Claude Code sets tmux **window options** as state flags; your status bar or powerline script reads those flags to reflect Claude's current activity.

---

## Environment Prerequisites

All hook scripts depend on `$TMUX_PANE` being set. This environment variable is automatically present when Claude Code runs inside a tmux pane. Without it, every script is a no-op.

The window index is resolved at runtime:

```bash
WIN=$(tmux display-message -t "${TMUX_PANE}" -p '#{window_index}')
```

This is how all scripts know *which* window to update, even when tmux has multiple windows open.

---

## State: Window Options

The hooks communicate state via two per-window tmux options:

| Option | Type | Meaning |
|---|---|---|
| `@tab_claude_needs_input` | `1` or empty | Claude is waiting for user input (permission request or elicitation dialog) |
| `@tab_claude_blink` | `1` or empty | The tab should visually blink/alert |
| `@tab_claude_active` | file flag | A `/tmp/claude-active-${TMUX_PANE}` file exists while Claude is running |

These are set and cleared via `tmux set-window-option -t :"$WIN" <option> <value>`.

An empty string (`''`) clears the option — tmux treats unset and empty-string options the same way in `#{}` format strings.

---

## Hook Events

### `PermissionRequest`

**Trigger:** Claude is about to perform a tool call that requires user approval.

**What it does:**
1. Touches `/tmp/claude-active-${TMUX_PANE}` (marks session active)
2. Sets `@tab_claude_needs_input` to `1` on the current window
3. Calls your powerline script to start a visual blink on the tab

**Script:** `scripts/permission-request.sh`

```bash
[ -n "${TMUX_PANE:-}" ] \
  && touch "/tmp/claude-active-${TMUX_PANE}" \
  && WIN=$(tmux display-message -t "${TMUX_PANE}" -p '#{window_index}' 2>/dev/null) \
  && [ -n "$WIN" ] \
  && tmux set-window-option -t :"$WIN" @tab_claude_needs_input '1' \
  && ~/dotFiles/tmux-scripts/tmux-powerline.sh tab-blink-start "$WIN" \
  || true
```

---

### `Notification` (matcher: `elicitation_dialog`)

**Trigger:** Claude raises an elicitation dialog — a structured prompt asking for user input mid-task.

**What it does:** Same as `PermissionRequest` — sets `@tab_claude_needs_input` and starts a blink — but does **not** touch the active file.

**Script:** `scripts/notify-blink.sh`

```bash
[ -n "${TMUX_PANE:-}" ] \
  && WIN=$(tmux display-message -t "${TMUX_PANE}" -p '#{window_index}' 2>/dev/null) \
  && [ -n "$WIN" ] \
  && tmux set-window-option -t :"$WIN" @tab_claude_needs_input '1' \
  && ~/dotFiles/tmux-scripts/tmux-powerline.sh tab-blink-start "$WIN" \
  || true
```

---

### `UserPromptSubmit`

**Trigger:** The user submits a message to Claude.

**What it does:** Clears both `@tab_claude_needs_input` and `@tab_claude_blink`, then refreshes the tmux client status bar.

**Script:** `scripts/clear-blink.sh`

```bash
[ -n "${TMUX_PANE:-}" ] \
  && WIN=$(tmux display-message -t "${TMUX_PANE}" -p '#{window_index}' 2>/dev/null) \
  && [ -n "$WIN" ] \
  && tmux set-window-option -t :"$WIN" @tab_claude_needs_input '' \
  && tmux set-window-option -t :"$WIN" @tab_claude_blink '' \
  && tmux refresh-client -S \
  || true
```

---

### `PostToolUse` and `PostToolUseFailure`

**Trigger:** Any tool call completes (success or failure).

**What it does:** Same as `UserPromptSubmit` — clears blink flags and refreshes status. This ensures the tab stops blinking once Claude resumes work after a permission grant.

**Script:** `scripts/clear-blink.sh` (same script as UserPromptSubmit)

---

### `Stop`

**Trigger:** The Claude Code session ends.

**What it does:**
1. Removes the `/tmp/claude-active-${TMUX_PANE}` file
2. Sets `@tab_claude_needs_input` to `1` and triggers `tab-blink-start` — this signals "session ended, check this tab"

**Script:** `scripts/stop.sh`

```bash
rm -f "/tmp/claude-active-${TMUX_PANE:-}" \
  && [ -n "${TMUX_PANE:-}" ] \
  && WIN=$(tmux display-message -t "${TMUX_PANE}" -p '#{window_index}' 2>/dev/null) \
  && [ -n "$WIN" ] \
  && tmux set-window-option -t :"$WIN" @tab_claude_needs_input '1' \
  && tmux refresh-client -S \
  && ~/dotFiles/tmux-scripts/tmux-powerline.sh tab-blink-start "$WIN" \
  || true
```

---

## Adapting to Your Setup

The only non-generic part of each script is the `~/dotFiles/tmux-scripts/tmux-powerline.sh` call. If you are not using this powerline setup, replace those lines with whatever triggers a visual update in your status bar.

The tmux window option writes (`tmux set-window-option`) are fully generic and work with any status bar that reads `#{@tab_claude_needs_input}` or `#{@tab_claude_blink}`.

**Minimal adaptation — status bar format string example:**

```
set -g window-status-format "#{?#{@tab_claude_needs_input}, ⚠ ,} #W"
```

This adds a warning indicator to any window where Claude is waiting for input, with no custom scripts required beyond the hook scripts themselves.
```

**Step 3: Validate the plugin**

```bash
claude plugin validate ./tmux
```

Expected: no errors

**Step 4: Commit**

```bash
git add tmux/skills/tmux-claude-hooks/SKILL.md
git commit -m "feat: add tmux-claude-hooks skill documenting hook behaviors"
```
