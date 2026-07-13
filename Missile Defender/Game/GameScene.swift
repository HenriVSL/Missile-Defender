//
//  GameScene.swift
//  Missile Defender
//
//  The whole game: layout, input, loop, collisions, waves, and state machine.
//

import SpriteKit
import UIKit

final class GameScene: SKScene {

    // Layers
    private let skyNode = SKSpriteNode()
    private let worldLayer = SKNode()
    private let hud = HUDNode()
    private let groundNode = SKShapeNode()
    private var overlay: SKNode?

    // Installations
    private var bases: [Base] = []
    private var cities: [City] = []
    private var installationsBuilt = false

    // Transient entities
    private var incoming: [IncomingMissile] = []
    private var abms: [PlayerMissile] = []
    private var explosions: [Explosion] = []

    // Systems
    private let score = ScoreManager()
    private let wave = WaveManager()

    // State
    private var state: GameState = .title
    private var lastUpdate: TimeInterval = 0
    private var groundY: CGFloat = 0
    private var basePositions: [CGPoint] = []
    private var cityPositions: [CGPoint] = []

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = Palette.sky
        view.isMultipleTouchEnabled = true

        skyNode.zPosition = -10
        skyNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(skyNode)

        groundNode.strokeColor = .clear
        groundNode.fillColor = Palette.ground
        worldLayer.addChild(groundNode)

        addChild(worldLayer)
        addChild(hud)

