import AppKit
import SnapKit

@MainActor
final class SigningMultiSelectPickerView: NSView {
    private final class FlippedContentView: NSView {
        override var isFlipped: Bool { true }
    }

    struct Option: Equatable {
        let id: String
        let title: String
        let detail: String?
    }

    private enum Metrics {
        static let minimumWidth: CGFloat = 280
        static let minimumHeight: CGFloat = 46
        static let maximumVisibleItems = 4
        static let checkboxHeight: CGFloat = 20
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 8
        static let itemSpacing: CGFloat = 6
        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8
    }

    private let scrollView = NSScrollView()
    private let documentContainer = FlippedContentView()
    private let stackView = NSStackView()
    private var buttons: [(id: String, button: NSButton)] = []

    var selectedIDs: [String] {
        buttons.compactMap { item in
            item.button.state == .on ? item.id : nil
        }
    }

    init(options: [Option], initiallySelectedIDs: [String] = []) {
        super.init(frame: .zero)
        configure(options: options, initiallySelectedIDs: Set(initiallySelectedIDs))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        updateDocumentLayout()
    }

    func selectAll() {
        buttons.forEach { $0.button.state = .on }
    }

    func invertSelection() {
        buttons.forEach { item in
            item.button.state = item.button.state == .on ? .off : .on
        }
    }

    private func configure(options: [Option], initiallySelectedIDs: Set<String>) {
        wantsLayer = true
        layer?.cornerRadius = Metrics.cornerRadius
        layer?.borderWidth = Metrics.borderWidth
        layer?.borderColor = NSColor.separatorColor.cgColor

        stackView.orientation = .vertical
        stackView.alignment = .width
        stackView.spacing = Metrics.itemSpacing
        stackView.edgeInsets = NSEdgeInsets(
            top: Metrics.verticalInset,
            left: Metrics.horizontalInset,
            bottom: Metrics.verticalInset,
            right: Metrics.horizontalInset
        )

        for option in options {
            let checkbox = NSButton(checkboxWithTitle: Self.displayTitle(for: option), target: nil, action: nil)
            checkbox.state = initiallySelectedIDs.contains(option.id) ? .on : .off
            checkbox.setButtonType(.switch)
            checkbox.lineBreakMode = .byTruncatingTail
            checkbox.alignment = .left
            checkbox.toolTip = option.detail ?? option.id
            checkbox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            checkbox.setContentHuggingPriority(.defaultLow, for: .horizontal)
            stackView.addArrangedSubview(checkbox)
            checkbox.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(Metrics.checkboxHeight)
                make.leading.trailing.equalToSuperview()
            }
            buttons.append((option.id, checkbox))
        }

        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = options.count > Metrics.maximumVisibleItems
        scrollView.autohidesScrollers = true
        scrollView.documentView = documentContainer

        documentContainer.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let visibleItemCount = max(1, min(options.count, Metrics.maximumVisibleItems))
        let preferredHeight = CGFloat(visibleItemCount) * Metrics.checkboxHeight
            + CGFloat(max(0, visibleItemCount - 1)) * Metrics.itemSpacing
            + Metrics.verticalInset * 2
        snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(Metrics.minimumWidth)
            make.height.equalTo(max(Metrics.minimumHeight, preferredHeight))
        }

        layoutSubtreeIfNeeded()
        updateDocumentLayout()
    }

    private func updateDocumentLayout() {
        let availableWidth = max(bounds.width, Metrics.minimumWidth)
        let contentHeight = max(ceil(stackView.fittingSize.height), bounds.height, Metrics.minimumHeight)
        documentContainer.frame = NSRect(x: 0, y: 0, width: availableWidth, height: contentHeight)
        documentContainer.layoutSubtreeIfNeeded()
        scrollView.hasVerticalScroller = contentHeight > bounds.height + 0.5
    }

    private static func displayTitle(for option: Option) -> String {
        guard let detail = option.detail, !detail.isEmpty, detail != option.title else {
            return option.title
        }
        return "\(option.title) (\(detail))"
    }
}
