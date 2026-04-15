---
name: new-feature
description: Guided workflow for implementing a new feature safely. Use when starting work on something new. Invoke with /new-feature [description].
---

# New Feature: $ARGUMENTS

Follow these steps in order. Do not skip ahead.

## 1. Explore

Read the relevant parts of the codebase:

- Find similar existing features to understand the pattern
- Identify which layers / modules will be affected
- Note any shared utilities or abstractions you should reuse

## 2. Plan

Write a short implementation plan:

- Files to create or modify
- Layer-by-layer breakdown (data → domain → presentation or equivalent)
- Test strategy

**Stop here. Show me the plan and wait for my approval.**

## 3. Implement

After approval, implement following the project's existing conventions from CLAUDE.md and rules.

One layer at a time. No sweeping changes outside the feature scope.

## 4. Test

Write tests alongside the implementation — not after.

## 5. Summarise

List every file changed and what was done to each.
Do NOT commit or stage anything.
