# Missile Defender

A portrait arcade game for iPhone, inspired by the 1980 arcade classic
*Missile Command*. Tap the sky to launch counter-missiles and protect six
cities from endless waves of incoming warheads. Built with SwiftUI and
SpriteKit, with a simple retro vector look.

## Features

| | |
|---|---|
| **Tap to fire** | Tap anywhere in the sky. The nearest battery that still has ammo launches a counter-missile at that point. Multi-touch works, so several fingers fire several shots |
| **Three batteries, six cities** | Batteries sit at the left, centre and right, with two groups of three cities between them. The centre battery fires faster missiles |
| **Limited ammo** | 10 missiles per battery per wave, shown as a small pyramid of dots above each battery. A battery that gets hit is out until the next wave |
| **Blasts** | Counter-missiles detonate where you tapped. The blast expands, holds and contracts, destroying every warhead it touches |
| **Endless waves** | Each wave brings more and faster missiles with shorter gaps between launches. There is no winning, only a higher score |
| **MIRVs** | From wave 3, some warheads split mid-flight into two or three, and this becomes more likely as the waves go on |
| **Scoring** | 25 points per warhead, multiplied by the wave tier (x1 for waves 1 to 2, rising to x6 from wave 11). End-of-wave bonus for unused missiles and surviving cities |
| **Bonus cities** | Batteries are rebuilt every wave, but destroyed cities stay down. Every 10,000 points earns a rebuilt city at the end of the wave |
| **High scores** | Top 5 scores are saved on the device and shown on the title screen |
| **Pause** | Pause button during play. Tap anywhere to resume |
| **Haptics** | Light tap on firing, a thud when warheads are destroyed, a heavy hit when a city or battery is lost |
| **Reduce Motion** | With Reduce Motion on, explosions use a single colour instead of flashing, and the screen does not shake |

The game ends when all six cities are destroyed.

## How it works

- `ContentView` hosts a full-screen `GameScene` (SpriteKit) through SwiftUI's
  `SpriteView`. The status bar and home indicator are hidden.
- Everything is drawn with `SKShapeNode`: triangles for batteries, simple
  city silhouettes, and line trails for missiles. There is no physics
  engine. Missiles move in straight lines and collisions are distance checks
  against each blast radius every frame.
- All tuning values (speeds, wave sizes, MIRV odds, blast timing, scoring)
  are in [`Missile Defender/Game/Config.swift`](Missile%20Defender/Game/Config.swift),
  and colours are in
  [`Missile Defender/Game/Palette.swift`](Missile%20Defender/Game/Palette.swift).
- High scores are stored in `UserDefaults`.

[`DESIGN.md`](DESIGN.md) contains the original design notes. Some items in it,
such as smart bombs, bombers and sound, are **planned** and not part of the
game yet.

## Requirements

- iOS 26.2 or later
- iPhone, portrait only. It also runs on iPad in iPhone compatibility mode.

## Install

1. Download the unsigned `.ipa` from the
   [latest release](https://github.com/HenriVSL/Missile-Defender/releases/latest).
2. Sideload it with a tool that re-signs it with your own Apple ID, such as
   [AltStore](https://altstore.io), [SideStore](https://sidestore.io) or
   [Sideloadly](https://sideloadly.io).

Apps signed with a free Apple ID expire after 7 days and need to be re-signed.

## Build from source

1. Open `Missile Defender.xcodeproj` in Xcode 26.2 or later.
2. Select your team under **Signing & Capabilities** for the
   `Missile Defender` target. Change the bundle identifier
   (`henril.Missile-Defender`) if Xcode reports a conflict.
3. Build and run.

## Third-party components

None. The game uses only Apple frameworks (SwiftUI, SpriteKit, UIKit).

*Missile Command* is a trademark of its respective owner. This project is not
affiliated with or endorsed by Atari.

## License

MIT, see [LICENSE](LICENSE).
