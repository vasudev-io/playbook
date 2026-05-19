---
name: audit
description: Audit the current branch against main like a staff/senior engineer, fanning out parallel subagents per concern (regressions/races, repo conventions, dead code, edge cases) and running a critic pass to cut false positives before reporting. Use whenever the user says "audit", "audit branch", "review my branch", "review the branch", "review this branch", "pre-flight", "pre-merge check", "check before merge", "what's risky in this branch", or asks for a senior-eng-style review of the current branch.
---

# Audit Branch vs main

A staff-engineer audit of the current branch vs `main`. Base is always `main` unless the user names another base.

The skill is an **orchestrator**: it gathers the diff, discovers the repo's own conventions, dispatches parallel subagents per concern, runs a critic pass to drop false positives, then writes the report. Do not try to do all concerns yourself in one pass — the subagents exist so each one has a clean context window and a narrow rubric.

## Step 1: Gather

Run in parallel, keep the output for later steps:

```bash
git rev-parse --abbrev-ref HEAD
git fetch origin main --quiet || true
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

Notes:
- Use the triple-dot form (`origin/main...HEAD`) — diff is from the merge-base, not from `main`'s tip.
- If `origin/main` doesn't exist, fall back to local `main`. If neither exists, stop and ask for the base.
- Read-only: this skill never pushes, force-pushes, resets, or rewrites refs.
- If `git diff` is huge (>2k changed lines or >40 files), don't paste the whole thing into subagent prompts — pass file paths + per-file diffs via `git diff origin/main...HEAD -- <path>` and let each subagent Read what it needs.

Identify the **deep-read set**: every changed file that isn't a lockfile, snapshot, generated artifact, fixture, or pure docs change. These are the files subagents must Read in full, not just skim from the diff.

## Step 2: Discover repo conventions

The conventions subagent (Subagent B) needs to know what *this* repo cares about. Before dispatching, collect convention sources by reading any of these that exist:

- `CLAUDE.md` (root + nested) — Claude Code instructions
- `AGENTS.md` / `GEMINI.md` — agent instructions
- `.cursor/rules/*.mdc` — Cursor rules (especially any with `alwaysApply: true`)
- `.github/copilot-instructions.md` — Copilot instructions
- `CONTRIBUTING.md`, `STYLE.md`, `docs/conventions.md` — style/contribution guides
- `.eslintrc*`, `.prettierrc*`, `tsconfig.json` — enforced via tooling but worth referencing

Extract a tight list of **enforceable rules** (naming conventions, banned imports, required patterns, async/error-handling rules, file-organization rules). Pass this list into Subagent B's prompt. If no convention sources exist, Subagent B falls back to language/framework defaults derived from package.json / detected stack.

## Step 3: Dispatch parallel subagents

Send a single message with **four `Agent` tool calls in parallel**, `subagent_type: "general-purpose"` for each. Each subagent gets:

- the branch name + commit list
- the full `git diff origin/main...HEAD` output (or per-file diffs if oversized)
- the deep-read file list
- its specific rubric (below)
- instruction to cite findings as `path:line` and return a tight bulleted list — no preamble, no summary

### Subagent A — Regressions, races, security

Rubric:
- Regressions: behavior changed without intent (removed null check, swapped operator, changed default, dropped error handler, sync↔async swap, removed cleanup in `useEffect` return, removed guard before a hook).
- Race conditions: shared mutable state without sync, missing `await`, `setState` after unmount, fire-and-forget promises that needed awaiting, IPC handlers mutating global state without locks, polling loops not cancelled on unmount.
- Security / data loss: dropped auth check, broadened query, deleted migration, swallowed transaction rollback, secrets in logs, unvalidated user input flowing to dangerous sinks (`eval`, `dangerouslySetInnerHTML`, shell exec, SQL).

### Subagent B — Repo conventions

Receives the extracted convention list from Step 2. Rubric:
- For each rule on the list, scan the diff for violations and cite `path:line`.
- Common categories worth checking even if rules aren't explicit: naming conventions (file/dir casing), banned imports (deprecated libraries, internal-only modules used externally), required patterns (error handling style, logging, telemetry), file-organization rules (where atoms/hooks/types live).
- Flag style drift only if a rule actually mandates it. Don't invent rules.
- If a rule is marked `alwaysApply: true` (Cursor rules), weight violations as Medium not Low.

### Subagent C — Dead code, ripe for removal

Rubric:
- Code paths made unreachable by this branch.
- Feature flags that are now permanently on/off.
- Helpers / components / exports with zero remaining callers — **verify with Grep across the repo** (exclude `node_modules`, `dist`, `build`, `*.test.*`, `*.spec.*`) before listing.
- Old implementation left next to its replacement.
- Removed-but-still-imported symbols (broken imports). Verify each removed export is no longer referenced.

For each finding, report the verified caller count (`0 callers`, `1 caller in path:line`).

### Subagent D — Edge cases & API contract drift

Rubric:
- Empty / null / undefined inputs, zero-length arrays, NaN, off-by-one, boundary conditions, timezone/DST, unicode, very large inputs.
- API contract changes not propagated to callers: renamed prop, changed return shape, new required param, narrowed/broadened type, changed enum value.
- Cross-process / cross-package payload shape changes without matching update on the other side (e.g. IPC main↔renderer, client↔server, app↔webview).
- Tests that pass but no longer assert what their name implies (e.g. test renamed but body unchanged, or assertion removed).

## Step 4: Oversized files (main thread)

Cheap, no subagent needed. For each file in the deep-read set, check post-change line count (`wc -l` or Read and count). Flag any **post-change** file > 1000 lines that this branch touched. For each, suggest one concrete seam to abstract ("split queue logic into its own module", "extract X reducer group"). Frame as: "easier to abstract now than after the next feature lands on top."

Threshold is a default — adjust if the repo's existing files are routinely large (e.g. raise to 1500 for repos where 1k-line files are normal).

## Step 5: Critic pass

Once all four subagents return, dispatch **one more `Agent` call** with:

- the merged findings list (with `path:line` citations)
- the full diff
- prompt: *"For each finding, decide: confirmed, false positive, or weak (citation doesn't support the claim or finding is too speculative). Return the trimmed list of confirmed findings only, preserving severity. Be ruthless — a senior reviewer who cries wolf gets ignored."*

The critic's output is the final findings list. Do not re-add findings the critic dropped unless you have a citation that disproves the drop.

## Step 6: Write the report

Reply in this exact structure. Omit any bucket with zero findings — do not write "None" sections.

```markdown
# Branch Audit: <current-branch> vs main

**Scope:** <N commits, M files changed, +X / -Y lines>

## High severity
- **<path:line>** — <one-line issue>. <Why it's wrong + concrete fix>.

## Medium severity
- **<path:line>** — <one-line issue>. <Why + fix>.

## Low severity (gotchas)
- **<path:line>** — <gotcha>. <What to be mindful of>.

## Convention violations
- **<path:line>** — <rule violated>. <One-line fix>.

## Deprecated / Ripe for removal
- **<path or symbol>** — <why it's now dead>. Verified <N callers> via grep.

## Oversized files (>1000 lines)
- **<path>** (<line count> lines, +<added this branch>) — <suggested seam>.

## Summary
<2–3 sentences: safe to merge / merge with fixes / do not merge. Name the top 1–2 risks the author should look at first.>
```

Severity mapping (subagent buckets → report buckets):
- A (regressions/races/security) → **High** for races/security/regressions; **Medium** for ambiguous behavior changes.
- B (conventions) → **Convention violations**. Promote to **Medium** if the violated rule is `alwaysApply` or causes a real bug, not just style drift.
- C (dead code) → **Deprecated / Ripe for removal**. Promote to **Medium** if it's a broken import (will fail typecheck/runtime).
- D (edge cases / contract drift) → **Medium** for contract drift breaking callers; **Low** for theoretical edge cases on internal-only code.

## Rules

- Every finding cites `path:line`. No filename-only hand-waving.
- Never flag what you can't point to in the diff or in a file a subagent Read.
- Don't propose refactors outside the diff except under **Deprecated** or **Oversized**.
- If the branch is clean, say so plainly in the Summary — do not pad buckets.
- Do not skip the critic pass. False positives are the fastest way to make this skill useless.
- This skill is read-only. No commits, pushes, resets, or branch mutations.
