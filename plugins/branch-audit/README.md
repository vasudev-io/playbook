# branch-audit

A staff-engineer audit of your current branch vs `main`. Instead of one model trying to spot everything in a single pass, this skill fans out **parallel subagents** — one per concern — and runs a **critic pass** to drop false positives before reporting.

## Install

In Claude Code:

```
/plugin marketplace add vasudev-io/playbook
/plugin install branch-audit@playbook
```

No configuration required.

## Use it

Trigger by typing `/audit`, or naturally:

- "audit my branch"
- "review the branch"
- "pre-flight check before merge"
- "what's risky in this branch"

The skill runs against the current branch vs `origin/main` (triple-dot diff from merge-base).

## What it does

1. **Gather** — `git diff origin/main...HEAD`, commit list, deep-read file set (skips lockfiles, snapshots, generated code).
2. **Discover repo conventions** — reads `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/*`, `.github/copilot-instructions.md`, contributing guides. Extracts an enforceable rule list specific to *this* repo.
3. **Dispatch 4 parallel subagents** — each with a clean context window and a narrow rubric:
   - **A** — regressions, races, security
   - **B** — repo conventions (using the rules discovered in step 2)
   - **C** — dead code & ripe-for-removal (with grep-verified caller counts)
   - **D** — edge cases & API contract drift
4. **Oversized files** — flag any file > 1000 lines this branch touched, with a concrete suggested seam.
5. **Critic pass** — one more agent ruthlessly drops false positives and weakly-cited findings before they reach the report.
6. **Report** — structured markdown with `path:line` citations in each bucket.

## Why parallel subagents

Single-pass audits hit two ceilings:

- **Context exhaustion** on big PRs — one model trying to hold the full diff + read every file + remember every convention + bucket findings.
- **Recall drops** when one prompt asks for 5 different concerns at once — the model fixates on the easiest two and skims the rest.

Fanning out gives each subagent ~the full context window for one narrow job. The critic pass then exists because parallel subagents over-report — many small findings are stylistic noise or speculative. The critic cuts them so the final list is short, sharp, and worth reading.

## Read-only

The skill never pushes, force-pushes, resets, or rewrites refs. It only runs `git diff`, `git log`, `git fetch --quiet`, and read tools.

## Requirements

- `git` available
- The branch has a base commit reachable from `origin/main` (or local `main` as fallback)
