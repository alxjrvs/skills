# Powerline Skills Design

## Overview

Two new skills in the `tmux` plugin, both Claude-facing: one focused purely on the glyph
model for building powerline transitions, one covering practical tips and patterns.

---

## Skill 1: `powerline-glyphs`

**Purpose:** Give Claude a working recipe for powerline glyph color assignments so it can
propose or debug exact format strings without re-deriving the model each time.

### Sections

**Core rule**
FG = the color on the source side (what the glyph blends into).
BG = the color on the destination side (what comes after).
The FG-dominant side of the glyph faces its source; BG faces the destination.

**Glyph catalog**
Two glyphs used in this setup:

- `U+E0BC` (SL, ``): forward-slash shape. FG dominates the **left** side. Used as a
  segment entry arrow — left side blends with the terminal background or prior segment exit.
- `U+E0BA` (BS, ``): backslash shape. FG dominates the **right** side. Used as a
  sub-segment separator or segment exit — right side blends with what follows.

**Recipes**

1. *Terminal → segment entry* (SL):
   `#[bg=SEGMENT_BG, fg=TERM_BG]SL`
   Left (FG) = TERM_BG, blends with terminal. Right (BG) = SEGMENT_BG, enters segment.

2. *Value → label sub-split* (BS):
   `#[bg=VALUE_BG, fg=LABEL_BG]BS`
   Left (BG) = VALUE_BG (current segment). Right (FG) = LABEL_BG (darker label). The next
   cell sets `bg=LABEL_BG` to match.

3. *Inter-segment valley* (BS then SL):
   `#[bg=PREV_DK, fg=TERM_BG]BS` + `#[bg=NEXT_BG, fg=TERM_BG]SL`
   BS exits the previous segment's dark label area back to TERM_BG; SL enters the next
   segment from TERM_BG. Creates a thin diagonal "V" of terminal background between segments.

**Worked example**
Full CPU segment from `status-right`, annotated line by line.

---

## Skill 2: `powerline-tips`

**Purpose:** Practical patterns and gotchas Claude needs when helping design or edit tmux
powerline format strings.

### Sections

1. **Value+label pattern** — every status-right segment uses a bright `SEGMENT_BG` for the
   number/value and a darker `SEGMENT_DK` for the text label. Always paired; the DK variant
   is set alongside the main color.

2. **`default` vs explicit TERM_BG** — `bg=default` inherits from the window background and
   can drift. Explicit `bg=#282c34` (or `TERM_BG` variable) is required when the glyph must
   blend precisely with the terminal background color.

3. **tmux `##` escaping** — inside `#[...]` style blocks, `#` must be written as `##` to
   produce a literal `#`. Hex color values inside style blocks require `##rrggbb`.
   Example: `#[fg=##f0f0f0]`.

4. **Status-right build direction** — the string is assembled left-to-right in code but the
   rightmost segment in the string is the leftmost on screen (nearest the center of the bar).
   Plan the visual layout right-to-left, then write code left-to-right.

5. **Per-window `@tab_*` option pattern** — dynamic tab colors are driven by setting
   per-window options (`tmux set-window-option @tab_foo value`) and reading them in
   `window-status-format` via `#{@tab_foo}`. This avoids re-running scripts on every render;
   only the hook or tab-colors command updates the values.

---

## File Locations

- `tmux/skills/powerline-glyphs/SKILL.md`
- `tmux/skills/powerline-tips/SKILL.md`
