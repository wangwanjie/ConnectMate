import AppKit

final class ThemedBackgroundView: NSView {
    private let backgroundColorProvider: (NSAppearance) -> NSColor
    var onEffectiveAppearanceChange: (() -> Void)?

    init(backgroundColorProvider: @escaping (NSAppearance) -> NSColor) {
        self.backgroundColorProvider = backgroundColorProvider
        super.init(frame: .zero)
        wantsLayer = true
        updateBackgroundColor()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override func updateLayer() {
        super.updateLayer()
        updateBackgroundColor()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateBackgroundColor()
        onEffectiveAppearanceChange?()
    }

    private func updateBackgroundColor() {
        layer?.backgroundColor = backgroundColorProvider(effectiveAppearance)
            .resolvedColor(with: effectiveAppearance)
            .cgColor
    }
}

extension NSColor {
    func resolvedColor(with appearance: NSAppearance) -> NSColor {
        var resolvedColor = self
        appearance.performAsCurrentDrawingAppearance {
            resolvedColor = usingColorSpace(.deviceRGB) ?? self
        }
        return resolvedColor
    }
}
