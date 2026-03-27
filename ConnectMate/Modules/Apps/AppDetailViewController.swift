import Cocoa
import SnapKit

@MainActor
final class AppDetailViewController: NSViewController {
    private let emptyStateView = EmptyStateView(
        symbolName: "app.badge",
        title: L10n.Apps.noSelectionTitle,
        detail: L10n.Apps.noSelectionDetail
    )
    private let contentView = NSView()
    private let iconView = AsyncImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let detailsStack = NSStackView()
    private var valueLabels: [String: NSTextField] = [:]

    override func loadView() {
        view = ThemedBackgroundView { appearance in
            NSColor.windowBackgroundColor.resolvedColor(with: appearance)
        }

        iconView.image = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 46, weight: .medium)
        iconView.contentTintColor = .controlAccentColor

        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor

        detailsStack.orientation = .vertical
        detailsStack.spacing = 14
        detailsStack.alignment = .leading

        let headerStack = NSStackView(views: [iconView, makeHeaderTextStack()])
        headerStack.orientation = .horizontal
        headerStack.spacing = 16
        headerStack.alignment = .top

        contentView.addSubview(headerStack)
        contentView.addSubview(detailsStack)
        view.addSubview(emptyStateView)
        view.addSubview(contentView)

        headerStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(72)
        }

        detailsStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(24)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
        }

        configureDetailRows()
        clearSelection()
    }

    func render(app: AppSummary?) {
        guard let app else {
            clearSelection()
            return
        }

        emptyStateView.isHidden = true
        contentView.isHidden = false
        titleLabel.stringValue = app.name
        subtitleLabel.stringValue = app.bundleID
        iconView.load(from: app.iconURL, placeholder: NSImage(systemSymbolName: "app.fill", accessibilityDescription: app.name))
        valueLabels[L10n.Apps.bundleID]?.stringValue = app.bundleID
        valueLabels[L10n.Apps.platform]?.stringValue = app.platform
        valueLabels[L10n.Apps.state]?.stringValue = app.appState ?? L10n.Apps.unavailable
        valueLabels[L10n.Apps.sku]?.stringValue = app.sku ?? L10n.Apps.unavailable
        valueLabels[L10n.Apps.appID]?.stringValue = app.id
        valueLabels[L10n.Apps.cachedAt]?.stringValue = DateFormatter.localizedString(
            from: app.cachedAt,
            dateStyle: .medium,
            timeStyle: .short
        )
    }

    func clearSelection() {
        emptyStateView.isHidden = false
        contentView.isHidden = true
        titleLabel.stringValue = ""
        subtitleLabel.stringValue = ""
    }

    private func makeHeaderTextStack() -> NSView {
        let stack = NSStackView(views: [titleLabel, subtitleLabel])
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        return stack
    }

    private func configureDetailRows() {
        [
            L10n.Apps.bundleID,
            L10n.Apps.platform,
            L10n.Apps.state,
            L10n.Apps.sku,
            L10n.Apps.appID,
            L10n.Apps.cachedAt
        ].forEach { title in
            let valueLabel = NSTextField(labelWithString: "")
            valueLabel.font = .systemFont(ofSize: 13)
            valueLabel.lineBreakMode = .byTruncatingMiddle
            valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            valueLabels[title] = valueLabel
            detailsStack.addArrangedSubview(makeRow(title: title, value: valueLabel))
        }
    }

    private func makeRow(title: String, value: NSTextField) -> NSView {
        let container = NSView()
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor

        container.addSubview(titleLabel)
        container.addSubview(value)

        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(96)
        }

        value.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
        }

        return container
    }
}
