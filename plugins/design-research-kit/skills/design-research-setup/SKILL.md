---
name: design-research-setup
description: Use immediately after installing the design-research-kit plugin to finish setup. Verifies gh auth, auto-creates the user's publish repo with GitHub Pages enabled, seeds an initial index.html, and walks the user through getting their Lazyweb MCP token. Idempotent — safe to re-run. Also triggers on "set up design research", "finish design research setup", "verify design research".
metadata:
  tags: setup, design, research, github-pages, lazyweb
---

## When to invoke

- **Immediately after** `/plugin install design-research-kit@playbook` completes.
- On the user's request: "set up design research", "finish setup", "verify my setup".
- After running `/reload-plugins` (to pick up changes since last verify).

## What it does

Runs the setup script which performs these steps idempotently:

1. **gh auth check** — fails fast with `gh auth login` instructions if not authenticated.
2. **Resolves github_user + publish_repo** — from `publish-research`'s userConfig env vars, or from `gh api user` as fallback.
3. **Repo creation** — if `<user>/<repo>` doesn't exist, creates it (public, with description).
4. **GitHub Pages enable** — POSTs to `/repos/<user>/<repo>/pages` if Pages is off.
5. **Seed `index.html`** — if the repo is empty, clones, pushes a minimal "no research published yet" landing page.
6. **Lazyweb token check** — verifies `~/.lazyweb/lazyweb_mcp_token` exists; if not, prints the URL and the path to save the token at.
7. **Writes a status report** to stdout summarizing what's set up and what (if anything) the user still needs to do.

## How to invoke

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/design-research-setup/setup.sh"
```

To verify-only (no writes, just status):

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/design-research-setup/setup.sh" --verify
```

## Safety

- Confirms with the user before any GitHub write (repo create, Pages enable, initial push).
- Never force-pushes, never deletes.
- Only writes to repos owned by the authenticated `gh` user.
- The lazyweb token file is created with mode 600 if the user pastes their token.

## After it finishes

If everything is green, tell the user one line: their Pages URL. Example:

> ✓ Setup complete. Your Pages site: https://<user>.github.io/<repo>/

If something is missing (typically the Lazyweb token), point them at `https://www.lazyweb.com/mcp-install` and offer to write the token to `~/.lazyweb/lazyweb_mcp_token` if they paste it.
