//
//  ScoreManager.swift
//  Missile Defender
//
//  Tracks the current score, a persistent top-5 high-score table, and bonus-city
//  thresholds.
//

import Foundation

final class ScoreManager {
    private(set) var score = 0
    private(set) var bestScores: [Int] = []
    private var nextBonusCity = Config.bonusCityEvery

    static let maxEntries = 5
    private let key = "MissileDefender.highScores"
    private let legacyKey = "MissileDefender.highScore"

    /// The standing record (top of the table).
    var high: Int { bestScores.first ?? 0 }

    init() {
        let stored = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        bestScores = Array(stored.sorted(by: >).prefix(Self.maxEntries))

        // One-time migration from the earlier single high-score key.
        let legacy = UserDefaults.standard.integer(forKey: legacyKey)
        if legacy > 0 {
            insert(legacy)
            UserDefaults.standard.removeObject(forKey: legacyKey)
            save()
        }
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
    }

    /// Commits the current score to the table. Returns its 1-based rank if it made
    /// the top 5, otherwise nil.
    func recordScore() -> Int? {
        let qualified = insert(score)
        save()
        guard qualified, score > 0 else { return nil }
        return bestScores.filter { $0 > score }.count + 1
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

    @discardableResult
    private func insert(_ value: Int) -> Bool {
        guard value > 0 else { return false }
        let qualifies = bestScores.count < Self.maxEntries || value > (bestScores.last ?? 0)
        bestScores.append(value)
        bestScores.sort(by: >)
        if bestScores.count > Self.maxEntries {
            bestScores.removeLast(bestScores.count - Self.maxEntries)
        }
        return qualifies
    }

    private func save() {
        UserDefaults.standard.set(bestScores, forKey: key)
    }
}
