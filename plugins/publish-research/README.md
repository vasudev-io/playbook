# publish-research

Publish a local research folder (containing a `report.html`) to your own GitHub Pages site. Auto-generates a landing index that lists every published session.

## Install

In Claude Code:

```
/plugin marketplace add vasudev-io/playbook
/plugin install publish-research@playbook
```

Claude Code will prompt for:

- `github_user` — your GitHub username (e.g. `octocat`)
- `publish_repo` — the repo name for hosting reports (default: `design-research`)
- `display_name` — name shown on the landing page (default: your GitHub username)

The plugin then publishes to `https://<github_user>.github.io/<publish_repo>/<slug>/` each time you invoke it.

## What it does

When a session produces a folder with a `report.html` (and optionally `report.md`, `references/`, etc.), this skill:

1. Clones (or auto-creates) `<github_user>/<publish_repo>` into the plugin's persistent data dir
2. Copies your local folder into `<repo>/<slug>/`
3. Renames `report.html` → `index.html` so the URL goes straight to the report
4. Regenerates the root `index.html` (designed landing page with Inter, listing all sessions newest-first)
5. Commits + pushes
6. Enables GitHub Pages on first publish

## Requirements

- `gh` CLI authenticated (`gh auth login`)
- `git` available
- `python3` available (used to template the landing page)
- A public GitHub repo named `<publish_repo>` you own — created automatically if missing

## Want the full design-research workflow?

Install `design-research-kit` instead — it bundles this plugin, the Lazyweb research skills, and a one-shot setup script that auto-creates and configures your Pages site.

```
/plugin install design-research-kit@playbook
```
