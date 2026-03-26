import Cocoa
import SnapKit

final class LoadingView: NSView {
    private let indicator = NSProgressIndicator()
    private let titleLabel = NSTextField(labelWithString: "")

    init(title: String) {
        super.init(frame: .zero)
        configure(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String) {
        titleLabel.stringValue = title
    }

    private func configure(title: String) {
        wantsLayer = true

        indicator.style = .spinning
        indicator.controlSize = .regular
        indicator.startAnimation(nil)

        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [indicator, titleLabel])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
