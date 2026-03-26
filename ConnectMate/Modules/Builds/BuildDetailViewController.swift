import Cocoa
import SnapKit

@MainActor
final class BuildDetailViewController: NSViewController {
    private let emptyStateView = EmptyStateView(
        symbolName: "shippingbox",
        title: L10n.Builds.noSelectionTitle,
        detail: L10n.Builds.noSelectionDetail
    )
    private let contentView = NSView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let detailsStack = NSStackView()
    private var valueLabels: [String: NSTextField] = [:]

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor

        detailsStack.orientation = .vertical
        detailsStack.spacing = 14
        detailsStack.alignment = .leading

        let headerStack = NSStackView(views: [titleLabel, subtitleLabel])
        headerStack.orientation = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .leading

        contentView.addSubview(headerStack)
        contentView.addSubview(detailsStack)
        view.addSubview(emptyStateView)
        view.addSubview(contentView)

        headerStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
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

    func render(build: BuildSummary?) {
        guard let build else {
            clearSelection()
            return
        }

        emptyStateView.isHidden = true
        contentView.isHidden = false
        titleLabel.stringValue = "\(build.version) (\(build.buildNumber))"
        subtitleLabel.stringValue = build.processingState.title
        subtitleLabel.textColor = build.processingState.tintColor
        valueLabels[L10n.Builds.version]?.stringValue = build.version
        valueLabels[L10n.Builds.buildNumber]?.stringValue = build.buildNumber
        valueLabels[L10n.Builds.status]?.stringValue = build.processingState.title
        valueLabels[L10n.Builds.platform]?.stringValue = build.platform ?? L10n.Builds.unavailable
        valueLabels[L10n.Builds.uploadedAt]?.stringValue = Self.localizedTimestamp(build.uploadedAt)
        valueLabels[L10n.Builds.cachedAt]?.stringValue = Self.localizedTimestamp(build.cachedAt)
        valueLabels[L10n.Builds.buildID]?.stringValue = build.id
        valueLabels[L10n.Builds.appID]?.stringValue = build.appID
        valueLabels[L10n.Builds.expired]?.stringValue = build.isExpired ? L10n.Builds.Status.expired : L10n.Builds.Status.valid
    }

    func clearSelection() {
        emptyStateView.isHidden = false
        contentView.isHidden = true
        titleLabel.stringValue = ""
        subtitleLabel.stringValue = ""
    }

    private func configureDetailRows() {
        [
            L10n.Builds.version,
            L10n.Builds.buildNumber,
            L10n.Builds.status,
            L10n.Builds.platform,
            L10n.Builds.uploadedAt,
            L10n.Builds.cachedAt,
            L10n.Builds.buildID,
            L10n.Builds.appID,
            L10n.Builds.expired
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

    private static func localizedTimestamp(_ date: Date?) -> String {
        guard let date else {
            return L10n.Builds.unavailable
        }

        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
}
