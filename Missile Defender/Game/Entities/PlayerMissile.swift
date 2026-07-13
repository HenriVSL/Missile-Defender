//
//  PlayerMissile.swift
//  Missile Defender
//
//  A counter-missile (ABM). Flies from a battery to the tapped point, marks that
//  point with a target "X", and detonates on arrival.
//

import SpriteKit

final class PlayerMissile {
    let node = SKNode()
    private let trail = SKShapeNode()
    private let head = SKShapeNode(circleOfRadius: Config.missileHeadRadius)
    private let marker = SKNode()

    let start: CGPoint
    let target: CGPoint
    private(set) var pos: CGPoint
    let speed: CGFloat
    private let dir: CGVector
    private(set) var arrived = false

    init(start: CGPoint, target: CGPoint, speed: CGFloat) {
        self.start = start
        self.target = target
        self.pos = start
        self.speed = speed

        let dx = target.x - start.x, dy = target.y - start.y
        let len = max(0.0001, (dx * dx + dy * dy).squareRoot())
        self.dir = CGVector(dx: dx / len, dy: dy / len)

        trail.strokeColor = Palette.abm
        trail.lineWidth = Config.trailWidth
        trail.lineCap = .round
        head.fillColor = Palette.abm
        head.strokeColor = .clear

        buildMarker()
        node.addChild(marker)
        node.addChild(trail)
        node.addChild(head)
        refreshTrail()
    }

    func update(_ dt: TimeInterval) {
        guard !arrived else { return }
        pos.x += dir.dx * speed * CGFloat(dt)
        pos.y += dir.dy * speed * CGFloat(dt)

        let remaining = (target.x - pos.x) * dir.dx + (target.y - pos.y) * dir.dy
        if remaining <= 0 { arrived = true; pos = target }
        refreshTrail()
    }

    private func buildMarker() {
        let s: CGFloat = 6
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -s, y: -s)); path.addLine(to: CGPoint(x: s, y: s))
        path.move(to: CGPoint(x: -s, y: s)); path.addLine(to: CGPoint(x: s, y: -s))
        let cross = SKShapeNode(path: path)
        cross.strokeColor = Palette.target
        cross.lineWidth = 1.5
        marker.addChild(cross)
        marker.position = target
    }

    private func refreshTrail() {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: pos)
        trail.path = path
        head.position = pos
    }
}
