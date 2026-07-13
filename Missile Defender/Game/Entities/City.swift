//
//  City.swift
//  Missile Defender
//
//  A passive installation the player defends. When every city is gone, the game ends.
//

import SpriteKit

final class City {
    let node = SKNode()
    private(set) var position: CGPoint
    private(set) var alive = true
    private let body = SKShapeNode()

    init(position: CGPoint) {
        self.position = position

        let cw = Config.cityWidth, ch = Config.cityHeight
        let path = CGMutablePath()
        path.addRect(CGRect(x: -cw / 2, y: 0, width: cw, height: ch * 0.55))          // main block
        path.addRect(CGRect(x: -cw / 2, y: 0, width: cw * 0.30, height: ch))          // left tower
        path.addRect(CGRect(x: cw * 0.18, y: 0, width: cw * 0.30, height: ch * 0.78)) // right tower
        body.path = path
        body.lineWidth = 1

        node.addChild(body)
        node.position = position
        refreshVisual()
    }

    func reposition(to newPosition: CGPoint) {
        position = newPosition
        node.position = newPosition
    }

    func restore() {
        alive = true
        refreshVisual()
    }

    func destroy() {
        guard alive else { return }
        alive = false
        refreshVisual()
    }

    private func refreshVisual() {
        body.fillColor = alive ? Palette.city : Palette.cityDead
        body.strokeColor = alive ? Palette.city : Palette.cityDead
        // Flatten the silhouette a little when destroyed (rubble).
        body.yScale = alive ? 1.0 : 0.35
    }
}
