---
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(git branch:*)
---

1. First, run `git diff` to see all changes (both staged and unstaged)
2. Analyze the diff to understand what changed
3. Write a conventional commit message based on the diff:
  - Use format: `type(scope): description`
  - Types: feat, fix, docs, style, refactor, test, chore
  - Keep the message under 72 characters
  - Generate only a single-line commit message (no multi-line messages)
4. Stage all changes with `git add -A`
5. Commit with the conventional commit message
6. Push to the remote branch. If the branch has no upstream, set it with `git push -u origin <branch>`