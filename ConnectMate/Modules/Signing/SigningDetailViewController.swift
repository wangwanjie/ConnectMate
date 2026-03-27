import Cocoa
import SnapKit

@MainActor
final class SigningDetailViewController: NSViewController {
    var onRefreshRequested: ((SigningAssetCategory) -> Void)?
    var onPrimaryActionRequested: ((SigningAssetCategory) -> Void)?
    var onCertificateActivationRequested: ((CertificateSummary, Bool) -> Void)?
    var onCertificateRevokeRequested: ((CertificateSummary) -> Void)?
    var onDeviceStatusRequested: ((RegisteredDeviceSummary, Bool) -> Void)?
    var onProfileDownloadRequested: ((ProvisioningProfileSummary) -> Void)?
    var onProfileDeleteRequested: ((ProvisioningProfileSummary) -> Void)?

    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(wrappingLabelWithString: "")
    private let actionRow = NSStackView()
    private let contentStack = NSStackView()
    private let emptyStateView = EmptyStateView(symbolName: "checkmark.seal", title: "", detail: "")

    private var renderedCategory: SigningAssetCategory = .bundleIDs
    private var renderedItem: SigningAssetItem?

    override func loadView() {
        view = ThemedBackgroundView { appearance in
            NSColor.windowBackgroundColor.resolvedColor(with: appearance)
        }
        buildLayout()
        render(category: .bundleIDs, item: nil)
    }

    func render(category: SigningAssetCategory, item: SigningAssetItem?) {
        renderedCategory = category
        renderedItem = item

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        actionRow.arrangedSubviews.forEach {
            actionRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        titleLabel.stringValue = item?.title ?? category.title
        subtitleLabel.stringValue = item?.subtitle ?? L10n.Signing.noSelectionDetail
        emptyStateView.update(
            symbolName: category.symbolName,
            title: item == nil ? L10n.Signing.noSelectionTitle : category.title,
            detail: item == nil ? L10n.Signing.noSelectionDetail : item?.subtitle ?? ""
        )

        emptyStateView.isHidden = item != nil
        contentStack.isHidden = item == nil

        let refreshButton = NSButton(title: L10n.Signing.refresh, target: self, action: #selector(handleRefresh))
        let primaryButton = NSButton(title: category.primaryActionTitle, target: self, action: #selector(handlePrimaryAction))
        actionRow.addArrangedSubview(refreshButton)
        actionRow.addArrangedSubview(primaryButton)

        switch item {
        case .bundleID(let bundleID):
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.identifier, value: bundleID.identifier))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.name, value: bundleID.name))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.platform, value: bundleID.platform))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.seedID, value: bundleID.seedID ?? L10n.Apps.unavailable))
        case .certificate(let certificate):
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.name, value: certificate.name))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.type, value: certificate.certificateType))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.displayName, value: certificate.displayName ?? L10n.Apps.unavailable))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.serialNumber, value: certificate.serialNumber ?? L10n.Apps.unavailable))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.expirationDate, value: certificate.expirationDate ?? L10n.Apps.unavailable))

            let activeButton = NSButton(
                title: L10n.Signing.activate,
                target: self,
                action: #selector(handleToggleCertificateActivation)
            )
            activeButton.identifier = NSUserInterfaceItemIdentifier("certificate.activate")
            let revokeButton = NSButton(title: L10n.Signing.revoke, target: self, action: #selector(handleRevokeCertificate))
            actionRow.addArrangedSubview(activeButton)
            actionRow.addArrangedSubview(revokeButton)
        case .device(let device):
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.name, value: device.name))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.udid, value: device.udid))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.platform, value: device.platform))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.status, value: device.status))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.deviceClass, value: device.deviceClass ?? L10n.Apps.unavailable))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.model, value: device.model ?? L10n.Apps.unavailable))
            let statusButton = NSButton(
                title: device.status.uppercased() == "ENABLED" ? L10n.Signing.disable : L10n.Signing.activate,
                target: self,
                action: #selector(handleToggleDeviceStatus)
            )
            actionRow.addArrangedSubview(statusButton)
        case .profile(let profile):
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.name, value: profile.name))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.type, value: profile.profileType))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.platform, value: profile.platform ?? L10n.Apps.unavailable))
            contentStack.addArrangedSubview(makeValueRow(title: L10n.Signing.profileState, value: profile.profileState ?? L10n.Apps.unavailable))

            let downloadButton = NSButton(title: L10n.Signing.download, target: self, action: #selector(handleDownloadProfile))
            let deleteButton = NSButton(title: L10n.Common.delete, target: self, action: #selector(handleDeleteProfile))
            actionRow.addArrangedSubview(downloadButton)
            actionRow.addArrangedSubview(deleteButton)
        case nil:
            break
        }
    }

    @objc
    private func handleRefresh() {
        onRefreshRequested?(renderedCategory)
    }

    @objc
    private func handlePrimaryAction() {
        onPrimaryActionRequested?(renderedCategory)
    }

    @objc
    private func handleToggleCertificateActivation() {
        guard case .certificate(let certificate) = renderedItem else { return }
        onCertificateActivationRequested?(certificate, true)
    }

    @objc
    private func handleRevokeCertificate() {
        guard case .certificate(let certificate) = renderedItem else { return }
        onCertificateRevokeRequested?(certificate)
    }

    @objc
    private func handleToggleDeviceStatus() {
        guard case .device(let device) = renderedItem else { return }
        onDeviceStatusRequested?(device, device.status.uppercased() != "ENABLED")
    }

    @objc
    private func handleDownloadProfile() {
        guard case .profile(let profile) = renderedItem else { return }
        onProfileDownloadRequested?(profile)
    }

    @objc
    private func handleDeleteProfile() {
        guard case .profile(let profile) = renderedItem else { return }
        onProfileDeleteRequested?(profile)
    }

    private func buildLayout() {
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2

        actionRow.orientation = .horizontal
        actionRow.alignment = .centerY
        actionRow.spacing = 10

        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 12

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(actionRow)
        view.addSubview(contentStack)
        view.addSubview(emptyStateView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(28)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        actionRow.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(18)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        contentStack.snp.makeConstraints { make in
            make.top.equalTo(actionRow.snp.bottom).offset(20)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }

    private func makeValueRow(title: String, value: String) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.snp.makeConstraints { make in
            make.width.equalTo(120)
        }

        let valueLabel = NSTextField(wrappingLabelWithString: value)
        valueLabel.maximumNumberOfLines = 2

        let row = NSStackView(views: [titleLabel, valueLabel])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 12
        return row
    }
}
