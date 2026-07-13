# Missile Defender — Design & Planning Document

A modern, vertical (portrait) reimagining of Atari's **Missile Command** (1980) for
modern iPhones, built with SwiftUI + SpriteKit. Retro vector look, simple color palette,
tap-to-fire controls.

---

## 1. Vision

- **Core fantasy:** You are the last line of missile defense. Waves of ICBMs rain
  down on your ground installations; you tap the sky to detonate counter-missiles and
  wipe them out before they land.
- **Feel:** Fast, tense, arcade. Simple bright vector graphics on a black sky.
  Escalating waves with no "win" — you play for a high score until everything is gone.
- **Platform:** Portrait iPhone only (runs on iPad in compatibility mode). Locked
  orientation. Target: iOS 26.
- **One-hand / two-thumb friendly:** everything is driven by tapping the play area.

---

## 2. How the original Missile Command worked (reference)

The player is a regional commander of **three anti-missile batteries** defending
**six cities**. A trackball moves a single crosshair; three buttons each launch a
counter-missile (ABM) from the corresponding battery toward the crosshair, where it
detonates into an expanding blast. Anything the blast touches is destroyed.

Key mechanics we are faithful to:

| Element | Original behavior |
|---|---|
| **Batteries** | 3 bases, **10 ABMs each per wave** (30 total). A base hit by an enemy loses its remaining ammo and is dead until next wave. Center base fires faster ABMs. |
| **Cities** | 6 cities. Purely passive — you defend them. When all cities are gone, the game ends. |
| **Attack missiles** | Fall from the top toward a random ground target on a straight trajectory, leaving a trail. |
| **MIRVs** | Some missiles split mid-flight into multiple warheads with new targets. |
| **Smart bombs** | Appear ~wave 5. Actively steer *around* your blasts; must be hit at close range. |
| **Bomber / killer satellite** | Appear ~wave 2. Cross the screen and drop/launch more missiles. |
| **Explosions** | Expand to a max radius, linger, then contract. Destroy everything they touch during that time. Catching multiple enemies in one blast is efficient. |
| **Waves** | Each wave is faster and denser; point values are multiplied by wave tier. |
| **Scoring** | 25 pts per destroyed missile × wave multiplier. End-of-wave bonus for unused ABMs and surviving cities. Bonus city every 10,000 pts. |
| **Wave multiplier** | Waves 1–2 ×1, 3–4 ×2, 5–6 ×3, 7–8 ×4, 9–10 ×5, 11+ ×6. |
| **Game over** | All six cities destroyed → "THE END". |

---

## 3. Modern / mobile tweaks (the important part)

These are the deliberate changes from the 1980 arcade cabinet.

### Controls
- **Trackball + 3 buttons → tap.** Tapping a point in the sky *is* the target. The
  game **auto-selects the nearest base that still has ammo** and launches an ABM there.
- **Rapid multi-tap** is allowed — each valid tap fires one ABM (subject to ammo and a
  tiny per-base cooldown), so panic-tapping a cluster feels good.
- **No crosshair to steer** — removes the biggest source of 1980 clumsiness.
- Optional later: brief tracer line from firing base to target so you can read shots.

### Layout & orientation
- **Portrait, locked.** Taller playfield than the original's 4:3 → incoming missiles
  travel farther, so speeds are retuned (see §7) to keep reaction time fair.
- **Safe areas respected:** ground installations sit above the home indicator; enemy
  spawns are pushed below the Dynamic Island / notch band so nothing important hides
  under hardware.

### Difficulty tuned for touch
- Fingers are less precise than a trackball, so early waves are **sparser** and blast
  radius is **slightly generous**. Difficulty ramps back up quickly.
- **Endless** arcade progression (no kill screen); pure high-score chase.

### Modern hardware affordances
- **60/120 Hz ProMotion** smooth vector animation instead of chunky raster.
- **Retina-crisp vector strokes**; optional subtle glow, kept minimal to preserve the
  simple retro palette.
- **Haptics:** light tap on fire, medium thud on explosion, heavy on losing a city.
- **Persistent high score** (UserDefaults).
- **Pause** button (mobile sessions get interrupted) + resume.
- **Reduce Motion** support: tones down palette-flashing and screen shake for
  photosensitivity/accessibility.

