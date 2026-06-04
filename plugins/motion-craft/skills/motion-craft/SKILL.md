---
name: motion-craft
description: >-
  Web animation and motion craft for interfaces that feel right. Foundation is
  Emil Kowalski's design-engineering philosophy (author of Sonner and Vaul,
  design engineer at Linear), synthesized in original wording and credited;
  extended with Vasudev Menon's own taste layer. Use whenever building,
  reviewing, or improving UI motion: transitions, hover/tap feedback, modals,
  drawers, dropdowns, toasts, tabs, reveals, drag/gesture, stagger, or any
  "make this feel better / smoother / more alive / add a reveal" request.
  Triggers on "animation", "motion", "transition", "easing", "spring",
  "make it feel nice", "audit my animations".
---

# Motion craft

Build interfaces where motion is felt, not noticed. Most animation should be
invisible: it confirms a state change, shows where something came from, or gives
tactile feedback, then gets out of the way. If an animation only exists to look
cool and users will see it often, cut it. Be strict with these rules; improvise
only when one clearly does not apply.

> **Credit.** The foundation here is Emil Kowalski's published work and his
> *Animations on the Web* course. This skill restates the principles in original
> wording and adds Vasudev's layer. For the canonical source, install Emil's own
> skill (`npx skills add emilkowalski/skill`) and take the course at
> [animations.dev](https://animations.dev). Read his essays at
> [emilkowal.ski/ui](https://emilkowal.ski/ui).

## Review format (required)

When reviewing motion code, output a single markdown table, one row per issue:

| Before | After | Why |
| --- | --- | --- |
| `transition: all 300ms` | `transition: transform 200ms ease-out` | name exact properties, never `all` |
| `transform: scale(0)` | `transform: scale(0.95); opacity: 0` | nothing real appears from nothing |
| `ease-in` on a dropdown | `ease-out` (or a custom curve) | `ease-in` delays the moment the user is watching |
| no `:active` on a button | `transform: scale(0.97)` on `:active` | presses must feel heard |
| `transform-origin: center` on a popover | origin at the trigger | popovers scale from their trigger (modals stay centered) |

Do not write "Before:" / "After:" as separate lines. Always a real table.

## The animation decision framework

Answer in order, before writing any motion code.

### 1. Should it animate at all? (frequency gate)

| How often a user sees it | Decision |
| --- | --- |
| 100+ times/day (shortcuts, command palette) | no animation, ever |
| Tens of times/day (hover, list nav) | remove or drastically reduce |
| Occasional (modals, drawers, toasts) | standard animation |
| Rare / first-time (onboarding, celebration) | room for delight |

**Never animate keyboard-initiated, repeated actions.** They fire hundreds of
times a day; motion makes them feel slow and disconnected. Raycast has no
open/close animation, and that is correct for something opened constantly.

### 2. What is the purpose?

Every animation needs a clear answer to "why does this move?" Valid reasons:
spatial consistency (enters and exits the same edge, so swipe-to-dismiss makes
sense), state indication, explanation, feedback (press confirms the tap landed),
or preventing a jarring pop-in. "It looks cool" on a high-frequency element is not
a reason.

### 3. Which easing?

```
entering or exiting the viewport?      -> ease-out (fast start, feels responsive)
moving / morphing while on screen?     -> ease-in-out
hover / color change?                  -> ease
constant motion (marquee, progress)?   -> linear
default                                -> ease-out
```

- **Never use `ease-in` on UI.** It starts slow, so the interface feels sluggish
  at the exact instant the user is watching most. `ease-out` at 200ms feels faster
  than `ease-in` at 200ms.
- **The built-in curves are weak. Use stronger custom ones.** Common strong values:

```css
--ease-out: cubic-bezier(0.23, 1, 0.32, 1);       /* strong ease-out for UI */
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);   /* on-screen movement */
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);    /* iOS-like drawer */
```

  Do not hand-roll curves. Pull stronger variants from easing.dev or easings.co.

### 4. How fast?

| Element | Duration |
| --- | --- |
| Button press feedback | 100 to 160ms |
| Tooltips, small popovers | 125 to 200ms |
| Dropdowns, selects | 150 to 250ms |
| Modals, drawers | 200 to 500ms |
| Marketing / explanatory | longer is allowed |

- **Keep UI under 300ms.** A 180ms dropdown beats a 400ms one.
- **Exit faster than enter** (a hold-to-delete can take 2s, but release snaps back
  in ~200ms). Slow where the user is deciding, fast where the system responds.
- Perceived speed is real: a faster spinner makes loading *feel* faster; instant
  tooltips after the first one make a whole toolbar feel quick.

## Springs

Springs simulate physics, so they feel alive and they keep velocity when
interrupted (CSS keyframes restart from zero). Use them for drag with momentum,
interruptible gestures, and decorative mouse-tracking. Avoid them for precise
functional readouts (a banking chart wants no animation at all).

```js
// Apple-style config (easier to reason about)
{ type: "spring", duration: 0.5, bounce: 0.2 }
// Traditional physics (more control)
{ type: "spring", mass: 1, stiffness: 100, damping: 10 }
```

Keep bounce subtle (0.1 to 0.3) and mostly reserve it for playful, drag-style
interactions. Tie mouse-driven decoration to a spring (`useSpring` in Motion) so
it has momentum instead of snapping to the pointer.

## Component principles

- **Buttons: `scale(0.97)` on `:active`** with `transition: transform 160ms ease-out`.
  Subtle (0.95 to 0.98). Applies to any pressable element.
- **Never enter from `scale(0)`.** Start at `scale(0.95)` (or higher) plus
  `opacity: 0`. Even a deflated balloon has a shape.
- **Popovers are origin-aware**: `transform-origin` at the trigger (Radix exposes
  `--radix-popover-content-transform-origin`). Modals are the exception and stay
  centered.
- **Tooltips skip the delay after the first one.** Initial tooltip delays to avoid
  accidental triggers; once one is open, adjacent ones open instantly with no
  animation (`transition-duration: 0ms`).
- **Transitions over keyframes for anything interruptible.** Transitions retarget
  mid-flight; keyframes restart. Toasts, toggles, rapidly-triggered state all want
  transitions.
- **Mask a rough crossfade with `filter: blur(2px)`** during the transition. It
  blends two overlapping states into one perceived object. Keep blur under 20px
  (heavy blur is expensive, especially in Safari).
- **Enter with `@starting-style`** instead of a `useEffect(() => setMounted(true))`
  hack, where browser support allows:

```css
.toast {
  opacity: 1; transform: translateY(0);
  transition: opacity 400ms ease, transform 400ms ease;
  @starting-style { opacity: 0; transform: translateY(100%); }
}
```

## CSS transforms

- **Percentage translates** are relative to the element's own size:
  `translateY(100%)` moves it exactly one height, at any size. This is how Sonner
  positions toasts and Vaul hides the drawer. Prefer percentages over hardcoded px.
- **`scale()` scales children too** (font, icons, content): a feature when
  scaling a button on press.
- **3D**: `rotateX/Y` with `transform-style: preserve-3d` for coin-flips, orbits,
  depth, no JS needed.
- **`transform-origin`** sets the anchor; default center is wrong for most popovers.

## clip-path

Hardware-accelerated, no layout shift (content is there, just clipped).
`inset(top right bottom left)` eats in from each side; all 100% hides everything.

- **Reveal**: `inset(0 0 100% 0)` to `inset(0 0 0 0)`, great on scroll with
  `useInView({ once: true, margin: "-100px" })`.
- **Tabs with perfect color transitions**: duplicate the list, style the copy as
  active, clip to show only the active tab, animate the clip on change. Beats
  timing individual color transitions.
- **Comparison sliders**: overlay two images, drive `inset` right value from drag.
- **Hold-to-delete**: colored overlay `inset(0 100% 0 0)` to `inset(0 0 0 0)` over
  2s linear on `:active`, snap back 200ms ease-out on release.

## Gesture and drag

- **Momentum dismiss**: do not require a distance threshold alone. Compute
  `velocity = Math.abs(distance) / elapsedMs`; dismiss if `velocity > ~0.11`. A
  flick is enough.
- **Damping past boundaries**: the further they overdrag, the less it moves.
  Real things slow before they stop; never hit an invisible wall.
- **Pointer capture** once dragging starts, so it continues outside the element.
- **Ignore extra touch points** after the drag begins, or switching fingers makes
  the element jump.

## Performance

- **Animate only `transform` and `opacity`** (composite step, GPU). `width`,
  `height`, `margin`, `padding`, `top`, `left` trigger layout and paint, which is
  what drops frames.
- **Do not animate an inherited CSS variable on a parent** in a list (it
  recalculates every child). Set `transform` directly on the moving element.
- **Motion's `x`/`y`/`scale` shorthands are NOT hardware-accelerated** (they run on
  the main thread via rAF and drop frames under load). For predetermined motion
  during page loads, use a real `transform` string or CSS animations (off the main
  thread). Use JS only for dynamic, interruptible motion.
- **WAAPI** (`element.animate([...], {...})`) gives CSS performance with JS control,
  hardware-accelerated and interruptible, no library.
- **`will-change: transform`** fixes jitter but allocates a layer; use sparingly.
- **Animate the child, not the parent**, to avoid hover-boundary flicker.

## Accessibility

- **`prefers-reduced-motion: reduce`** means fewer and gentler, not zero. Keep
  opacity/color transitions that aid comprehension; drop position/transform motion.
- **Gate hover behind `@media (hover: hover) and (pointer: fine)`** so touch devices
  do not trigger hover on tap.

## Stagger

When several elements enter together, stagger them 30 to 80ms apart for a cascade
that beats everything popping at once. Keep delays short, and never block
interaction while a stagger plays (it is decoration).

## Debugging

- **Slow-mo**: bump duration 2 to 5x (or use the DevTools animation inspector).
  Watch for overlapping states in a crossfade, wrong `transform-origin`, abrupt
  easing, and properties drifting out of sync.
- **Frame-by-frame** in the Chrome Animations panel for coordinated-property timing.
- **Test gestures on real hardware**, not just the simulator.
- **Look again the next day.** Fresh eyes catch what tired ones shipped.

## The Sonner lessons (apply to any component)

Great defaults beat many options (most users never customize). Handle edge cases
invisibly (pause toast timers on a hidden tab, fill stack gaps so hover holds).
Use transitions not keyframes for rapidly-added items. Naming creates identity.
And **cohesion**: match the motion to the component's personality. Sonner runs
slightly slower and uses `ease` (not `ease-out`) because that fits its elegant,
calm vibe. A playful widget can bounce; a pro dashboard stays crisp and fast.

---

# Vasudev's layer

> Personal taste on top of the rules above. Edit freely. Where a line is a guess
> from my site rather than a stated rule, it is marked (infer).

- **Reveals over spectacles.** A typewriter on my name is a spectacle and it dates.
  Prefer a fast mask-reveal or fade+rise that happens once and disappears. Motion
  should support the story, not perform.
- **Calm, considered, exact.** Fewer animations, better chosen. Strong hierarchy and
  restraint over flash. If in doubt, remove it.
- **Orchestrate, do not pile up.** One sequenced entrance beats two competing ones.
  Heavy intros (cover reels, hero motion) should **wake only when fully in view**,
  not fire on load. (infer, from the site's cover-reel behavior.)
- **Momentum with hard cuts.** U-curve timing on bursts: accelerate in, decisive
  cut out. No mushy linear fades on signature moments. (infer.)
- **Stack**: Framer Motion (Motion) + React 19 + Vite. Custom cursor that morphs
  into affordances. Respect the hardware-accel caveat above when motion runs during
  loads.
- **Copy in motion follows the house rule: no em-dashes.** Microcopy in tooltips,
  toasts, and labels uses colons/commas/periods.
- **Default curves I reach for** (edit to taste): `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`
  for entrances, the iOS drawer curve for sheets, springs for anything draggable.
- **TODO (Vasudev):** add your signature durations, your go-to spring config, and any
  component patterns you want enforced (e.g. how cards expand, cursor timing).

## Review checklist

1. Purpose: does each animation communicate something? Cut the rest.
2. Frequency: high-frequency or keyboard action? Then no animation.
3. Easing: matches the tree? Entrances on a strong `ease-out`, never `ease-in`?
4. Duration: under 300ms? Exit faster than enter?
5. Scale/origin: from `0.95` not `0`, origin at the trigger?
6. Performance: only `transform`/`opacity`? No inherited-var thrash? Motion `x/y`
   under load swapped for `transform`/CSS?
7. Interruptible: transitions (not keyframes) for rapidly-triggered state?
8. Reduced motion + touch hover gates present?
9. Vasudev's layer: reveal not spectacle, wakes-when-in-view, no em-dashes in copy?
