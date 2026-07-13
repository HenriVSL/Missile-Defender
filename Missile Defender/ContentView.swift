//
//  ContentView.swift
//  Missile Defender
//
//  Hosts the SpriteKit game. The scene fills the safe area; the black sky extends
//  behind the Dynamic Island / home indicator so nothing gameplay-critical hides
//  under hardware.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var scene: GameScene?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if let scene {
                    SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                }
            }
            .onAppear { ensureScene(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in
                ensureScene(size: newSize)
                scene?.size = newSize
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private func ensureScene(size: CGSize) {
        guard scene == nil, size.width > 0, size.height > 0 else { return }
        let newScene = GameScene(size: size)
        newScene.scaleMode = .resizeFill
        scene = newScene
    }
}

#Preview {
    ContentView()
}
