# Design research, on autopilot, inside Claude Code

A walkthrough of how I run design research inside [Claude Code](https://claude.com/claude-code) — a workflow that takes a one-line question ("how do top apps handle X?") and produces a structured report with **real screenshots from a curated app database, live web captures of competitor sites, an ASCII wireframe of the recommendation, and a one-click public URL** to share the report.

It's the workflow that produced [this research on queued messages in LLM chat apps](https://vasudev-io.github.io/design-research/queued-messages-llm-chat/) (sample output).

Everything below is reproducible on your own machine in about 10 minutes.

---

## What you get

Six skills that compose into one fluent workflow:

| Skill | What it does | Typical trigger |
|---|---|---|
| `lazyweb-design-research` | Deep research with screenshots. Produces `report.md`, `report.html`, and a `references/` folder of downloaded examples. | "research how top apps handle empty states" |
| `lazyweb-quick-references` | Faster, lighter version — just downloads a batch of screenshots without a full report. | "show me examples of pricing pages" |
| `lazyweb-design-improve` | Captures your current design, finds similar references, generates concrete improvement ideas. | "improve this design", "critique this" |
| `lazyweb-design-brainstorm` | Cross-pollination — deliberately searches *outside* your category to find novel patterns. | "brainstorm fresh ideas for X" |
| `lazyweb-add-inspo-source` / `lazyweb-remove-inspo-source` | Connect external sources (Mobbin, Savee, Dribbble, Behance) via headless-browser auth so they show up in research alongside the built-in database. | "add Mobbin as an inspo source" |
| `publish-research` | One-shot: pushes the local research folder to GitHub Pages and prints a public URL. | Runs automatically at the end of a research session, or "publish this" |

The reports look like [this](https://vasudev-io.github.io/design-research/queued-messages-llm-chat/) — TL;DR, recommendations with ASCII wireframes, a screenshot gallery with attribution, patterns, anti-patterns, "unique angles," and sources.

---

## How a session feels

```
me:  do design research on chat message queuing
     this is my current design [screenshot]

claude: [searches the Lazyweb database with 6 different query angles]
        [downloads 12 strong references that actually match the topic]
        [grounds the report against your current design]
        [writes report.md + report.html + ASCII mockups]
        [auto-publishes to GitHub Pages]
        Published → https://vasudev-io.github.io/design-research/chat-message-queuing/
```

That's it. No tab-switching, no manual screenshot wrangling, no decks. You read the report, decide what to ship, move on.

---

## Prerequisites

1. **Claude Code installed.** Mac / Windows desktop app or the CLI. ([install](https://claude.com/claude-code))
2. **A GitHub account** — needed only if you want one-click publishing.
3. **`gh` CLI authenticated** (`gh auth login`) for the publish step.
4. **Node.js** — `npx` is used by the Lazyweb MCP.

---

## Install

### 1. Lazyweb skills + MCP

The six `lazyweb-*` skills ship as a Claude Code plugin. Free; the MCP server is hosted at `lazyweb.com/mcp`.

Setup instructions (with token): **https://www.lazyweb.com/mcp-install**

In short, you'll:
- Install the Lazyweb plugin in Claude Code
- Drop your token at `~/.lazyweb/lazyweb_mcp_token`
- Restart Claude Code

Verify with: ask Claude "is lazyweb MCP working?" — it'll call `lazyweb_health` and report `ok`.

### 2. (Optional) Inspo sources

If you have Mobbin / Savee / Dribbble / Behance accounts, connect them once:

```
"add Mobbin as an inspo source"
```

Claude opens a headless browser, you sign in, the session cookies are stored locally, and that source is auto-queried in every future research session.

### 3. The `publish-research` skill

This is a one-file skill in `~/.claude/skills/publish-research/`. It pushes a local research folder to your **own** `<you>/design-research` GitHub repo with Pages enabled, so the report is viewable at `https://<you>.github.io/design-research/<slug>/`.

Setup:

```bash
mkdir -p ~/.claude/skills/publish-research
mkdir -p ~/.claude/cache/design-research

# Clone your own design-research repo (create it on GitHub first if needed)
cd ~/.claude/cache
gh repo clone <you>/design-research
```

Then create `~/.claude/skills/publish-research/SKILL.md`:

```markdown
---
name: publish-research
description: Use when you have just produced a design research bundle (HTML report + screenshots in a local folder) and need to host it on the user's public GitHub Pages so they can view it on the web. ALWAYS invoke at the end of any design research session — even if the user did not explicitly ask — and announce the resulting URL. Also triggers on "publish this research", "host this", "put this on the cloud", "share this report".
---

## What this does

Publishes a local research folder to `https://<you>.github.io/design-research/<slug>/`.

## How to invoke

Run: `~/.claude/skills/publish-research/publish.sh <local-dir> <slug>`

The script:
1. Pulls the latest from `~/.claude/cache/design-research`
2. Copies the local dir into `~/.claude/cache/design-research/<slug>/`
3. Renames `report.html` → `index.html`
4. Regenerates the root `index.html` listing every published session, newest first
5. Commits and pushes
6. Prints the public URL
```

And the publish script — `~/.claude/skills/publish-research/publish.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOCAL_DIR="${1:?usage: publish.sh <local-dir> <slug>}"
SLUG="${2:?usage: publish.sh <local-dir> <slug>}"
REPO_DIR="$HOME/.claude/cache/design-research"

cd "$REPO_DIR"
git pull --rebase --autostash

mkdir -p "$SLUG"
rsync -a --delete "$LOCAL_DIR"/ "$SLUG"/
[ -f "$SLUG/report.html" ] && mv "$SLUG/report.html" "$SLUG/index.html"

# Regenerate root index (newest first)
{
  echo '<!doctype html><meta charset=utf-8><title>Design Research</title>'
  echo '<style>body{font:16px -apple-system,system-ui;max-width:720px;margin:48px auto;padding:0 24px}h1{margin:0 0 24px}a{color:#2563eb;text-decoration:none}a:hover{text-decoration:underline}li{margin:6px 0}</style>'
  echo '<h1>Design research</h1><ul>'
  for d in $(ls -td */ 2>/dev/null); do
    name="${d%/}"
    echo "<li><a href=\"$name/\">$name</a></li>"
  done
  echo '</ul>'
} > index.html

git add -A
git commit -m "publish: $SLUG" || true
git push

GH_USER="$(gh api user --jq .login)"
echo "Published → https://$GH_USER.github.io/design-research/$SLUG/"
```

Make it executable: `chmod +x ~/.claude/skills/publish-research/publish.sh`

Enable GitHub Pages on the repo once (Settings → Pages → main branch, / root) or via `gh api`:

```bash
gh api -X POST "/repos/<you>/design-research/pages" \
  -f source[branch]=main -f source[path]=/
```

---

## Usage

Just talk to Claude:

```
"do design research on dashboard empty states"
"how do top apps handle login error states?"
"research onboarding flows for fintech apps"
"improve this design [screenshot]"
"brainstorm unconventional approaches to file uploaders"
```

Output lives in your current workspace at:

```
.lazyweb/design-research/<topic>-<date>/
├── report.md
├── report.html
└── references/
    ├── stripe-pricing.png
    ├── linear-onboarding.png
    └── …
```

`publish-research` then mirrors that folder to your GitHub Pages repo and prints the URL.

---

## Customization

**Use a different publish target.** Change the repo path in `publish.sh`. Could be a private repo, a different account, an internal mirror.

**Skip publishing.** Tell Claude "don't publish this one." Or remove `publish-research` from `~/.claude/skills/`.

**Tighter screenshots.** The research skill caps at 30 images and explicitly filters using each screenshot's `visionDescription` field — references are only attached if they actually match the point being made. If you want fewer / more strict, edit `~/.claude/plugins/cache/lazyweb/lazyweb/<version>/skills/lazyweb-design-research/SKILL.md`.

**More inspo sources.** `add-inspo-source` works with any site where login is via a normal web form. Cookies persist in `~/.lazyweb/`.

---

## Limitations + notes

- **Lazyweb is a hosted database.** Searches go out to `lazyweb.com/mcp`. Free, but not offline.
- **GitHub Pages is public by default.** If your research includes proprietary screenshots, use a private repo and skip the publish step.
- **The `publish-research` skill in this repo is forked from mine** — yours will publish to your own repo, not mine. Set the path explicitly.
- **The browse tool (used for live web screenshots)** is optional. Reports still work without it; you just get database screenshots, no live captures. Setup: `~/.claude/skills/lazyweb-skill/browse/setup` if your install includes it.

---

## Why this composition

The hard part of design research isn't the writing — it's the *evidence*. The reason this workflow is fast is because:

1. **The screenshot database has been vision-captioned**, so the skill can match references to the actual point being made (no "here's a vaguely related screenshot")
2. **Live web captures fill the freshness gap** — competitor sites change fast, the database is curated
3. **The report format is opinionated** (TL;DR → recommendations → ASCII mockup → gallery → patterns → anti-patterns → unique angles → findings → sources) so every report has the same shape, which makes them easy to skim later
4. **Auto-publish removes the "I'll share it tomorrow" failure mode** — by the time you finish reading, the URL is already in clipboard distance

That's the whole pitch. Try it on a real design question you have today.

---

## Credits

- **Lazyweb skills + MCP**: [lazyweb.com](https://lazyweb.com/) — [aboul3ata/lazyweb-skill](https://github.com/aboul3ata/lazyweb-skill)
- **Claude Code**: [claude.com/claude-code](https://claude.com/claude-code)
- **`publish-research`** is a personal skill — the version above is what I run; yours should point at your own repo.

License: MIT for the contents of this guide.
