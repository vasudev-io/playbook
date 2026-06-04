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

## Audit your branch like a staff engineer

```
/plugin install branch-audit@playbook
```

A pre-merge audit of the current branch vs `main`. Instead of a single-pass review, it fans out **parallel subagents** per concern (regressions/races, repo conventions, dead code, edge cases), discovers your repo's own rules from `CLAUDE.md` / `AGENTS.md` / `.cursor/rules/*`, then runs a **critic pass** to drop false positives before reporting. Triggers on `/audit`, "review my branch", "pre-flight check", etc. Read-only.

## Animation & motion craft

```
/plugin install motion-craft@playbook
```

Emil Kowalski's design-engineering skill (author of Sonner and Vaul, design
engineer at Linear) for building and reviewing UI motion: the animation decision
framework, custom easing curves, springs, component patterns, clip-path, gesture
physics, performance, and a Before/After review rubric. **Not mine.** Bundled here
verbatim with credit (the only change is added trigger keywords so it activates
reliably), the same way `lazyweb` is bundled. Canonical source:
`npx skills add emilkowalski/skill` and [animations.dev](https://animations.dev).
Triggers on "animation", "motion", "easing", "make it feel nicer", etc.

## What's inside

```
.
├── AGENTS.md                 ← imperative install script for AI agents
├── .claude-plugin/
│   └── marketplace.json      ← marketplace manifest (5 plugins)
├── plugins/
│   ├── publish-research/     ← my publish skill (standalone-usable)
│   ├── branch-audit/         ← staff-engineer branch audit (standalone-usable)
│   ├── design-research-kit/  ← metapackage + setup skill
│   └── motion-craft/         ← Emil Kowalski's motion skill, bundled with credit
└── guides/                   ← long-form workflow guides
```

## For agents

If you're an AI agent reading this repo to figure out what to do for a user, jump straight to [AGENTS.md](./AGENTS.md). It has imperative install steps.

## Credits

- **lazyweb plugin** is by [aboul3ata/lazyweb-skill](https://github.com/aboul3ata/lazyweb-skill) — bundled here via `git-subdir` for one-command install convenience. All credit to them.
- **motion-craft plugin** is [Emil Kowalski's](https://github.com/emilkowalski/skill) design-engineering skill, bundled verbatim with credit. Install the canonical version with `npx skills add emilkowalski/skill`, take his course at [animations.dev](https://animations.dev), and read his essays at [emilkowal.ski/ui](https://emilkowal.ski/ui). All credit to him.
- Inspired by the [Anthropic claude-plugins-official](https://github.com/anthropics/claude-plugins-official) marketplace structure.

## License

MIT for the bits I wrote (publish-research, design-research-kit, the guides). Lazyweb's and Emil's plugins retain their own rights; they are bundled here with credit.
