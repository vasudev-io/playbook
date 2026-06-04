---
name: vasudev-motion
description: >-
  Vasudev's personal motion taste, layered on top of the emil-design-eng skill.
  Use alongside it on any animation/motion work: it sets house defaults and
  overrides (when they conflict, this wins). Triggers on the same requests as
  emil-design-eng: "animation", "motion", "transition", "easing", "spring",
  "reveal", "make it feel nicer".
---

# Vasudev's motion layer

Personal taste on top of `emil-design-eng` (the canon). Apply both; when they
conflict, this wins. Edit freely. Lines marked (infer) are guessed from the site
rather than stated rules: confirm or change them.

## Principles

- **Reveals over spectacles.** A typewriter on a name is a spectacle and it dates.
  Prefer a fast mask-reveal or fade+rise that happens once and disappears. Motion
  supports the story, it does not perform.
- **Calm, considered, exact.** Fewer animations, better chosen. Strong hierarchy and
  restraint over flash. In doubt, remove it.
- **Orchestrate, do not pile up.** One sequenced entrance beats two competing ones.
- **Heavy intros wake only when fully in view**, never on load (cover reels, hero
  motion gate on `useInView({ once: true })`). (infer, from the site's cover reel.)
- **Momentum with hard cuts.** U-curve timing on signature bursts: accelerate in,
  decisive cut out. No mushy linear fades on hero moments. (infer.)
- **No em-dashes in microcopy.** Tooltips, toasts, labels use colons/commas/periods.

## Stack

- Motion (Framer Motion) + React 19 + Vite.
- Custom cursor that morphs into affordances (view/close pill over cards).
- Mind Emil's hardware-accel caveat: prefer CSS/`transform` strings over Motion
  `x`/`y` for motion that runs during page loads.

## Defaults (edit to taste)

- Entrances: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`.
- Sheets/drawers: iOS curve `cubic-bezier(0.32, 0.72, 0, 1)`.
- Anything draggable: spring, subtle bounce (0.1 to 0.2).
- TODO (Vasudev): pin your signature durations, your go-to spring config, and the
  exact card-expand + cursor-morph timings so they are enforced, not guessed.
