# playbook

My hub of Claude Code skills, plugins, and guides. Public so others can install the bits they like.

## One-command install (Claude Code)

```
/plugin marketplace add vasudev-io/playbook
/plugin install design-research-kit@playbook
```

That bundles three plugins:

| plugin | what it does | author |
|---|---|---|
| `lazyweb` | design research skills backed by a curated screenshot database | [Lazyweb](https://github.com/aboul3ata/lazyweb-skill) (not me — bundled here for convenience) |
| `publish-research` | publishes a local research folder to your own GitHub Pages | me |
| `design-research-kit` | metapackage + auto-setup script that wires everything up | me |

After install, run the setup skill once. It creates your `<user>/design-research` repo, enables GitHub Pages, and seeds a landing page.

```
design-research-setup
```

The only remaining manual step is grabbing a free Lazyweb MCP token from [their site](https://www.lazyweb.com/mcp-install) — the setup skill prints the URL and the path to save it at.

## Want just the publish capability?

```
/plugin install publish-research@playbook
```

Standalone — useful if you want to publish any `report.html` to your own Pages site, no Lazyweb required.

## What's inside

```
.
├── AGENTS.md                 ← imperative install script for AI agents
├── .claude-plugin/
│   └── marketplace.json      ← marketplace manifest (3 plugins)
├── plugins/
│   ├── publish-research/     ← my publish skill (standalone-usable)
│   └── design-research-kit/  ← metapackage + setup skill
└── guides/                   ← long-form workflow guides
```

## For agents

If you're an AI agent reading this repo to figure out what to do for a user, jump straight to [AGENTS.md](./AGENTS.md). It has imperative install steps.

## Credits

- **lazyweb plugin** is by [aboul3ata/lazyweb-skill](https://github.com/aboul3ata/lazyweb-skill) — bundled here via `git-subdir` for one-command install convenience. All credit to them.
- Inspired by the [Anthropic claude-plugins-official](https://github.com/anthropics/claude-plugins-official) marketplace structure.

## License

MIT for the bits I wrote (publish-research, design-research-kit, the guides). Lazyweb's plugin retains its own MIT license.
