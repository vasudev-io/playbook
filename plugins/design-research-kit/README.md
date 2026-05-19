# design-research-kit

The full design research workflow in one install — Lazyweb research skills, the `publish-research` skill, and a one-shot setup script that creates and configures your GitHub Pages site.

## Install

In Claude Code:

```
/plugin marketplace add vasudev-io/playbook
/plugin install design-research-kit@playbook
```

This auto-installs:

- `lazyweb` — design research skills backed by a screenshot database ([upstream](https://github.com/aboul3ata/lazyweb-skill))
- `publish-research` — publishes reports to your GitHub Pages site

Claude Code will prompt for `github_user`, `publish_repo`, and `display_name` during install.

## After install

Run the setup skill once (your AI agent can invoke it for you):

```
design-research-setup
```

It checks `gh` auth, creates your `<user>/<repo>` repo if missing, enables GitHub Pages, seeds a landing page, and prompts for your Lazyweb token.

## Usage

After setup, ask your agent things like:

- "research how top apps handle dashboard empty states"
- "improve this design [screenshot]"
- "brainstorm fresh ideas for file uploaders"

The session produces a local folder with `report.html` and references, then `publish-research` ships it to `https://<user>.github.io/<repo>/<slug>/`.

## Manual one-time step

Lazyweb requires a free MCP token from their website — the setup skill prints the URL and the path to save the token at. We can't automate the token grab because lazyweb auths through a web form.
