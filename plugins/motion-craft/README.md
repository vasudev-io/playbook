# motion-craft

A Claude Code skill for building and reviewing UI motion that feels right:
easing, duration, springs, component patterns, clip-path, gesture/drag,
performance, accessibility, and a review rubric.

## Credit

The foundation is **Emil Kowalski's** design-engineering work (author of
[Sonner](https://sonner.emilkowal.ski) and [Vaul](https://vaul.emilkowal.ski),
design engineer at Linear). The skill restates his principles in original wording
and adds my own taste layer on top. It does not copy his files.

For the canonical source, go straight to Emil:

- Official skill: `npx skills add emilkowalski/skill` ([repo](https://github.com/emilkowalski/skill))
- Course: [animations.dev](https://animations.dev)
- Essays: [emilkowal.ski/ui](https://emilkowal.ski/ui)

## Install

```
/plugin marketplace add vasudev-io/playbook
/plugin install motion-craft
```

## Use

Ask for animation help, or audit existing motion:

> use the motion-craft skill to audit and improve my frontend animations

The skill auto-triggers on animation, motion, transition, easing, spring, and
"make it feel nice" requests.
