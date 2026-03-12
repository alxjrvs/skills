# Powerline Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create two Claude-facing skills in the tmux plugin — `powerline-glyphs` (glyph color recipe model) and `powerline-tips` (practical format string patterns).

**Architecture:** Two new SKILL.md files under `tmux/skills/`. Pure markdown documentation, no code. Validate with `claude plugin validate ./tmux` after each.

**Tech Stack:** Markdown, Claude Code plugin system

---

### Task 1: Create powerline-glyphs skill

**Files:**
- Create: `tmux/skills/powerline-glyphs/SKILL.md`

**Step 1: Create the directory**

```bash
mkdir -p /Users/jarvis/Code/JrvsSkills/tmux/skills/powerline-glyphs
```

**Step 2: Write the skill file**

Create `tmux/skills/powerline-glyphs/SKILL.md` with this exact content:

````markdown
---
description: Recipe for powerline glyph color assignments — which side FG dominates, how to flow segments together, and exact color patterns for entry/split/exit transitions.
---

# Powerline Glyphs

Powerline-style status bars use filled Nerd Font glyphs to create seamless color transitions
between segments. Each glyph has one side fully dominated by FG and the other by BG.

**Core rule:** FG = source color (what the glyph blends into on its dominant side). BG =
destination color (what follows). The FG side faces its source; BG faces the destination.

---

## Glyph Catalog

Two glyphs are used in this setup:

| Variable | Glyph | Codepoint | FG side | Shape | Use |
|---|---|---|---|---|---|
| `SL` | `` | U+E0BC | **Left** | Forward-slash `/` | Segment entry |
| `BS` | `` | U+E0BA | **Right** | Backslash `\` | Sub-split or exit |

**Reading the table:** "FG side = Left" means the FG color fills the left triangle of the
glyph. To blend with the terminal background on the left, set `fg=TERM_BG`.

---

## Recipes

### 1. Terminal → segment entry (SL)

Use at the start of a segment to transition from terminal background into the segment color.

```
#[bg=SEGMENT_BG, fg=TERM_BG]<SL glyph>
```

- Left side (FG = TERM_BG): blends with terminal background to the left
- Right side (BG = SEGMENT_BG): enters the segment

### 2. Value → label sub-split (BS)

Use inside a segment to split a bright value area from a darker label area.

```
#[bg=VALUE_BG, fg=LABEL_BG]<BS glyph>
#[bg=LABEL_BG, fg=#f0f0f0] LABEL TEXT
```

- Left side (BG = VALUE_BG): continues the value segment
- Right side (FG = LABEL_BG): bleeds into the label segment that follows

### 3. Inter-segment valley (BS exit + SL entry)

Use between two segments to create a thin diagonal "V" of terminal background.

```
#[bg=PREV_DK, fg=TERM_BG]<BS glyph>
#[bg=NEXT_BG, fg=TERM_BG]<SL glyph>
```

- BS right side (FG = TERM_BG): exits previous segment back to terminal BG
- SL left side (FG = TERM_BG): enters next segment from terminal BG
- The two complementary slopes create a V-shaped valley of terminal color between segments

---

## Worked Example: CPU Segment

From `status-right` in `tmux-powerline.sh`. Variables: `CPU_BG` = bright CPU color,
`CPU_DK` = darker CPU label color, `TERM_BG` = terminal background (`#282c34`).

```sh
# 1. Entry: terminal BG → CPU_BG via SL
#    FG=TERM_BG (left side blends with bar background)
#    BG=CPU_BG  (right side enters segment)
o="#[bg=${CPU_BG},fg=${TERM_BG}]${SL}"

# 2. Value text: CPU percentage on bright background
o="${o}#[bg=${CPU_BG},fg=#f0f0f0] ${cpu_display} "

# 3. Sub-split: CPU_BG → CPU_DK via BS
#    BG=CPU_BG (left side continues bright area)
#    FG=CPU_DK (right side bleeds into label color)
o="${o}#[bg=${CPU_BG},fg=${CPU_DK}]${BS}"

# 4. Label text: "CPU" on darker background
o="${o}#[bg=${CPU_DK},fg=#f0f0f0,nobold] CPU "

# 5. Exit: CPU_DK → TERM_BG via BS (before next segment's SL entry)
#    BG=CPU_DK (left side finishes segment)
#    FG=TERM_BG (right side returns to terminal BG)
o="${o}#[bg=${CPU_DK},fg=${TERM_BG}]${BS}"
```

The next segment then starts with its own `SL` entry from TERM_BG, completing the valley.
````

**Step 3: Validate**

