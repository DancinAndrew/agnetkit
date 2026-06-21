#!/usr/bin/env bash
# Bisection script to find which pytest test file creates unwanted files/state.
# Usage:   ./find-polluter.sh <path_to_check> <test_dir_or_pattern>
# Example: ./find-polluter.sh '.git_artifact' 'tests'
#
# Runs each test file in its own process; the first one that leaves <path_to_check>
# behind is the polluter. Ported from obra/superpowers (MIT) to pytest.

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <path_to_check> <test_dir_or_pattern>"
  echo "Example: $0 '.git_artifact' 'tests'"
  exit 2
fi

POLLUTION_CHECK="$1"
TEST_ROOT="$2"

TEST_FILES=$(find "$TEST_ROOT" -name 'test_*.py' -o -name '*_test.py' | sort)
TOTAL=$(printf '%s\n' "$TEST_FILES" | grep -c . || true)

echo "🔍 Looking for the test that creates: $POLLUTION_CHECK"
echo "   Across $TOTAL test files under: $TEST_ROOT"
echo ""

COUNT=0
for TEST_FILE in $TEST_FILES; do
  COUNT=$((COUNT + 1))

  if [ -e "$POLLUTION_CHECK" ]; then
    echo "⚠️  Pollution already present before test $COUNT/$TOTAL — clean it first."
    rm -rf "$POLLUTION_CHECK"
  fi

  echo "[$COUNT/$TOTAL] $TEST_FILE"
  python -m pytest "$TEST_FILE" -q >/dev/null 2>&1 || true

  if [ -e "$POLLUTION_CHECK" ]; then
    echo ""
    echo "🎯 FOUND POLLUTER: $TEST_FILE"
    echo "   created: $POLLUTION_CHECK"
    ls -la "$POLLUTION_CHECK" 2>/dev/null || true
    echo ""
    echo "Investigate:  python -m pytest $TEST_FILE -q   |   \$EDITOR $TEST_FILE"
    exit 1
  fi
done

echo ""
echo "✅ No polluter found — all test files clean."
exit 0