        computeLayout()
        buildInstallations()
        hud.layout(sceneSize: size)
        hud.setHigh(score.high)
        showTitle()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        computeLayout()
        repositionInstallations()
        hud.layout(sceneSize: size)
    }

    // MARK: - Layout

    private func computeLayout() {
        let groundH = size.height * Config.groundHeightFrac
        groundY = groundH
        groundNode.path = CGPath(rect: CGRect(x: 0, y: 0, width: size.width, height: groundH), transform: nil)
        basePositions = Config.baseXFracs.map { CGPoint(x: size.width * $0, y: groundH) }
        cityPositions = Config.cityXFracs.map { CGPoint(x: size.width * $0, y: groundH) }
        updateSky()
    }

    /// Vertical gradient: horizon blue at the bottom fading to black up top, so
    /// warheads read as descending from space.
    private func updateSky() {
        guard size.width > 0, size.height > 0 else { return }
        skyNode.texture = GameScene.makeSkyTexture(size: size)
        skyNode.size = size
        skyNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private static func makeSkyTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors = [Palette.skyBottom.cgColor, Palette.sky.cgColor, Palette.sky.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 0.5, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors, locations: locations) else { return }
            // UIKit image space has y=0 at the top; draw blue from the visual bottom up.
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: size.height),
                                                 end: CGPoint(x: 0, y: 0),
                                                 options: [])
        }
        return SKTexture(image: image)
    }

    private func buildInstallations() {
        guard !installationsBuilt else { return }
        for (i, p) in basePositions.enumerated() {
            let base = Base(index: i, position: p, isCenter: i == 1)
            bases.append(base)
            worldLayer.addChild(base.node)
        }
        for p in cityPositions {
            let city = City(position: p)
            cities.append(city)
            worldLayer.addChild(city.node)
        }
        installationsBuilt = true
    }

    private func repositionInstallations() {
        guard installationsBuilt else { return }
        for (i, base) in bases.enumerated() where i < basePositions.count {
            base.reposition(to: basePositions[i])
        }
        for (i, city) in cities.enumerated() where i < cityPositions.count {
            city.reposition(to: cityPositions[i])
        }
    }

    private func resetInstallations() {
        for base in bases { base.reload() }
        for city in cities { city.restore() }
    }

    // MARK: - Game flow

    private func startGame() {
        clearTransients()
        resetInstallations()
        score.reset()
        hud.setScore(0)
        hud.setHigh(score.high)
        clearOverlay()
        state = .playing
        wave.startWave(1)
        hud.setWave(wave.wave)
        hud.setPauseButtonVisible(true)
    }

    private func startNextWave() {
        guard state == .waveCleared else { return }
        removeAction(forKey: "nextWave")
        clearOverlay()
        clearTransients()
        for base in bases { base.reload() }   // cities persist between waves
        state = .playing
        wave.startWave(wave.wave + 1)
        hud.setWave(wave.wave)
        hud.setPauseButtonVisible(true)
    }

    private func endWave() {
        state = .waveCleared
        hud.setPauseButtonVisible(false)

        let unusedABMs = bases.reduce(0) { $0 + ($1.alive ? $1.ammo : 0) }
        let savedCities = cities.filter { $0.alive }.count
        let mult = wave.multiplier
        let bonus = unusedABMs * Config.pointsPerUnusedABM * mult
                  + savedCities * Config.pointsPerSavedCity * mult
        score.add(bonus)
        hud.setScore(score.score)

        awardBonusCities(score.claimBonusCities())

        showWaveClearedOverlay(unusedABMs: unusedABMs, savedCities: savedCities, bonus: bonus)

        run(.sequence([.wait(forDuration: Config.interWaveDelay),
                       .run { [weak self] in self?.startNextWave() }]),
            withKey: "nextWave")
    }

    private func awardBonusCities(_ count: Int) {
        guard count > 0 else { return }
        var remaining = count
        for city in cities where !city.alive && remaining > 0 {
            city.restore()
            remaining -= 1
        }
    }

    private func gameOver() {
        state = .gameOver
        removeAction(forKey: "nextWave")
        hud.setHigh(score.high)
        hud.setPauseButtonVisible(false)
        showGameOverOverlay()
    }

    private func togglePause() {
        switch state {
        case .playing:
            state = .paused
            hud.setPaused(true)
            showPauseOverlay()
        case .paused:
            state = .playing
            hud.setPaused(false)
            clearOverlay()
        default:
            break
        }
    }

    private func clearTransients() {
        for m in incoming { m.node.removeFromParent() }
        for a in abms { a.node.removeFromParent() }
        for e in explosions { e.node.removeFromParent() }
        incoming.removeAll()
        abms.removeAll()
        explosions.removeAll()
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch state {
        case .title:
            startGame()
        case .waveCleared:
            startNextWave()
        case .gameOver:
            showTitle()
        case .paused:
            togglePause()
        case .playing:
            if nodes(at: location).contains(where: { $0.name == HUDNode.pauseName }) {
                togglePause()
                return
            }
            // Fire one ABM per touch so multi-touch panic firing works.
            for t in touches { fire(at: t.location(in: self)) }
        }
    }

    private func fire(at point: CGPoint) {
        let armed = bases.filter { $0.canFire }
        guard let base = armed.min(by: { distance($0.launchPoint, point) < distance($1.launchPoint, point) }) else {
            return   // out of ammo everywhere
        }
        base.fire()
        let abm = PlayerMissile(start: base.launchPoint, target: point, speed: base.abmSpeed)
        worldLayer.addChild(abm.node)
        abms.append(abm)
        Haptics.light()
    }

    // MARK: - Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 1.0 / 30.0)
        lastUpdate = currentTime
        guard state == .playing else { return }
        step(dt)
    }

    private func step(_ dt: TimeInterval) {
        for base in bases { base.tick(dt) }

        // Spawn
        let toSpawn = wave.update(dt)
        for _ in 0..<toSpawn { spawnIncoming() }

        // Move ABMs, detonate on arrival
        for abm in abms { abm.update(dt) }
        for abm in abms where abm.arrived {
            spawnExplosion(at: abm.target, radius: Config.explosionMaxRadius, damaging: true)
            abm.node.removeFromParent()
        }
        abms.removeAll { $0.arrived }

        // Move explosions
        for ex in explosions { ex.update(dt) }
        explosions.removeAll { !$0.alive }

        // Move incoming, handle MIRV splits
        for m in incoming { m.update(dt) }
        handleSplits()

        // Blasts destroy warheads
        resolveExplosionHits()

        // Landed warheads hit the ground
        handleLandings()

        checkWaveCleared()
    }

    // MARK: - Spawning

    private func spawnIncoming() {
        let x = CGFloat.random(in: size.width * 0.05...size.width * 0.95)
        let startY = size.height + 12
        let target = randomGroundTarget()
        let m = IncomingMissile(start: CGPoint(x: x, y: startY), target: target, speed: wave.incomingSpeed)

        if wave.wave >= Config.mirvFirstWave, CGFloat.random(in: 0...1) < wave.mirvChance {
            let frac = CGFloat.random(in: Config.mirvSplitYFracMin...Config.mirvSplitYFracMax)
            m.splitY = size.height * frac
            m.splitCount = Int.random(in: Config.mirvSplitMin...Config.mirvSplitMax)
        }

        worldLayer.addChild(m.node)
        incoming.append(m)
    }

    private func randomGroundTarget() -> CGPoint {
        let livePositions = cities.filter { $0.alive }.map { $0.position }
                          + bases.filter { $0.alive }.map { $0.position }
        if let p = livePositions.randomElement() {
            return CGPoint(x: p.x, y: groundY)
        }
        // Nothing left to aim at — target the ground so the missile still lands.
        return CGPoint(x: CGFloat.random(in: 0...size.width), y: groundY)
    }

    private func handleSplits() {
        var spawned: [IncomingMissile] = []
        for m in incoming where m.wantsSplit {
            let children = max(0, m.splitCount - 1)
            for _ in 0..<children {
                let child = IncomingMissile(start: m.headPosition, target: randomGroundTarget(), speed: m.speed)
                worldLayer.addChild(child.node)
                spawned.append(child)
            }
            m.consumeSplit(newTarget: randomGroundTarget())
        }
        incoming.append(contentsOf: spawned)
    }

    // MARK: - Collisions & landings

    private func resolveExplosionHits() {
        guard !explosions.isEmpty, !incoming.isEmpty else { return }
        var killedAny = false
        for ex in explosions where ex.alive && ex.damaging {
            for m in incoming where m.alive {
                if distance(ex.center, m.headPosition) <= ex.radius {
                    m.alive = false
                    m.node.removeFromParent()
                    score.addMissileKill(multiplier: wave.multiplier)
                    killedAny = true
                }
            }
        }
        if killedAny {
            incoming.removeAll { !$0.alive }
            hud.setScore(score.score)
            Haptics.medium()
        }
    }

    private func handleLandings() {
        let landed = incoming.filter { $0.arrived }
        guard !landed.isEmpty else { return }
        for m in landed {
            m.node.removeFromParent()
            spawnExplosion(at: m.headPosition, radius: Config.groundBurstRadius, damaging: false)
            hitGround(at: m.headPosition)
        }
        incoming.removeAll { $0.arrived }
    }

    private func hitGround(at point: CGPoint) {
        if let city = cities.first(where: { $0.alive && abs($0.position.x - point.x) < 1 }) {
            city.destroy()
            onInstallationLost()
            if cities.allSatisfy({ !$0.alive }) { gameOver() }
        } else if let base = bases.first(where: { $0.alive && abs($0.position.x - point.x) < 1 }) {
            base.destroy()
            onInstallationLost()
        }
    }

    private func onInstallationLost() {
        Haptics.heavy()
        guard !reduceMotion else { return }
        let shake = SKAction.sequence([
            .moveBy(x: 6, y: 0, duration: 0.03),
            .moveBy(x: -12, y: 0, duration: 0.06),
            .moveBy(x: 6, y: 0, duration: 0.03)
        ])
        worldLayer.run(shake)
    }

    private func spawnExplosion(at point: CGPoint, radius: CGFloat, damaging: Bool) {
        let ex = Explosion(center: point, maxRadius: radius, damaging: damaging, reduceMotion: reduceMotion)
        worldLayer.addChild(ex.node)
        explosions.append(ex)
    }

    private func checkWaveCleared() {
        guard state == .playing, wave.finishedSpawning, incoming.isEmpty else { return }
        endWave()
    }

    // MARK: - Overlays

    private func showTitle() {
        clearTransients()
        resetInstallations()
        state = .title
        hud.setScore(0)
        hud.setWave(1)
        hud.setPaused(false)
        hud.setPauseButtonVisible(false)
        showOverlay([
            .init(text: "MISSILE DEFENDER", size: 34, color: Palette.city),
            .init(text: "", size: 10, color: Palette.hud),
            .init(text: "TAP THE SKY TO INTERCEPT", size: 15, color: Palette.hud),
            .init(text: "DEFEND YOUR CITIES", size: 15, color: Palette.hud),
            .init(text: "", size: 14, color: Palette.hud),
            .init(text: "TAP TO START", size: 18, color: Palette.target),
            .init(text: "", size: 20, color: Palette.hud),
            .init(text: "HIGH SCORE  " + String(format: "%06d", score.high), size: 13, color: Palette.hudDim)
        ])
    }

    private func showWaveClearedOverlay(unusedABMs: Int, savedCities: Int, bonus: Int) {
        showOverlay([
            .init(text: "WAVE \(wave.wave) CLEARED", size: 26, color: Palette.city),
            .init(text: "", size: 10, color: Palette.hud),
            .init(text: "CITIES  \(savedCities) x \(Config.pointsPerSavedCity) x\(wave.multiplier)", size: 14, color: Palette.hud),
            .init(text: "AMMO    \(unusedABMs) x \(Config.pointsPerUnusedABM) x\(wave.multiplier)", size: 14, color: Palette.hud),
            .init(text: "BONUS   \(bonus)", size: 16, color: Palette.target),
            .init(text: "", size: 14, color: Palette.hud),
            .init(text: "TAP TO CONTINUE", size: 14, color: Palette.hudDim)
        ])
    }

    private func showGameOverOverlay() {
        let isHigh = score.score >= score.high && score.score > 0
        showOverlay([
            .init(text: "THE END", size: 40, color: Palette.incoming),
            .init(text: "", size: 12, color: Palette.hud),
            .init(text: "SCORE  " + String(format: "%06d", score.score), size: 18, color: Palette.hud),
            .init(text: isHigh ? "NEW HIGH SCORE!" : "HIGH  " + String(format: "%06d", score.high),
                  size: 15, color: isHigh ? Palette.target : Palette.hudDim),
            .init(text: "", size: 16, color: Palette.hud),
            .init(text: "TAP TO CONTINUE", size: 14, color: Palette.hudDim)
        ])
    }

    private func showPauseOverlay() {
        showOverlay([
            .init(text: "PAUSED", size: 30, color: Palette.hud),
            .init(text: "", size: 12, color: Palette.hud),
            .init(text: "TAP TO RESUME", size: 14, color: Palette.hudDim)
        ])
    }

    private struct OverlayLine {
        let text: String
        let size: CGFloat
        let color: SKColor
    }

    private func showOverlay(_ lines: [OverlayLine]) {
        clearOverlay()
        let container = SKNode()
        let spacing: CGFloat = 8
        let totalHeight = lines.reduce(0) { $0 + $1.size + spacing }
        var y = totalHeight / 2

        for line in lines {
            y -= line.size + spacing
            guard !line.text.isEmpty else { continue }
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = line.text
            label.fontSize = line.size
            label.fontColor = line.color
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: y)
            container.addChild(label)
        }

        container.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        container.zPosition = 100
        addChild(container)
        overlay = container
    }

    private func clearOverlay() {
        overlay?.removeFromParent()
        overlay = nil
    }

    // MARK: - Utility

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