```bash
cd /Users/jarvis/Code/JrvsSkills && claude plugin validate ./tmux
```

Expected: no errors (pre-existing author warning is fine)

**Step 4: Commit**

```bash
cd /Users/jarvis/Code/JrvsSkills && git add tmux/skills/powerline-glyphs/SKILL.md && git commit -m "feat: add powerline-glyphs skill"
```

---

### Task 2: Create powerline-tips skill

**Files:**
- Create: `tmux/skills/powerline-tips/SKILL.md`

**Step 1: Create the directory**

```bash
mkdir -p /Users/jarvis/Code/JrvsSkills/tmux/skills/powerline-tips
```

**Step 2: Write the skill file**

Create `tmux/skills/powerline-tips/SKILL.md` with this exact content:

````markdown
---
description: Practical patterns and gotchas for building tmux powerline format strings — value+label pairing, color blending, escaping, build direction, and dynamic per-window options.
---

# Powerline Tips

Practical patterns for building and editing tmux powerline format strings. See also:
`powerline-glyphs` for the glyph color model.

---

## Value + Label Pattern

Every status-right segment uses two background colors: a bright `SEGMENT_BG` for the
value/number, and a darker `SEGMENT_DK` for the text label. Always define and use them
as a pair — the sub-separator glyph (U+E0BA) transitions between them.

```sh
# Bright value area
o="${o}#[bg=${CPU_BG},fg=#f0f0f0] ${cpu_display} "
# Transition via BS glyph
o="${o}#[bg=${CPU_BG},fg=${CPU_DK}]${BS}"
# Darker label area
o="${o}#[bg=${CPU_DK},fg=#f0f0f0,nobold] CPU "
```

When adding a new segment, define both `SEGMENT_BG` and `SEGMENT_DK` in `theme.sh`.

---

## `default` vs Explicit TERM_BG

`bg=default` inherits from the window background and can produce visible mismatches
when the window bg differs from the status bar bg. Use the explicit terminal background
color (`#282c34` or the `TERM_BG` variable) whenever a glyph must blend precisely with
the bar background.

```sh
# Unreliable — may not match status bar background
#[bg=default,fg=#c07018]

# Reliable — explicit terminal background
TERM_BG="#282c34"
#[bg=${TERM_BG},fg=#c07018]
```

---

## Hex Colors Inside tmux Style Blocks

Inside `#[...]` style blocks, `#` must be written as `##` to produce a literal `#`. Hex
color values therefore require `##rrggbb`.

```
# Wrong — tmux interprets the # as a variable prefix
#[fg=#f0f0f0]

# Correct inside window-status-format strings that go through double-expansion
#[fg=##f0f0f0]
```

This applies inside `window-status-format`, `window-status-current-format`, and any
format string that tmux double-expands. It does **not** apply to `set-option` values set
directly in shell (e.g. via `tmux set-window-option`) — those are single-expanded and
use plain `#rrggbb`.

---

## Status-Right Build Direction

The status-right string is assembled left-to-right in code, but renders from right to
left on screen — the last segment appended in code is the leftmost segment on the bar
(nearest the window list).

Plan the visual layout right-to-left (TIME → BAT → MEM → CPU from right edge inward),
then write the code left-to-right in that order.

```
Visual (screen):  [CPU][MEM][BAT][TIME]  ← right edge of bar
Code order:        CPU  MEM  BAT  TIME   (appended first → last)
```

---

## Dynamic Colors via Per-Window Options

Tab colors and per-window state are driven by `tmux set-window-option @tab_foo value`
and read in format strings via `#{@tab_foo}`. This avoids re-running scripts on every
status bar render — only the hook or `tab-colors` command updates the values.

```sh
# Set in tab-colors script or hook
tmux set-window-option -t :$WIN @tab_dk_color "#9a5818"

# Read in window-status-current-format
#[bg=#{@tab_dk_color},fg=#f0f0f0] #W
```

For conditional logic, combine with `#{?condition,true,false}`:

```
#{?#{@tab_claude_needs_input},#[bg=#D97757],#[bg=#{@tab_inactive_color}]}
```

An empty string (`''`) clears an option — tmux treats unset and empty identically in
`#{}` expansions, so clearing an option effectively sets its conditional to false.
````

**Step 3: Validate**

```bash
cd /Users/jarvis/Code/JrvsSkills && claude plugin validate ./tmux
```

Expected: no errors

**Step 4: Commit**

```bash
cd /Users/jarvis/Code/JrvsSkills && git add tmux/skills/powerline-tips/SKILL.md && git commit -m "feat: add powerline-tips skill"
```
