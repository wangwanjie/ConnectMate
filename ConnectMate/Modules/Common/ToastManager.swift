import Cocoa
import SnapKit

enum ToastManager {
    static func show(message: String, in view: NSView) {
        let toast = ToastView(message: message)
        view.addSubview(toast)
        toast.alphaValue = 0

        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(24)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            toast.animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                toast.animator().alphaValue = 0
            }, completionHandler: {
                toast.removeFromSuperview()
            })
        }
    }
}

private final class ToastView: NSVisualEffectView {
    init(message: String) {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 10

        let label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2

        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
