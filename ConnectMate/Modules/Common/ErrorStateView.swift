import Cocoa
import SnapKit

final class ErrorStateView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let actionButton = NSButton(title: "", target: nil, action: nil)
    private var actionHandler: (() -> Void)?

    init(title: String, detail: String, actionTitle: String? = nil, actionHandler: (() -> Void)? = nil) {
        self.actionHandler = actionHandler
        super.init(frame: .zero)
        configure(title: title, detail: detail, actionTitle: actionTitle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(title: String, detail: String, actionTitle: String?) {
        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        detailLabel.stringValue = detail
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 4
        detailLabel.alignment = .center

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)

        if let actionTitle {
            actionButton.title = actionTitle
            actionButton.bezelStyle = .rounded
            actionButton.target = self
            actionButton.action = #selector(handleAction)
            stack.addArrangedSubview(actionButton)
        }

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }

    @objc
    private func handleAction() {
        actionHandler?()
    }
}
