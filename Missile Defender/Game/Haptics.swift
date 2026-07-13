//
//  Haptics.swift
//  Missile Defender
//
//  Thin wrapper over UIImpactFeedbackGenerator. No-ops on devices without a
//  Taptic Engine (e.g. iPad), which is the desired behaviour.
//

import UIKit

enum Haptics {
    static var enabled = true

    static func light()  { impact(.light) }
    static func medium() { impact(.medium) }
    static func heavy()  { impact(.heavy) }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
