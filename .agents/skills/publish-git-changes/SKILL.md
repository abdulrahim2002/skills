---
name: publish-git-changes
description: Git workflow for publishing code changes on a project repository. Use when creating branches, commits, or pull requests in this project.
---

# Publishing Git Changes

## Critical guardrail — `gh` permission

**Every `gh` command that mutates (create, merge, close, edit, label, assign,
etc.) MUST be confirmed by the user before running.** This is a hard rule, not
a guideline. The agent MUST present the exact command, explain what it does, and
wait for explicit approval. Never run a mutating `gh` command autonomously.

Read-only `gh` commands (`gh pr list`, `gh pr view`, `gh pr status`, `gh pr
diff`, `gh issue list`, `gh issue view`) are safe to run without confirmation.

## Setup

You need to check the default branch of the current repo; Always checkout from
default branch; for this skill, we assume the default branch is called `main`.

## Steps

### 1. Cut a feature branch from main
```bash
git checkout main
git pull
git checkout -b <type>/<short-description>
```

Pattern: `<type>/<short-description>` (kebab-case). Describe the work in
plain terms — never use AI/automation terminology (phase numbers, ticket
numbers, "agent-did", "ai-generated", etc.).

Examples: `feat/agent-stack-gateway-target`, `fix/webtext-scraper-timeout`,
`chore/bump-deps`.

Completion: branch exists, checked out, and `git log --oneline -1` shows the
tip matches main.

### 2. Stage and commit

One logical change per commit. If the diff covers two unrelated concerns
(e.g., a dependency bump and a separate bug fix), split them into separate
commits. A single concern may touch multiple files; a single file touched in
two unrelated ways means two commits.

Commit format — Conventional Commits, max 72-char header:

```
<type>(<scope>): <short description>

<optional body — blank line required above>
```

Types: `fix` · `feat` · `chore` · `docs` · `refactor` · `style` · `test` ·
`build` · `ci` · `security` · `release`. Scope is optional free text.

Branch names, commit messages, and PR titles must never contain AI or
automation jargon: no phase/ticket/iteration numbers, no "agent", "copilot",
"codex", "generated", or similar terms. Frame everything as if a human
engineer wrote it — describe the change, not the process that produced it.

Before committing:
- Inspect `git status` and `git diff --staged` to confirm only intended files
  are staged.
- One logical change per commit. Split unrelated changes into separate commits.
- Never commit secrets, env files, or credentials.
- Review every commit message for accidental AI terminology leaks.

Completion: commit created with intended files only, no secrets staged.

### 3. Push and open a PR

Push the branch first, then prepare the PR.

```bash
git push -u origin HEAD
```

**Then ask the user for permission before running `gh pr create`.** Present the
full command with title and body for approval.

PR body follows `.github/pull_request_template.md`:

```
gh pr create \
  --title "fix: short description" \
  --base main \
  --body "$(cat <<'EOF'
## What changed?

...

## Why?

...

## How was this tested?

...

## Deployment / infra impact

...

Signed-off-by: GitHub Copilot (AI agent)
EOF
)"
```

## Reference

### Branch rules

- Always cut from `main`, never from another feature branch.
- Never force-push a branch that has an open PR. Open a new branch instead.
- Keep branches focused: one feature or fix per branch.

### PR body sign-off

Every PR body must end with a sign-off identifying the agent:

```
Signed-off-by: <agent-name> (AI agent)
```

If the agent name is unknown: `Signed-off-by: AI agent (non-human)`.

### Sequence — branches that gate

When a PR is open and further changes are needed, the next logical commit on
the same branch is gated by the open PR — do not push to it without user
direction. Ask first.
