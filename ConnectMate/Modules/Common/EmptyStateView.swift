import Cocoa
import SnapKit

final class EmptyStateView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")

    init(symbolName: String, title: String, detail: String) {
        super.init(frame: .zero)
        configure(symbolName: symbolName, title: title, detail: detail)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(symbolName: String, title: String, detail: String) {
        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)
        titleLabel.stringValue = title
        detailLabel.stringValue = detail
    }

    private func configure(symbolName: String, title: String, detail: String) {
        wantsLayer = true

        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        iconView.contentTintColor = .secondaryLabelColor

        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)

        detailLabel.stringValue = detail
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 3
        detailLabel.alignment = .center

        let stack = NSStackView(views: [iconView, titleLabel, detailLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }
}
