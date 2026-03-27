import AppKit
import SnapKit

@MainActor
enum SigningAlertAccessoryFactory {
    private enum Metrics {
        static let containerWidth: CGFloat = 440
        static let labelWidth: CGFloat = 120
        static let controlMinimumWidth: CGFloat = 280
        static let rowSpacing: CGFloat = 12
        static let containerInset: CGFloat = 2
        static let stackSpacing: CGFloat = 10
        static let hintWidth: CGFloat = 420
    }

    static func makeContainer(rows: [NSView]) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: Metrics.containerWidth, height: 1))
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = Metrics.stackSpacing

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Metrics.containerInset)
            make.width.equalToSuperview().inset(Metrics.containerInset * 2)
        }

        container.layoutSubtreeIfNeeded()
        let fittingSize = container.fittingSize
        container.frame.size = NSSize(
            width: max(Metrics.containerWidth, ceil(fittingSize.width)),
            height: max(1, ceil(fittingSize.height))
        )
        return container
    }

    static func makeRow(title: String, control: NSView) -> NSView {
        let row = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        control.setContentHuggingPriority(.defaultLow, for: .horizontal)
        control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        row.addSubview(label)
        row.addSubview(control)

        label.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalTo(Metrics.labelWidth).priority(.high)
            make.bottom.lessThanOrEqualToSuperview()
        }

        control.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(Metrics.rowSpacing)
            make.top.trailing.bottom.equalToSuperview()
            make.width.greaterThanOrEqualTo(Metrics.controlMinimumWidth).priority(.high)
        }

        label.snp.makeConstraints { make in
            make.centerY.equalTo(control.snp.centerY)
        }

        row.layoutSubtreeIfNeeded()
        row.frame.size = NSSize(
            width: Metrics.containerWidth,
            height: max(1, ceil(row.fittingSize.height))
        )
        return row
    }

    static func makeHintLabel(_ text: String) -> NSView {
        let label = NSTextField(wrappingLabelWithString: text)
        label.textColor = .secondaryLabelColor
        label.font = .systemFont(ofSize: 11)
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = Metrics.hintWidth
        label.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(Metrics.hintWidth)
        }
        return label
    }
}
