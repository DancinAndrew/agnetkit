---
name: verification-loop
description: "Comprehensive verification for Claude Code sessions. Use before claiming work is complete/fixed/passing and before commits or PRs — run the checks and confirm output before any success claim. Evidence before assertions, always."
origin: ECC, locally enhanced (Iron Law + Gate from obra/superpowers verification-before-completion, MIT)
---

# Verification Loop Skill

A comprehensive verification system for Claude Code sessions.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

Claiming work is complete without verification is dishonesty, not efficiency. If you haven't
run the verification command in *this* message, you cannot claim it passes. This backs
CLAUDE.md §1.4 ("Loop until verified") with an executable gate.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction ("Great!", "Done!", "Perfect!"):

1. IDENTIFY: What command proves this claim?
2. RUN:      Execute the FULL command, fresh and complete.
3. READ:     Full output — check exit code, count failures.
4. VERIFY:   Does the output confirm the claim?
               NO  -> state the actual status with evidence
               YES -> state the claim WITH the evidence
5. ONLY THEN: make the claim.

Skip any step = claiming without proof.
```

## When to Use

Invoke this skill:
- After completing a feature or significant code change
- Before creating a PR
- When you want to ensure quality gates pass
- After refactoring

## Verification Phases

### Phase 1: Build Verification
```bash
# Check if project builds
npm run build 2>&1 | tail -20
# OR
pnpm build 2>&1 | tail -20
```

If build fails, STOP and fix before continuing.

### Phase 2: Type Check
```bash
# TypeScript projects
npx tsc --noEmit 2>&1 | head -30

# Python projects
pyright . 2>&1 | head -30
```

Report all type errors. Fix critical ones before continuing.

### Phase 3: Lint Check
```bash
# JavaScript/TypeScript
npm run lint 2>&1 | head -30

# Python
ruff check . 2>&1 | head -30
```

### Phase 4: Test Suite
```bash
# Run tests with coverage
npm run test -- --coverage 2>&1 | tail -50

# Check coverage threshold
# Target: 80% minimum
```

Report:
- Total tests: X
- Passed: X
- Failed: X
- Coverage: X%

### Phase 5: Security Scan
```bash
# Check for secrets
grep -rn "sk-" --include="*.ts" --include="*.js" . 2>/dev/null | head -10
grep -rn "api_key" --include="*.ts" --include="*.js" . 2>/dev/null | head -10

# Check for console.log
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10
```

### Phase 6: Diff Review
```bash
# Show what changed
git diff --stat
git diff HEAD~1 --name-only
```

Review each changed file for:
- Unintended changes
- Missing error handling
- Potential edge cases

## Output Format

After running all phases, produce a verification report:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## Continuous Mode

For long sessions, run verification every 15 minutes or after major changes:

```markdown
Set a mental checkpoint:
- After completing each function
- After finishing a component
- Before moving to next task

Run: /verify
```

## Integration with Hooks

This skill complements PostToolUse hooks but provides deeper verification.
Hooks catch issues immediately; this skill provides comprehensive review.

## Common Failures — What a Claim Actually Requires

| Claim | Requires | NOT sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | A previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build/type-check: exit 0 | "Linter passed", logs look fine |
| Bug fixed | Test the original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red→green cycle verified (revert fix, see it FAIL) | Test passes once |
| Agent completed | `git diff` shows the changes | The agent reported "success" |
| Requirements met | Line-by-line checklist | "Tests pass, so it's done" |

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification. |
| "I'm confident" | Confidence ≠ evidence. |
| "Just this once" | No exceptions. |
| "Linter passed" | Linter ≠ compiler/type-checker. |
| "Agent said success" | Verify independently with the diff. |
| "I'm tired" | Exhaustion ≠ excuse. |
| "Partial check is enough" | Partial proves nothing about the whole. |
| "Different words, so the rule doesn't apply" | Spirit over letter — any wording implying success counts. |

**The bottom line:** run the command, read the output, THEN claim the result. Non-negotiable.
