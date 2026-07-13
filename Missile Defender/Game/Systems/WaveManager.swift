//
//  WaveManager.swift
//  Missile Defender
//
//  Owns per-wave difficulty parameters and the spawn schedule. The scene asks it
//  each frame how many missiles to launch; it decides based on the interval timer.
//

import Foundation
import CoreGraphics

final class WaveManager {
    private(set) var wave = 0
    private(set) var totalThisWave = 0
    private(set) var remainingToSpawn = 0
    private(set) var incomingSpeed: CGFloat = 0

    private var spawnInterval: TimeInterval = 1
    private var spawnTimer: TimeInterval = 0

    var finishedSpawning: Bool { remainingToSpawn == 0 }

    func startWave(_ number: Int) {
        wave = number
        let extra = Config.incomingCountPerWave * (number - 1)
        totalThisWave = min(Config.baseIncomingCount + extra, Config.incomingCountMax)
        remainingToSpawn = totalThisWave

        spawnInterval = max(Config.spawnIntervalMin,
                            Config.spawnIntervalStart - Config.spawnIntervalDecay * Double(number - 1))
        spawnTimer = Config.firstSpawnDelay
        incomingSpeed = min(Config.incomingSpeedMax,
                            Config.incomingBaseSpeed + Config.incomingSpeedPerWave * CGFloat(number - 1))
    }

    /// Returns how many missiles should spawn this frame (0 or 1 in practice).
    func update(_ dt: TimeInterval) -> Int {
        guard remainingToSpawn > 0 else { return 0 }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return 0 }
        spawnTimer += spawnInterval
        remainingToSpawn -= 1
        return 1
    }

    var multiplier: Int {
        switch wave {
        case ..<3:   return 1
        case ..<5:   return 2
        case ..<7:   return 3
        case ..<9:   return 4
        case ..<11:  return 5
        default:     return 6
        }
    }

    var mirvChance: CGFloat {
        guard wave >= Config.mirvFirstWave else { return 0 }
        let ramp = Config.mirvChanceStart + Config.mirvChancePerWave * CGFloat(wave - Config.mirvFirstWave)
        return min(Config.mirvChanceMax, ramp)
    }
}
