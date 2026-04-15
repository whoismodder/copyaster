import AppKit

final class FloatingPanel: NSPanel {

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        animationBehavior = .none
        isMovableByWindowBackground = false
        hasShadow = false              // La vista SwiftUI maneja su propia sombra
    }

    override func resignKey() {
        super.resignKey()
    }
}
