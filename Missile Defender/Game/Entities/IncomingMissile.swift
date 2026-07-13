//
//  IncomingMissile.swift
//  Missile Defender
//
//  An enemy ICBM: travels in a straight line from the top of the screen toward a
//  ground target, leaving a trail. Some missiles MIRV — splitting mid-flight.
//

import SpriteKit

final class IncomingMissile {
    let node = SKNode()
    private let trail = SKShapeNode()          // moving segment: trailStart -> head
    private let staticTrail = SKShapeNode()    // frozen trunk left behind after a split
    private let head = SKShapeNode(circleOfRadius: Config.missileHeadRadius)

    let start: CGPoint
    private(set) var target: CGPoint
    private(set) var pos: CGPoint
    let speed: CGFloat
    private var dir: CGVector
    /// Where the currently-moving trail segment begins (the split point, once split).
    private var trailStart: CGPoint

    var alive = true
    private(set) var arrived = false

    // MIRV
    var splitY: CGFloat?
    var splitCount = 0
    private(set) var hasSplit = false
    private(set) var wantsSplit = false

    /// Current head position, used for collision tests.
    var headPosition: CGPoint { pos }

    init(start: CGPoint, target: CGPoint, speed: CGFloat) {
        self.start = start
        self.target = target
        self.pos = start
        self.trailStart = start
        self.speed = speed
        self.dir = IncomingMissile.unitVector(from: start, to: target)

        for line in [trail, staticTrail] {
            line.strokeColor = Palette.incoming
            line.lineWidth = Config.trailWidth
            line.lineCap = .round
        }
        head.fillColor = Palette.incoming
        head.strokeColor = .clear

        node.addChild(staticTrail)
        node.addChild(trail)
        node.addChild(head)
        refreshTrail()
    }

    func update(_ dt: TimeInterval) {
        guard alive, !arrived else { return }
        pos.x += dir.dx * speed * CGFloat(dt)
        pos.y += dir.dy * speed * CGFloat(dt)

        if let sy = splitY, !hasSplit, pos.y <= sy {
            wantsSplit = true
        }

        // Arrived once we pass the target along the travel direction.
        let remaining = (target.x - pos.x) * dir.dx + (target.y - pos.y) * dir.dy
        if remaining <= 0 { arrived = true; pos = target }

        refreshTrail()
    }

    /// Called by the scene after it consumes a split so children can be spawned.
    func consumeSplit(newTarget: CGPoint) {
        wantsSplit = false
        hasSplit = true

        // Freeze the descending trunk from where the trail began down to the split point,
        // then start a fresh moving segment from the split point outward.
        let trunk = CGMutablePath()
        trunk.move(to: trailStart)
        trunk.addLine(to: pos)
        staticTrail.path = trunk
        trailStart = pos

        retarget(newTarget)
    }

    func retarget(_ newTarget: CGPoint) {
        target = newTarget
        dir = IncomingMissile.unitVector(from: pos, to: newTarget)
    }

    private func refreshTrail() {
        let path = CGMutablePath()
        path.move(to: trailStart)
        path.addLine(to: pos)
        trail.path = path
        head.position = pos
    }

    private static func unitVector(from a: CGPoint, to b: CGPoint) -> CGVector {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(0.0001, (dx * dx + dy * dy).squareRoot())
        return CGVector(dx: dx / len, dy: dy / len)
    }
}
