#!/usr/bin/env bash
# scramstorm-handoff.sh — Automate handoff from scramstorm to SCRAM.
# Reads handoff.md manifest, extracts quick-win briefs from options.md,
# seeds a SCRAM workspace, and copies stub briefs.
# Usage: scramstorm-handoff.sh <brainstorm-workspace-path> <scram-workspace-path>
# Exit 0: handoff successful, workspace seeded
# Exit 1: validation failure (missing files, bad manifest)
# Exit 2: extraction failure (no briefs found, parse error)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -lt 2 ]; then
  echo "Usage: scramstorm-handoff.sh <brainstorm-workspace-path> <scram-workspace-path>" >&2
  exit 1
fi

BRAINSTORM_PATH="$1"
SCRAM_PATH="$2"

# --- Validation ---

if [ ! -d "$BRAINSTORM_PATH" ]; then
  echo "Error: brainstorm workspace does not exist: $BRAINSTORM_PATH" >&2
  exit 1
fi

if [ ! -f "$BRAINSTORM_PATH/options.md" ]; then
  echo "Error: options.md not found in $BRAINSTORM_PATH" >&2
  exit 1
fi

if [ ! -f "$BRAINSTORM_PATH/handoff.md" ]; then
  echo "Error: handoff.md not found in $BRAINSTORM_PATH" >&2
  exit 1
fi

# --- Parse handoff.md YAML frontmatter ---

FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$BRAINSTORM_PATH/handoff.md" | sed '1d;$d')

if [ -z "$FRONTMATTER" ]; then
  echo "Error: no YAML frontmatter found in handoff.md" >&2
  exit 1
fi

parse_field() {
  local field="$1"
  echo "$FRONTMATTER" | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//"
}

MANIFEST_VERSION=$(parse_field "manifest_version")
WINNING_OPTION=$(parse_field "winning_option")
G1_SKIP=$(parse_field "g1_skip_eligible")
G2_SKIP=$(parse_field "g2_skip_eligible")

if [ -z "$MANIFEST_VERSION" ]; then
  echo "Error: manifest_version not found in handoff.md frontmatter" >&2
  exit 1
fi

if [ "$MANIFEST_VERSION" != "1" ]; then
  echo "Error: unsupported manifest_version: $MANIFEST_VERSION (expected 1)" >&2
  exit 1
fi

# Extract briefs list (lines starting with "  - " after "briefs:")
MANIFEST_BRIEFS=()
IN_BRIEFS=false
while IFS= read -r line; do
  if [[ "$line" =~ ^briefs: ]]; then
    IN_BRIEFS=true
    continue
  fi
  if [ "$IN_BRIEFS" = true ]; then
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      MANIFEST_BRIEFS+=("${BASH_REMATCH[1]}")
    else
      break
    fi
  fi
done <<< "$FRONTMATTER"

# --- Extract quick-win briefs from options.md ---
# Sections with low effort estimates become stub briefs

OPTIONS_FILE="$BRAINSTORM_PATH/options.md"
EXTRACTED_SLUGS=()
EXTRACTED_TITLES=()
EXTRACTED_CONTENTS=()

CURRENT_TITLE=""
CURRENT_CONTENT=""
IN_SECTION=false

flush_section() {
  if [ "$IN_SECTION" = true ] && [ -n "$CURRENT_CONTENT" ]; then
    if echo "$CURRENT_CONTENT" | grep -qi 'effort.*low\|low.*effort\|\*\*Effort:\*\*.*low'; then
      local slug
      slug=$(echo "$CURRENT_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
      EXTRACTED_SLUGS+=("$slug")
      EXTRACTED_TITLES+=("$CURRENT_TITLE")
      EXTRACTED_CONTENTS+=("$CURRENT_CONTENT")
    fi
  fi
}

while IFS= read -r line; do
  if echo "$line" | grep -qE '^#{2,4}[[:space:]]+(Option|Approach)'; then
    flush_section
    CURRENT_TITLE=$(echo "$line" | sed 's/^#*[[:space:]]*//; s/[[:space:]]*(.*)//')
    CURRENT_CONTENT="$line"
    IN_SECTION=true
  elif [ "$IN_SECTION" = true ]; then
    CURRENT_CONTENT="${CURRENT_CONTENT}
${line}"
  fi
done < "$OPTIONS_FILE"
flush_section

# --- Create SCRAM workspace ---

if [ ! -d "$SCRAM_PATH" ]; then
  if ! "$SCRIPT_DIR/scram-init.sh" "$SCRAM_PATH" > /dev/null; then
    echo "Error: failed to initialize SCRAM workspace at $SCRAM_PATH" >&2
    exit 2
  fi
elif [ ! -d "$SCRAM_PATH/briefs" ]; then
  mkdir -p "$SCRAM_PATH/briefs"
fi

# --- Copy manifest briefs ---

COPIED=0

for brief_path in "${MANIFEST_BRIEFS[@]}"; do
  if [ ! -f "$brief_path" ]; then
    echo "Warning: brief not found, skipping: $brief_path" >&2
    continue
  fi

  FILENAME=$(basename "$brief_path")
  SLUG="${FILENAME%.md}"
  DEST="$SCRAM_PATH/briefs/${SLUG}.md"

  {
    echo "## Status: stub — requires G3 refinement"
    echo "## Source ticket: ${SLUG}"
    echo ""
    cat "$brief_path"
  } > "$DEST"

  COPIED=$((COPIED + 1))
done

# --- Write extracted quick-win briefs from options.md ---

EXTRACTED=0

for i in "${!EXTRACTED_SLUGS[@]}"; do
  slug="${EXTRACTED_SLUGS[$i]}"
  title="${EXTRACTED_TITLES[$i]}"
  content="${EXTRACTED_CONTENTS[$i]}"
  DEST="$SCRAM_PATH/briefs/${slug}.md"

  # Skip if a manifest brief already covers this slug
  if [ -f "$DEST" ]; then
    continue
  fi

  {
    echo "## Status: stub — requires G3 refinement"
    echo "## Source ticket: ${slug}"
    echo ""
    echo "# ${title}"
    echo ""
    echo "## Story"
    echo "Quick-win extracted from scramstorm options.md. Low effort estimate."
    echo ""
    echo "## Original Content"
    echo "${content}"
  } > "$DEST"

  EXTRACTED=$((EXTRACTED + 1))
done

# --- Confirmation summary ---

TOTAL=$((COPIED + EXTRACTED))

echo "Scramstorm handoff complete."
echo "  Brainstorm workspace: $BRAINSTORM_PATH"
echo "  SCRAM workspace:      $SCRAM_PATH"
echo "  Winning option:       ${WINNING_OPTION:-null}"
echo "  G1 skip eligible:     ${G1_SKIP:-false}"
echo "  G2 skip eligible:     ${G2_SKIP:-false}"
echo "  Manifest briefs:      ${#MANIFEST_BRIEFS[@]} found, $COPIED copied"
echo "  Quick-win extracts:   ${#EXTRACTED_SLUGS[@]} found, $EXTRACTED copied"
echo "  Total briefs:         $TOTAL"

exit 0
