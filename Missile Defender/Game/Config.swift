//
//  Config.swift
//  Missile Defender
//
//  All tunable gameplay numbers live here so balancing is a single-file edit.
//

import Foundation
import CoreGraphics

enum Config {

    // MARK: Layout (fractions of the scene size)

    /// Height of the ground strip as a fraction of scene height.
    static let groundHeightFrac: CGFloat = 0.05
    /// Horizontal positions of the three batteries.
    static let baseXFracs: [CGFloat] = [0.10, 0.50, 0.90]
    /// Horizontal positions of the six cities (two groups of three, between the bases).
    static let cityXFracs: [CGFloat] = [0.22, 0.30, 0.38, 0.62, 0.70, 0.78]

    // MARK: Installation sizes (points)

    static let baseWidth: CGFloat = 34
    static let baseHeight: CGFloat = 20
    static let cityWidth: CGFloat = 26
    static let cityHeight: CGFloat = 20
    static let missileHeadRadius: CGFloat = 2.5
    static let trailWidth: CGFloat = 2

    // MARK: Ammo

    static let ammoPerBase = 10

    // MARK: Speeds (points per second)

    static let abmSpeed: CGFloat = 680           // side batteries (20% slower than before)
    static let abmSpeedCenter: CGFloat = 1000    // centre battery fires faster (classic)
    static let incomingBaseSpeed: CGFloat = 80
    static let incomingSpeedPerWave: CGFloat = 14
    static let incomingSpeedMax: CGFloat = 340

    // MARK: Explosion

    static let explosionMaxRadius: CGFloat = 44
    static let groundBurstRadius: CGFloat = 24
    static let explosionExpandTime: TimeInterval = 0.22
    static let explosionHoldTime: TimeInterval = 0.55
    static let explosionContractTime: TimeInterval = 0.33
    static let explosionColorPeriod: TimeInterval = 0.07
    static let explosionAlpha: CGFloat = 0.9
    /// A tiny per-battery cooldown so one physical tap fires exactly one ABM.
    static let fireCooldown: TimeInterval = 0.04

    // MARK: Waves

    static let baseIncomingCount = 6
    static let incomingCountPerWave = 2
    static let incomingCountMax = 26
    static let spawnIntervalStart: TimeInterval = 1.4
    static let spawnIntervalMin: TimeInterval = 0.35
    static let spawnIntervalDecay: TimeInterval = 0.07
    static let firstSpawnDelay: TimeInterval = 0.9
    static let interWaveDelay: TimeInterval = 2.4

    // MARK: MIRV (splitting missiles)

    static let mirvFirstWave = 3
    static let mirvChanceStart: CGFloat = 0.15
    static let mirvChancePerWave: CGFloat = 0.04
    static let mirvChanceMax: CGFloat = 0.5
    static let mirvSplitMin = 2
    static let mirvSplitMax = 3
    /// Split altitude as a fraction of scene height (measured from the bottom).
    static let mirvSplitYFracMin: CGFloat = 0.45
    static let mirvSplitYFracMax: CGFloat = 0.62

    // MARK: Scoring

    static let pointsPerMissile = 25
    static let pointsPerUnusedABM = 5
    static let pointsPerSavedCity = 100
    static let bonusCityEvery = 10_000
    static let maxCities = 6
}
