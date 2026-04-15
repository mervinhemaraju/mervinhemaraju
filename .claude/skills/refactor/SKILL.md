---
name: refactor
description: Plan and execute a focused refactor. Use when user wants to clean up, restructure, or improve existing code. Invoke with /refactor [target] where target is a file, function, or module name.
---

# Refactor: $ARGUMENTS

## Step 1 — Understand

Read the target code. Identify:

- What it does
- What makes it hard to read, test, or change
- What pattern it should follow (check CLAUDE.md and rules)

## Step 2 — Plan

Write out the refactor plan before touching any code:

- What changes and why
- What stays the same
- What tests are needed to verify no regression

Show me the plan. Wait for my approval before proceeding.

## Step 3 — Execute

Make the changes. Keep the diff minimal — only change what the plan covers.

## Step 4 — Verify

Run the relevant tests/linter to confirm nothing is broken.
Report the outcome. Do NOT commit.