### Scope simplifications for v1
- Bomber/killer satellite and smart bombs are **later milestones**, not v1.
- Start with attack missiles + MIRV splitting; that alone is a complete game.

---

## 4. Core gameplay loop

```
Wave start
  → Palette set for this wave
  → Bases reloaded to full ammo, surviving cities restored to view
  → Spawner drips N incoming missiles over the wave duration (some MIRV)
Player taps → nearest armed base fires ABM → travels → detonates → blast expands
  → blast overlaps incoming warhead → warhead destroyed, +score
Incoming missile reaches ground → hits city or base → that target destroyed
Wave cleared (all incoming resolved)
  → Bonus: unused ABMs + surviving cities (× wave multiplier)
  → Next wave (faster, denser)
All cities destroyed → GAME OVER → high score → restart
```

---

## 5. Entities & data model

Lightweight: each entity is a small type owning an `SKNode` (usually `SKShapeNode`
for the vector look). No physics engine — we do straight-line motion + circle-overlap
tests each frame (cheap, and gives us exact control).

- **Base** — position, `ammo` count, `alive`, `isCenter` (faster ABMs), fire cooldown.
- **City** — position, `alive`. Passive.
- **IncomingMissile** — `start`, `target`, `speed`, current head position, trail path,
  optional `splitAltitude` + `splitCount` for MIRV.
- **PlayerMissile (ABM)** — `start`, `target`, `speed`, head position, trail.
  On reaching target → spawn Explosion.
- **Explosion** — center, current radius, phase (expand → hold → contract), max radius.
  Destroys overlapping enemies while active.
- **SmartBomb** (later) — like IncomingMissile but steers away from nearby explosions.
- **Bomber / Satellite** (later) — horizontal crosser that spawns incoming missiles.

Collision model each frame:
- ABM/incoming head reaches its target point → remove head, trigger effect.
- For every active Explosion, test distance(center, incomingHead) ≤ radius → kill
  incoming, award points, optionally chain.
- Incoming head reaching ground target → destroy the city/base at that point.

---

## 6. Visual design

- **Aesthetic:** pure vector — thin bright strokes, filled simple shapes, black sky.
  Missiles are a moving dot with a line trail; targets marked with a small `✕`.
- **Palette (single fixed scheme for the whole game).** One high-contrast retro set,
  defined centrally in `Palette.swift`:

  | Role | Color |
  |---|---|
  | Sky | black |
  | Ground / bases | blue |
  | Cities | cyan |
  | Incoming trail + head | red |
  | ABM trail + head | cyan/white |
  | Explosion shimmer | yellow → orange → red → white (within the fixed scheme) |
- **Explosions:** filled circle whose color cycles rapidly through the wave's explosion
  colors while it expands/holds/contracts (the classic shimmering blob).
- **HUD:** score top-center, high score corner, wave number, ammo pips per base near
  each battery, all in the same vector font/stroke style. Minimal chrome.

---

## 7. Waves, difficulty & scoring

Difficulty is data-driven from a single tunable `Config` so balancing is one file.

Per wave, scaled by wave index:
- `incomingCount` — starts ~6–8, grows.
- `incomingSpeed` — starts slow (retuned for the taller portrait field), grows.
- `mirvChance` / `mirvSplits` — 0 early, ramps in.
- `smartBombCount` — 0 until wave 5+ (later milestone).
- `spawnInterval` — gap between incoming launches shrinks.

Scoring (faithful to original):
- **25 × waveMultiplier** per destroyed enemy missile.
- End-of-wave: **5 × waveMultiplier** per unused ABM, **100 × waveMultiplier** per
  surviving city.
- **Bonus city every 10,000 pts** (up to a max city count).
- Wave multiplier tiers: 1–2 ×1, 3–4 ×2, 5–6 ×3, 7–8 ×4, 9–10 ×5, 11+ ×6.

---

## 8. Game states / screens

Simple enum state machine driving the scene:

- `attract` / **Title** — game name, tap to start, high score.
- `playing` — the loop above.
- `waveCleared` — bonus tally animation, brief pause, then next wave.
- `paused` — overlay, resume/quit.
- `gameOver` — "THE END", final score, new-high-score flash, tap to restart.

---

## 9. Technical architecture

