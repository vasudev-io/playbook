---
name: publish-research
description: Use when you have just produced a design research bundle (HTML report + screenshots/references in a local folder) and need to host it on the user's public GitHub Pages so they can view it on the web. ALWAYS invoke at the end of any design research session — even if the user did not explicitly ask — and announce the resulting URL. Also triggers on "publish this research", "host this", "put this on the cloud", "share this report".
metadata:
  tags: design, research, publish, github-pages, hosting
---

## What this does

Publishes a local research folder to `https://<github_user>.github.io/<publish_repo>/<slug>/` so the user can view it on the web from any device. The `github_user` and `publish_repo` come from this plugin's `userConfig` (collected at install time).

## When to use

- **Always**, at the end of a research session that produced a local folder with an HTML report (commonly under `.lazyweb/design-research/...`, `.context/research/...`, or anywhere with a `report.html`).
- On explicit request: "publish this research", "host this", "put it on the cloud", "share this report".

Do not skip on the grounds that the research was "small" or "local-only". If a `report.html` exists, publish it.

## Slug convention

Slugs are kebab-case and describe **what was researched**, not when. Date lives inside the report, not the slug.

Good slugs: `blog-editorial-patterns`, `pricing-page-layouts`, `dashboard-empty-states`, `onboarding-flows-fintech`, `auth-modal-affordances`.

Bad slugs: `research-2026-05-11` (date-only), `blog-patterns-2026-05-11` (date suffix unless collision), `cursor-ramp-retool` (named after sources, not the topic).

If the local folder name is dated, **rename to a topic slug** before publishing.

## How to invoke

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/publish-research/publish.sh" <local-dir> <slug>
```

The script:
1. Clones `<github_user>/<publish_repo>` into the plugin's persistent data dir on first use.
2. Copies the local dir into `<repo>/<slug>/`.
3. Renames `report.html` → `index.html` so the URL goes directly to the report.
4. Regenerates the root `index.html` and `README.md` listing every published session, newest first.
5. Commits and pushes.
6. Enables GitHub Pages on first publish (idempotent).
7. Prints the public URL.

## After publishing

Print the public URL in one short line:

> Published → https://<github_user>.github.io/<publish_repo>/<slug>/

Pages can take **30-60s** on the very first deploy. Subsequent updates to existing slugs are live within ~20s.

## Collisions

If `<slug>` already exists in the repo, the script overwrites it (treating the new local dir as the updated version). To preserve both, append a version suffix: `blog-editorial-patterns-v2` or `blog-editorial-patterns-2026-08`.

## Edge cases

- **No `report.html`**: still publish, but `index.html` will be a directory listing. Warn the user.
- **No screenshots / references**: fine, the report alone is enough.
- **Sensitive content**: this repo is public by default. Check the report for client names, unreleased product details, NDAs, internal screenshots before pushing. If anything looks sensitive, ask the user. The script does NOT check — you do.

## Setup state

Configured automatically when `design-research-kit` is installed (which auto-creates the target repo and enables Pages). For standalone `publish-research` installs, the target repo must exist and have GitHub Pages enabled on `main` branch root — the script will create both if `gh` is authenticated and the repo doesn't yet exist.
