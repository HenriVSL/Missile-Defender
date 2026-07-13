//
//  Palette.swift
//  Missile Defender
//
//  A single fixed retro colour scheme for the whole game.
//

import SpriteKit

enum Palette {
    static let sky        = SKColor.black
    static let skyBottom  = SKColor(red: 0.05, green: 0.12, blue: 0.32, alpha: 1)   // horizon blue
    static let ground     = SKColor(red: 0.16, green: 0.42, blue: 1.00, alpha: 1)   // blue
    static let base       = SKColor(red: 0.30, green: 0.60, blue: 1.00, alpha: 1)   // brighter blue
    static let baseDead   = SKColor(white: 0.24, alpha: 1)
    static let city       = SKColor(red: 0.25, green: 0.95, blue: 0.95, alpha: 1)   // cyan
    static let cityDead   = SKColor(white: 0.20, alpha: 1)
    static let incoming   = SKColor(red: 1.00, green: 0.24, blue: 0.24, alpha: 1)   // red
    static let abm        = SKColor(red: 0.65, green: 1.00, blue: 1.00, alpha: 1)   // cyan-white
    static let target     = SKColor(red: 1.00, green: 0.88, blue: 0.30, alpha: 1)   // yellow X
    static let hud        = SKColor(red: 0.82, green: 0.90, blue: 1.00, alpha: 1)
    static let hudDim      = SKColor(red: 0.45, green: 0.55, blue: 0.72, alpha: 1)

    /// Explosion shimmer — rapid cycle through these while a blast is active.
    static let explosionCycle: [SKColor] = [
        SKColor(red: 1.00, green: 0.95, blue: 0.42, alpha: 1),  // yellow
        SKColor(red: 1.00, green: 0.60, blue: 0.16, alpha: 1),  // orange
        SKColor(red: 1.00, green: 0.26, blue: 0.20, alpha: 1),  // red
        SKColor.white
    ]
    /// Static explosion colour used when Reduce Motion is on.
    static let explosionStatic = SKColor(red: 1.00, green: 0.70, blue: 0.25, alpha: 1)
}