- **SwiftUI shell + SpriteKit scene.** `ContentView` hosts the game via SwiftUI's
  built-in `SpriteView(scene:)` — no `UIViewRepresentable` needed on iOS 26.
- **`GameScene: SKScene`** owns the game loop (`update(_:)`), entity arrays, input
  (`touchesBegan`), and the state machine.
- **Vector rendering** via `SKShapeNode` (paths for trails, circles for explosions).
  Trails are redrawn from each missile's `start` to its current head each frame.
- **No SpriteKit physics** — custom straight-line motion + circle-overlap collisions
  for precision and simplicity.
- **Systems** kept as small focused types: `Spawner`/`WaveManager`, `CollisionSystem`,
  `ScoreManager`, `Palette`, `Config`.
- **Persistence:** high score in `UserDefaults`.
- **Haptics:** `UIImpactFeedbackGenerator` (upgrade to Core Haptics later if wanted).

Proposed file layout:

```
Missile Defender/
  Missile_DefenderApp.swift      // @main
  ContentView.swift              // SwiftUI host: title + SpriteView
  Game/
    GameScene.swift              // loop, input, state machine
    GameState.swift              // enum + transitions
    Config.swift                 // all tunable numbers (difficulty, sizes, speeds)
    Palette.swift                // per-wave color sets
    Entities/
      Base.swift
      City.swift
      IncomingMissile.swift
      PlayerMissile.swift
      Explosion.swift
    Systems/
      WaveManager.swift          // spawn schedule + difficulty scaling
      CollisionSystem.swift      // overlap tests, scoring hooks
      ScoreManager.swift         // score, multiplier, high score
    UI/
      HUDNode.swift              // score / wave / ammo pips
```

---

## 10. Ground installation layout (portrait, along the bottom)

Faithful to the original ordering `Base–cities–Base–cities–Base`, mapped to width:

- Bases at ~**10%**, **50%** (center = faster ABMs), **90%** of width.
- Cities in two groups of three between the bases (~22/30/38% and ~62/70/78%).
- All sit on a ground strip above the home-indicator safe area.

*(If we drop cities — see open question §12 — the three bases become the only things
you defend and losing all three ends the game.)*

---

## 11. Implementation roadmap (milestones)

1. **Skeleton** — SwiftUI hosts a black `GameScene`; ground strip, 3 bases, 6 cities
   drawn as vectors. Portrait locked. Compiles for device.
2. **Fire ABMs** — tap → nearest armed base launches an ABM → travels → explosion
   expands/holds/contracts. Ammo decrements, pips update.
3. **Incoming missiles** — spawner drips attack missiles toward ground targets with
   trails; explosions destroy them; enemies that land destroy a city/base.
4. **Waves & scoring** — wave clear detection, end-of-wave bonus, difficulty ramp,
   score/high-score HUD, wave palette cycling.
5. **Game states** — title, pause, game over, restart.
6. **Juice** — haptics, screen shake, explosion color cycling, Reduce Motion path.
7. **MIRV splitting** — mid-flight splits, ramped by wave.
8. **Stretch:** smart bombs, bomber/satellite, bonus cities, sound.

Each milestone is independently playable/testable.

---

## 12. Resolved design decisions

1. **Targets:** 3 bases **+ 6 cities**. Cities are passive; game over when all cities
   are destroyed. Bases can be knocked out for a wave but don't end the game.
2. **Ammo:** **Limited, 10 per base per wave** (30 total), reloaded each wave. Unused
   ABMs give an end-of-wave bonus.
3. **Palette:** **Single fixed scheme** for the whole game (no per-wave recolor).
   Explosions still shimmer through a small set of colors *within* that fixed scheme;
   the shimmer is dampened under Reduce Motion.

---

## 13. Build & test workflow

- Verify by **compiling for a generic iOS device** with `xcodebuild`
  (`-destination 'generic/platform=iOS'`); the iOS Simulator is intentionally not used.
- Gameplay is validated by the user **on real hardware**.
- Balancing lives entirely in `Config.swift` for fast iteration on device.

---

*Reference: Missile Command (Atari, 1980).*
Sources:
[Missile Command — Wikipedia](https://en.wikipedia.org/wiki/Missile_Command) ·
[arcade-history](https://www.arcade-history.com/?page=detail&id=1644) ·
[Missile Command disassembly](https://6502disassembly.com/va-missile-command/)
