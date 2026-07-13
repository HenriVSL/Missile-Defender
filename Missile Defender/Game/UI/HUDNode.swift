//
//  HUDNode.swift
//  Missile Defender
//
//  Top-of-screen readout: high score (left), score (centre), wave (right), plus a
//  tappable pause button. Uses a monospaced font for the retro terminal look.
//

import SpriteKit

final class HUDNode: SKNode {
    static let pauseName = "hud.pause"

    private let font = "Menlo-Bold"
    private let scoreLabel = SKLabelNode()
    private let highLabel = SKLabelNode()
    private let waveLabel = SKLabelNode()
    private let pauseButton = SKShapeNode()
    private let pauseGlyph = SKLabelNode()

    override init() {
        super.init()
        configure(scoreLabel, size: 22, align: .center)
        configure(highLabel, size: 13, align: .left, color: Palette.hudDim)
        configure(waveLabel, size: 13, align: .right, color: Palette.hudDim)

        pauseButton.name = HUDNode.pauseName
        pauseButton.strokeColor = Palette.hudDim
        pauseButton.lineWidth = 1
        pauseButton.fillColor = SKColor.black.withAlphaComponent(0.01)

        configure(pauseGlyph, size: 14, align: .center)
        pauseGlyph.text = "II"
        pauseButton.addChild(pauseGlyph)

        addChild(scoreLabel)
        addChild(highLabel)
        addChild(waveLabel)
        addChild(pauseButton)

        setScore(0)
        setHigh(0)
        setWave(1)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure(_ label: SKLabelNode, size: CGFloat, align: SKLabelHorizontalAlignmentMode, color: SKColor = Palette.hud) {
        label.fontName = font
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = align
        label.verticalAlignmentMode = .center
    }

    func layout(sceneSize: CGSize) {
        let topY = sceneSize.height - 22
        let margin: CGFloat = 14
        scoreLabel.position = CGPoint(x: sceneSize.width / 2, y: topY)
        highLabel.position = CGPoint(x: margin, y: topY + 2)
        waveLabel.position = CGPoint(x: sceneSize.width - margin, y: topY + 2)

        let btn: CGFloat = 30
        pauseButton.path = CGPath(roundedRect: CGRect(x: -btn / 2, y: -btn / 2, width: btn, height: btn),
                                  cornerWidth: 5, cornerHeight: 5, transform: nil)
        pauseButton.position = CGPoint(x: sceneSize.width - margin - btn / 2, y: topY - 26)
    }

    func setPauseButtonVisible(_ visible: Bool) { pauseButton.isHidden = !visible }
    func setScore(_ value: Int) { scoreLabel.text = String(format: "%06d", value) }
    func setHigh(_ value: Int)  { highLabel.text = "HI " + String(format: "%06d", value) }
    func setWave(_ value: Int)  { waveLabel.text = "WAVE \(value)" }
    func setPaused(_ paused: Bool) { pauseGlyph.text = paused ? "\u{25B6}" : "II" }
}
