//
//  Base.swift
//  Missile Defender
//
//  A missile battery. Fires ABMs, holds limited ammo, can be knocked out for a
//  wave. The centre battery fires faster counter-missiles (faithful to the original).
//

import SpriteKit

final class Base {
    let node = SKNode()
    let index: Int
    let isCenter: Bool
    private(set) var position: CGPoint
    private(set) var ammo: Int
    private(set) var alive = true
    private var cooldown: TimeInterval = 0

    private let body = SKShapeNode()
    private let ammoContainer = SKNode()

    /// Point counter-missiles launch from (the apex of the battery).
    var launchPoint: CGPoint { CGPoint(x: position.x, y: position.y + Config.baseHeight) }
    var abmSpeed: CGFloat { isCenter ? Config.abmSpeedCenter : Config.abmSpeed }
    var canFire: Bool { alive && ammo > 0 && cooldown <= 0 }

    init(index: Int, position: CGPoint, isCenter: Bool) {
        self.index = index
        self.position = position
        self.isCenter = isCenter
        self.ammo = Config.ammoPerBase

        let w = Config.baseWidth, h = Config.baseHeight
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w / 2, y: 0))
        path.addLine(to: CGPoint(x: w / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        body.path = path
        body.lineWidth = 1.5

        node.addChild(body)
        node.addChild(ammoContainer)
        node.position = position
        refreshVisual()
    }

    func reposition(to newPosition: CGPoint) {
        position = newPosition
        node.position = newPosition
    }

    func tick(_ dt: TimeInterval) {
        if cooldown > 0 { cooldown -= dt }
    }

    func fire() {
        guard canFire else { return }
        ammo -= 1
        cooldown = Config.fireCooldown
        refreshVisual()
    }

    func reload() {
        alive = true
        ammo = Config.ammoPerBase
        cooldown = 0
        refreshVisual()
    }

    func destroy() {
        guard alive else { return }
        alive = false
        ammo = 0
        refreshVisual()
    }

    private func refreshVisual() {
        body.fillColor = alive ? Palette.base : Palette.baseDead
        body.strokeColor = alive ? Palette.base : Palette.baseDead
        rebuildAmmoPyramid()
    }

    /// Draw remaining ammo as a small stacked pyramid above the battery.
    private func rebuildAmmoPyramid() {
        ammoContainer.removeAllChildren()
        guard alive, ammo > 0 else { return }

        let rows = [4, 3, 2, 1]          // 10 slots, filled from the bottom row up
        let dx: CGFloat = 6, dy: CGFloat = 5.5
        let baseY = Config.baseHeight + 7
        var placed = 0

        outer: for (rowIndex, count) in rows.enumerated() {
            for column in 0..<count {
                if placed >= ammo { break outer }
                let x = (CGFloat(column) - CGFloat(count - 1) / 2) * dx
                let y = baseY + CGFloat(rowIndex) * dy
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = Palette.abm
                dot.strokeColor = .clear
                dot.position = CGPoint(x: x, y: y)
                ammoContainer.addChild(dot)
                placed += 1
            }
        }
    }
}
