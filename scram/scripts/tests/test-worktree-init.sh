#!/usr/bin/env bash
# test-worktree-init.sh — TDD tests for worktree-init.sh guard behaviors.
# RED: non-scram/ prefix guard test fails before the guard is added.
# GREEN: all tests pass after the guard is implemented.

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
# TEST GROUP 1: integration branch prefix guard
# A non-scram/-prefixed integration branch must exit with a clear error
# before the script attempts to strip the prefix or create branches.
# ---------------------------------------------------------------------------
echo ""
echo "=== worktree-init.sh: integration branch prefix guard ==="

# Test: non-scram/ prefix exits with non-zero exit code
TMPDIR_GUARD=$(mktemp -d)
cd "$TMPDIR_GUARD"
git init -q
git commit --allow-empty -m "init"

OUTPUT=$("$SCRIPTS_DIR/worktree-init.sh" "main" "my-story" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -ne 0 ]; then
  pass "worktree-init.sh: non-scram/ branch 'main' exits with non-zero exit code ($EXIT_CODE)"
else
  fail "worktree-init.sh: non-scram/ branch 'main' should exit non-zero but exited 0"
fi

# Test: error message mentions the invalid branch name
if echo "$OUTPUT" | grep -q "main"; then
  pass "worktree-init.sh: error output references the invalid branch name 'main'"
else
  fail "worktree-init.sh: error output does not reference 'main' — got: $OUTPUT"
fi

# Test: error message indicates the scram/ prefix requirement
if echo "$OUTPUT" | grep -qi "scram/"; then
  pass "worktree-init.sh: error output mentions required 'scram/' prefix"
else
  fail "worktree-init.sh: error output does not mention 'scram/' prefix — got: $OUTPUT"
fi

# Test: another non-scram/ branch name also fails
OUTPUT2=$("$SCRIPTS_DIR/worktree-init.sh" "feature/my-thing" "my-story" 2>&1)
EXIT_CODE2=$?
if [ "$EXIT_CODE2" -ne 0 ]; then
  pass "worktree-init.sh: non-scram/ branch 'feature/my-thing' exits with non-zero exit code"
else
  fail "worktree-init.sh: non-scram/ branch 'feature/my-thing' should exit non-zero but exited 0"
fi

cd /tmp
rm -rf "$TMPDIR_GUARD"

# ---------------------------------------------------------------------------
# TEST GROUP 2: valid scram/ prefix passes the guard
# The script must NOT exit early when given a scram/-prefixed branch.
# (It will still fail Check 1 since we're not in a worktree — that's correct.)
# ---------------------------------------------------------------------------
echo ""
echo "=== worktree-init.sh: valid scram/ prefix reaches Check 1 ==="

TMPDIR_VALID=$(mktemp -d)
cd "$TMPDIR_VALID"
git init -q
git commit --allow-empty -m "init"

OUTPUT=$("$SCRIPTS_DIR/worktree-init.sh" "scram/my-feature" "my-story" 2>&1)
EXIT_CODE=$?

# The script must not emit the prefix guard error
if echo "$OUTPUT" | grep -qi "must start with scram/\|integration branch.*prefix\|not a valid integration branch"; then
  fail "worktree-init.sh: scram/ prefix still hit guard error — got: $OUTPUT"
else
  pass "worktree-init.sh: scram/ prefix 'scram/my-feature' does not trigger prefix guard"
fi

# It should fail at Check 1 (not in a worktree) — exit 1 from the worktree check
# OR exit 2 (branch not found in a new temp repo) — both are correct
# The key: it must NOT exit due to the prefix guard
if echo "$OUTPUT" | grep -q "FAIL: Not in a worktree\|FAIL: Cannot find integration branch"; then
  pass "worktree-init.sh: scram/ prefix reaches Check 1 or Check 2 (not prefix guard)"
else
  fail "worktree-init.sh: scram/ prefix did not reach expected checks — got: $OUTPUT"
fi

cd /tmp
rm -rf "$TMPDIR_VALID"

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
