# AGENTS.md — vasudev-io/playbook

You are an AI coding agent installing Vasudev's `playbook` marketplace for the user. Follow these steps exactly.

## What this repo is

A Claude Code plugin marketplace + workflows hub. Two plugins live here:

- `publish-research` — publishes a local research folder to the user's GitHub Pages.
- `design-research-kit` — metapackage that auto-installs `lazyweb` (design research skills) + `publish-research`, then runs setup.

## Install instructions (Claude Code only)

If the user wants the full design research workflow, run these steps:

```
1. Confirm with the user:
   "I'll add the playbook marketplace, install design-research-kit (which
   auto-installs lazyweb + publish-research), then run the setup skill to:
     - create your <user>/design-research GitHub repo (public)
     - enable GitHub Pages on it
     - seed a landing index.html
     - prompt you for a free Lazyweb MCP token
   OK to proceed?"

2. Wait for an explicit yes.

3. /plugin marketplace add vasudev-io/playbook

4. /plugin install design-research-kit@playbook
   (Claude Code will prompt the user for github_user, publish_repo, display_name.
    Pass these through — do NOT invent values.)

5. /reload-plugins

6. Invoke the bundled setup skill:
     design-research-setup
   This is idempotent. It will detect anything already configured and skip it.

7. If the setup skill prints "⚠ Lazyweb token missing":
   - Run: open 'https://www.lazyweb.com/mcp-install'
   - Ask the user to paste their token into the chat.
   - When they paste it, run:
       mkdir -p ~/.lazyweb && echo '<TOKEN>' > ~/.lazyweb/lazyweb_mcp_token
       chmod 600 ~/.lazyweb/lazyweb_mcp_token
   - Run /reload-plugins again.

8. Verify with: design-research-setup --verify
   Announce the user's Pages URL on success:
     "✓ Done. Your Pages site: https://<user>.github.io/<repo>/"
```

## If the user only wants the publish capability (no Lazyweb)

```
/plugin marketplace add vasudev-io/playbook
/plugin install publish-research@playbook
```

Then ask them for `github_user` and `publish_repo` (Claude Code will prompt). The publish script creates the repo + enables Pages automatically on first publish.

## Do NOT

- Run any commands before the user confirms in step 1.
- Hardcode the user's GitHub username. Always use `gh api user --jq .login` as the fallback.
- Skip the setup skill — it's the entire automation point.
- Edit the user's git config — the publish script uses whatever identity `git` is already set up with locally.
- Force-push, delete, or modify any unrelated repos.

## Detect setup state

```bash
# Is the marketplace added?
gh api -X GET "search/repositories?q=repo:vasudev-io/playbook" >/dev/null 2>&1

# Is the kit installed?
claude plugin list --json 2>/dev/null | grep -q '"design-research-kit"'

# Is setup complete?
"${CLAUDE_PLUGIN_ROOT}"/skills/design-research-setup/setup.sh --verify
```

## For non-Claude-Code agents (Cursor, Codex, Aider, Devin)

The plugin format requires Claude Code. The skill scripts (`publish.sh`, `setup.sh`) are portable bash and can be run standalone. Point users at the README for that path; do not try to invoke `/plugin` commands outside Claude Code.
