---
name: code-stage
description: Stages all changes in the git repository and drafts a descriptive commit message based on the staged diff.
license: MIT
compatibility: opencode
---

## What I do
- Stage all current changes using `git add .`
- Analyze the staged changes using `git diff --cached`.
- Draft a concise and meaningful commit message based on the analysis.
- Present the drafted message to the user for review.

## When to use me
Use this when you want to prepare a commit by staging all files and generating a message draft. 

## Instructions
1. Run `git add .` to stage all changes, explicitly excluding any accidental submodule additions (like `kubernetes/ai` and `src/kiosk`).
2. Run `git diff --cached` to see what was staged.
3. Analyze the output to understand the changes.
4. Draft a commit message following the project's conventions (e.g., `feat(scope): description` using Conventional Commits style).
5. Provide the drafted message to the user.

**Note:** This skill does NOT perform the actual commit or push. It also specifically avoids managing submodules.
