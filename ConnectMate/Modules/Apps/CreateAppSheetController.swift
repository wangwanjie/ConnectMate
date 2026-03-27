import Cocoa
import SnapKit

@MainActor
final class CreateAppSheetController: NSViewController {
    private let service: AppService
    private let onCreated: (AppService.CreateAppRequest) -> Void

    private let nameField = NSTextField()
    private let bundleIDField = NSTextField()
    private let skuField = NSTextField()
    private let primaryLocaleField = NSTextField(string: "zh-Hans")
    private let platformPopup = NSPopUpButton()

    init(
        service: AppService,
        onCreated: @escaping (AppService.CreateAppRequest) -> Void
    ) {
        self.service = service
        self.onCreated = onCreated
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func presentAsSheet(
        from window: NSWindow?,
        service: AppService,
        onCreated: @escaping (AppService.CreateAppRequest) -> Void
    ) {
        let controller = CreateAppSheetController(service: service, onCreated: onCreated)
        let sheet = NSWindow(contentViewController: controller)
        sheet.title = L10n.Apps.createTitle
        sheet.styleMask = [.titled, .closable]
        sheet.setContentSize(NSSize(width: 520, height: 320))
        sheet.isReleasedWhenClosed = false

        if let window {
            window.beginSheet(sheet)
        } else {
            let host = NSWindow(contentViewController: controller)
            host.title = L10n.Apps.createTitle
            host.setContentSize(NSSize(width: 520, height: 320))
            host.makeKeyAndOrderFront(nil)
        }
    }

    override func loadView() {
        view = NSView()
        buildLayout()
    }

    private func buildLayout() {
        let titleLabel = NSTextField(labelWithString: L10n.Apps.createTitle)
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let hintLabel = NSTextField(wrappingLabelWithString: L10n.Apps.createHint)
        hintLabel.textColor = .secondaryLabelColor

        platformPopup.addItems(withTitles: [
            L10n.Apps.defaultPlatform,
            "IOS",
            "MAC_OS",
            "TV_OS",
            "UNIVERSAL"
        ])

        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 12

        formStack.addArrangedSubview(makeRow(title: L10n.Apps.name, control: nameField))
        formStack.addArrangedSubview(makeRow(title: L10n.Apps.bundleID, control: bundleIDField))
        formStack.addArrangedSubview(makeRow(title: L10n.Apps.sku, control: skuField))
        formStack.addArrangedSubview(makeRow(title: L10n.Apps.primaryLocale, control: primaryLocaleField))
        formStack.addArrangedSubview(makeRow(title: L10n.Apps.platform, control: platformPopup))

        let cancelButton = NSButton(title: L10n.Common.cancel, target: self, action: #selector(closeSheet))
        let createButton = NSButton(title: L10n.Common.create, target: self, action: #selector(handleCreate))
        createButton.keyEquivalent = "\r"

        let buttonRow = NSStackView(views: [cancelButton, createButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        view.addSubview(titleLabel)
        view.addSubview(hintLabel)
        view.addSubview(formStack)
        view.addSubview(buttonRow)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        formStack.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        buttonRow.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(formStack.snp.bottom).offset(16)
            make.trailing.bottom.equalToSuperview().inset(20)
        }
    }

    @objc
    private func handleCreate() {
        let request = AppService.CreateAppRequest(
            name: nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            bundleID: bundleIDField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            sku: skuField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            primaryLocale: primaryLocaleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: selectedPlatform
        )

        Task { [weak self] in
            guard let self else { return }

            do {
                _ = try await service.createApp(request)
                await MainActor.run {
                    self.onCreated(request)
                    self.closeSheet()
                }
            } catch {
                await MainActor.run {
                    self.presentCreationError(error)
                }
            }
        }
    }

    @objc
    private func closeSheet() {
        if let sheetParent = view.window?.sheetParent, let window = view.window {
            sheetParent.endSheet(window)
        } else {
            view.window?.close()
        }
    }

    private var selectedPlatform: String? {
        let title = platformPopup.titleOfSelectedItem ?? ""
        return title == L10n.Apps.defaultPlatform ? nil : title
    }

    private func makeRow(title: String, control: NSView) -> NSView {
        let container = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)

        container.addSubview(label)
        container.addSubview(control)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(120)
        }

        control.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(label)
        }

        return container
    }

    private func presentCreationError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = L10n.Apps.createTitle
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.Common.ok)

        if let window = view.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
