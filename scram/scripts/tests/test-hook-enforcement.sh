#!/usr/bin/env bash
# test-hook-enforcement.sh — TDD tests for isolation-check.sh and merge-guard.sh.
# RED: these tests should fail before the scripts are created.
# GREEN: all tests pass after implementation.

SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=""

pass() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL=$((FAIL + 1))
  ERRORS="$ERRORS\n  - $1"
}

# ---------------------------------------------------------------------------
# TEST GROUP 1: isolation-check.sh — file existence and basic structure
# ---------------------------------------------------------------------------
echo ""
echo "=== isolation-check.sh: existence ==="

if [ -f "$SCRIPTS_DIR/isolation-check.sh" ]; then
  pass "isolation-check.sh exists"
else
  fail "isolation-check.sh does not exist at $SCRIPTS_DIR/isolation-check.sh"
fi

if [ -x "$SCRIPTS_DIR/isolation-check.sh" ]; then
  pass "isolation-check.sh is executable"
else
  fail "isolation-check.sh is not executable"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 2: isolation-check.sh — no-op when SCRAM_WORKSPACE unset
# ---------------------------------------------------------------------------
echo ""
echo "=== isolation-check.sh: guard on SCRAM_WORKSPACE ==="

if [ -f "$SCRIPTS_DIR/isolation-check.sh" ]; then
  # With no SCRAM_WORKSPACE, should exit 0 (no-op)
  OUTPUT=$(echo '{}' | env -u SCRAM_WORKSPACE "$SCRIPTS_DIR/isolation-check.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "isolation-check.sh: exits 0 when SCRAM_WORKSPACE is unset"
  else
    fail "isolation-check.sh: should exit 0 when SCRAM_WORKSPACE is unset, got $EXIT_CODE"
  fi
else
  fail "isolation-check.sh: skip (file not found)"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 3: isolation-check.sh — no HALT when no worktrees need checking
# ---------------------------------------------------------------------------
echo ""
echo "=== isolation-check.sh: no-op when no isolation failure ==="

if [ -f "$SCRIPTS_DIR/isolation-check.sh" ]; then
  TMPDIR_IC=$(mktemp -d)
  mkdir -p "$TMPDIR_IC"

  # No worktrees file or empty workspace — should exit 0
  OUTPUT=$(echo '{}' | SCRAM_WORKSPACE="$TMPDIR_IC" "$SCRIPTS_DIR/isolation-check.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "isolation-check.sh: exits 0 when workspace exists but no isolation failure"
  else
    fail "isolation-check.sh: unexpected non-zero exit for empty workspace — got $EXIT_CODE"
  fi

  # Should NOT write HALT file when exit 0
  if [ ! -f "$TMPDIR_IC/HALT" ]; then
    pass "isolation-check.sh: does not write HALT when no failure"
  else
    fail "isolation-check.sh: incorrectly wrote HALT file"
  fi

  rm -rf "$TMPDIR_IC"
else
  fail "isolation-check.sh: skip (file not found)"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 4: merge-guard.sh — file existence and basic structure
# ---------------------------------------------------------------------------
echo ""
echo "=== merge-guard.sh: existence ==="

if [ -f "$SCRIPTS_DIR/merge-guard.sh" ]; then
  pass "merge-guard.sh exists"
else
  fail "merge-guard.sh does not exist at $SCRIPTS_DIR/merge-guard.sh"
fi

if [ -x "$SCRIPTS_DIR/merge-guard.sh" ]; then
  pass "merge-guard.sh is executable"
else
  fail "merge-guard.sh is not executable"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 5: merge-guard.sh — no-op when SCRAM_WORKSPACE unset
# ---------------------------------------------------------------------------
echo ""
echo "=== merge-guard.sh: guard on SCRAM_WORKSPACE ==="

if [ -f "$SCRIPTS_DIR/merge-guard.sh" ]; then
  # With no SCRAM_WORKSPACE, should always exit 0 regardless of command
  OUTPUT=$(printf '{"command":"git merge some-branch"}' | env -u SCRAM_WORKSPACE "$SCRIPTS_DIR/merge-guard.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "merge-guard.sh: exits 0 for git merge when SCRAM_WORKSPACE is unset"
  else
    fail "merge-guard.sh: should exit 0 when SCRAM_WORKSPACE is unset, got $EXIT_CODE"
  fi
else
  fail "merge-guard.sh: skip (file not found)"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 6: merge-guard.sh — non-merge commands pass through
# ---------------------------------------------------------------------------
echo ""
echo "=== merge-guard.sh: pass-through for non-merge commands ==="

if [ -f "$SCRIPTS_DIR/merge-guard.sh" ]; then
  TMPDIR_MG=$(mktemp -d)

  # git status — should pass
  OUTPUT=$(printf '{"command":"git status"}' | SCRAM_WORKSPACE="$TMPDIR_MG" "$SCRIPTS_DIR/merge-guard.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "merge-guard.sh: exits 0 for git status"
  else
    fail "merge-guard.sh: git status should exit 0, got $EXIT_CODE"
  fi

  # npm install — should pass
  OUTPUT=$(printf '{"command":"npm install"}' | SCRAM_WORKSPACE="$TMPDIR_MG" "$SCRIPTS_DIR/merge-guard.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "merge-guard.sh: exits 0 for npm install"
  else
    fail "merge-guard.sh: npm install should exit 0, got $EXIT_CODE"
  fi

  # git commit — should pass
  OUTPUT=$(printf '{"command":"git commit -m feat: add something"}' | SCRAM_WORKSPACE="$TMPDIR_MG" "$SCRIPTS_DIR/merge-guard.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 0 ]; then
    pass "merge-guard.sh: exits 0 for git commit"
  else
    fail "merge-guard.sh: git commit should exit 0, got $EXIT_CODE"
  fi

  rm -rf "$TMPDIR_MG"
else
  fail "merge-guard.sh: skip (file not found)"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 7: merge-guard.sh — git merge without pre-merge-check.sh args
# When git merge is detected but no approved args, should exit non-zero
# ---------------------------------------------------------------------------
echo ""
echo "=== merge-guard.sh: intercepts git merge commands ==="

if [ -f "$SCRIPTS_DIR/merge-guard.sh" ]; then
  TMPDIR_MG2=$(mktemp -d)
  mkdir -p "$TMPDIR_MG2"

  # Plain 'git merge some-branch' — should be intercepted (exits non-zero)
  OUTPUT=$(printf '{"command":"git merge some-branch"}' | SCRAM_WORKSPACE="$TMPDIR_MG2" "$SCRIPTS_DIR/merge-guard.sh" 2>&1)
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -ne 0 ]; then
    pass "merge-guard.sh: intercepts plain 'git merge some-branch' (exits non-zero)"
  else
    fail "merge-guard.sh: should block 'git merge some-branch' but exited 0"
  fi

  # Output should explain the block
  if echo "$OUTPUT" | grep -qi "merge\|guard\|block\|SCRAM"; then
    pass "merge-guard.sh: output explains why merge was intercepted"
  else
    fail "merge-guard.sh: output does not explain interception — got: $OUTPUT"
  fi

  rm -rf "$TMPDIR_MG2"
else
  fail "merge-guard.sh: skip (file not found)"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 8: hooks.json — PostToolUse and Bash PreToolUse entries
# ---------------------------------------------------------------------------
echo ""
echo "=== hooks.json: new hook entries ==="

HOOKS_FILE="$(dirname "$SCRIPTS_DIR")/hooks/hooks.json"

if [ -f "$HOOKS_FILE" ]; then
  # PostToolUse key must exist
  if grep -q '"PostToolUse"' "$HOOKS_FILE"; then
    pass "hooks.json: contains PostToolUse key"
  else
    fail "hooks.json: missing PostToolUse key"
  fi

  # Agent matcher for PostToolUse
  if grep -q '"Agent"' "$HOOKS_FILE"; then
    pass "hooks.json: contains Agent matcher"
  else
    fail "hooks.json: missing Agent matcher in PostToolUse"
  fi

  # isolation-check.sh reference
  if grep -q 'isolation-check.sh' "$HOOKS_FILE"; then
    pass "hooks.json: references isolation-check.sh"
  else
    fail "hooks.json: missing isolation-check.sh reference"
  fi

  # merge-guard.sh reference
  if grep -q 'merge-guard.sh' "$HOOKS_FILE"; then
    pass "hooks.json: references merge-guard.sh"
  else
    fail "hooks.json: missing merge-guard.sh reference"
  fi

  # Bash matcher for PreToolUse merge-guard
  if grep -q '"Bash"' "$HOOKS_FILE"; then
    pass "hooks.json: contains Bash matcher for PreToolUse"
  else
    fail "hooks.json: missing Bash matcher in PreToolUse"
  fi

  # Valid JSON
  if command -v jq &>/dev/null; then
    if jq empty "$HOOKS_FILE" 2>/dev/null; then
      pass "hooks.json: is valid JSON"
    else
      fail "hooks.json: invalid JSON"
    fi
  else
    pass "hooks.json: jq not available, skipping JSON validation"
  fi
else
  fail "hooks.json: not found at $HOOKS_FILE"
fi

# ---------------------------------------------------------------------------
# TEST GROUP 9: pre-merge-check.sh — exact SHA matching (not substring)
# Verifies that a SHA appearing only in a commit subject does not pass the
# sha_on_branch check. The buggy grep "$COMMIT_SHA" would match the subject
# line; the fixed awk+grep -Fx matches only the SHA column.
# ---------------------------------------------------------------------------
echo ""
echo "=== pre-merge-check.sh: exact SHA matching ==="

PRE_MERGE_SCRIPT="$SCRIPTS_DIR/pre-merge-check.sh"

if [ ! -f "$PRE_MERGE_SCRIPT" ]; then
  fail "pre-merge-check.sh: not found at $PRE_MERGE_SCRIPT"
else
  TMPDIR_PMC=$(mktemp -d)
  PMC_RESULTS="$TMPDIR_PMC/results.txt"
  (
    cd "$TMPDIR_PMC" || exit 1
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    # Commit A — create a real commit on an integration-like branch
    git checkout -q -b integration
    echo "base" > base.txt
    git add base.txt
    git commit -q -m "initial commit"

    # Commit B on story branch — subject embeds a known fake SHA string
    git checkout -q -b story-branch
    EMBEDDED_SHA="abc1234"
    echo "story" > story.txt
    git add story.txt
    git commit -q -m "revert $EMBEDDED_SHA from previous change"

    # EMBEDDED_SHA appears in the commit subject but is not an actual commit SHA.
    # The buggy grep "$COMMIT_SHA" matches the subject line and exits 0 (false positive).
    # The fixed awk '{print $1}' | grep -Fx "$COMMIT_SHA" only checks the SHA column.
    OUTPUT=$(bash "$PRE_MERGE_SCRIPT" story-branch "$EMBEDDED_SHA" integration 2>&1)
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
      echo "PASS:rejects SHA embedded only in commit subject" >> "$PMC_RESULTS"
    else
      echo "FAIL:falsely accepted SHA found only in commit subject (substring match bug)" >> "$PMC_RESULTS"
    fi

    # Capture a real commit SHA and verify it IS accepted (sha_on_branch check passes)
    REAL_SHA=$(git rev-parse --short HEAD)
    OUTPUT2=$(bash "$PRE_MERGE_SCRIPT" story-branch "$REAL_SHA" integration 2>&1)
    # Script may still fail on diff_non_empty, but must NOT fail on sha_on_branch
    if echo "$OUTPUT2" | grep -q "sha_on_branch"; then
      echo "FAIL:rejected a valid commit SHA as not on branch" >> "$PMC_RESULTS"
    else
      echo "PASS:accepts a valid commit SHA on the branch" >> "$PMC_RESULTS"
    fi
  )

  while IFS= read -r line; do
    case "$line" in
      PASS:*) pass "${line#PASS:}" ;;
      FAIL:*) fail "${line#FAIL:}" ;;
    esac
  done < "$PMC_RESULTS"

  rm -rf "$TMPDIR_PMC"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  echo -e "$ERRORS"
  exit 1
fi

exit 0
