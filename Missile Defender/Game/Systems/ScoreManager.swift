//
//  ScoreManager.swift
//  Missile Defender
//
//  Tracks score, the persistent high score, and bonus-city thresholds.
//

import Foundation

final class ScoreManager {
    private(set) var score = 0
    private(set) var high = 0
    private var nextBonusCity = Config.bonusCityEvery

    private let highScoreKey = "MissileDefender.highScore"

    init() {
        high = UserDefaults.standard.integer(forKey: highScoreKey)
    }

    func reset() {
        score = 0
        nextBonusCity = Config.bonusCityEvery
    }

    func addMissileKill(multiplier: Int) {
        add(Config.pointsPerMissile * multiplier)
    }

    func add(_ points: Int) {
        score += points
        if score > high {
            high = score
            UserDefaults.standard.set(high, forKey: highScoreKey)
        }
    }

    /// Number of bonus cities earned by crossing 10k thresholds since last check.
    func claimBonusCities() -> Int {
        var earned = 0
        while score >= nextBonusCity {
            nextBonusCity += Config.bonusCityEvery
            earned += 1
        }
        return earned
    }
}
