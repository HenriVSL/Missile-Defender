//
//  Explosion.swift
//  Missile Defender
//
//  An expanding / holding / contracting blast. While alive and `damaging`, it
//  destroys any enemy warhead whose head falls within its current radius.
//

import SpriteKit

final class Explosion {
    let node: SKShapeNode
    let center: CGPoint
    let damaging: Bool

    private(set) var radius: CGFloat = 0
    private(set) var alive = true
    private var age: TimeInterval = 0
    private let maxRadius: CGFloat
    private let reduceMotion: Bool

    private let expand = Config.explosionExpandTime
    private let hold = Config.explosionHoldTime
    private let contract = Config.explosionContractTime
    private var total: TimeInterval { expand + hold + contract }

    init(center: CGPoint, maxRadius: CGFloat, damaging: Bool, reduceMotion: Bool) {
        self.center = center
        self.maxRadius = maxRadius
        self.damaging = damaging
        self.reduceMotion = reduceMotion

        // Circle drawn at full radius and scaled down each frame (crisp, no path rebuilds).
        node = SKShapeNode(circleOfRadius: maxRadius)
        node.position = center
        node.lineWidth = 0
        node.alpha = Config.explosionAlpha
        node.fillColor = reduceMotion ? Palette.explosionStatic : Palette.explosionCycle[0]
        node.strokeColor = .clear
        node.setScale(0.0001)
    }

    func update(_ dt: TimeInterval) {
        guard alive else { return }
        age += dt

        switch age {
        case ..<expand:
            radius = maxRadius * CGFloat(age / expand)
        case ..<(expand + hold):
            radius = maxRadius
        case ..<total:
            let t = (age - expand - hold) / contract
            radius = maxRadius * CGFloat(1 - t)
        default:
            alive = false
            node.removeFromParent()
            return
        }

        node.setScale(max(0.0001, radius / maxRadius))

        if !reduceMotion {
            let index = Int(age / Config.explosionColorPeriod) % Palette.explosionCycle.count
            node.fillColor = Palette.explosionCycle[index]
        }
    }
}
