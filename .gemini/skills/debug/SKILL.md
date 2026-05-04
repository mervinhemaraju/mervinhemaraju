---
name: debug
description: Systematic debugging workflow. Use when something is broken, a test is failing, or behaviour is unexpected. Invoke with /debug [description of the problem].
---

# Debug: $ARGUMENTS

Work through this in order. Do not jump to fixes before understanding the problem.

## 1. Reproduce

Confirm you can see the problem:

- Run the failing test / command and capture the exact error output
- Note the full stack trace — read it bottom-up to find the origin

## 2. Locate

Narrow down where the fault lives:

- What is the last known-good state?
- Which file / function / layer is the first to behave incorrectly?
- Use `grep`, `find`, or read relevant files — do not guess

## 3. Hypothesise

State 2–3 possible causes ranked by likelihood.
Pick the most likely one to investigate first.

## 4. Verify

Prove or disprove the hypothesis:

- Add a temporary log or assertion if needed
- Run the smallest possible reproduction

## 5. Fix

Make the minimal change that addresses the root cause.
Do not fix unrelated things you notice along the way — note them separately.

## 6. Confirm

Run the full test suite (or at minimum the affected tests) to confirm:

- The original problem is gone
- Nothing else broke

## 7. Report

Summary of:

- Root cause (one sentence)
- What was changed and why
- Anything else noticed that should be addressed separately

Do NOT commit. Do NOT clean up unrelated code in the same change.
