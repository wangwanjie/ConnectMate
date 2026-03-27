import Cocoa
import SnapKit

@MainActor
final class CreateVersionSheetController: NSViewController {
    private let service: BuildService
    private let apps: [AppRecord]
    private let onCreated: (BuildService.CreateVersionRequest) -> Void

    private let appPopup = NSPopUpButton()
    private let versionField = NSTextField()
    private let platformPopup = NSPopUpButton()

    init(
        service: BuildService,
        apps: [AppRecord],
        selectedAppID: String?,
        onCreated: @escaping (BuildService.CreateVersionRequest) -> Void
    ) {
        self.service = service
        self.apps = apps
        self.onCreated = onCreated
        super.init(nibName: nil, bundle: nil)

        for app in apps {
            appPopup.addItem(withTitle: "\(app.name) (\(app.bundleID))")
            appPopup.lastItem?.representedObject = app.ascID
        }

        if let selectedAppID,
           let index = apps.firstIndex(where: { $0.ascID == selectedAppID }) {
            appPopup.selectItem(at: index)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func presentAsSheet(
        from window: NSWindow?,
        service: BuildService,
        apps: [AppRecord],
        selectedAppID: String?,
        onCreated: @escaping (BuildService.CreateVersionRequest) -> Void
    ) {
        let controller = CreateVersionSheetController(
            service: service,
            apps: apps,
            selectedAppID: selectedAppID,
            onCreated: onCreated
        )
        let sheet = NSWindow(contentViewController: controller)
        sheet.title = L10n.Builds.addVersionTitle
        sheet.styleMask = [.titled, .closable]
        sheet.setContentSize(NSSize(width: 520, height: 250))
        sheet.isReleasedWhenClosed = false

        if let window {
            window.beginSheet(sheet)
        } else {
            let host = NSWindow(contentViewController: controller)
            host.title = L10n.Builds.addVersionTitle
            host.setContentSize(NSSize(width: 520, height: 250))
            host.makeKeyAndOrderFront(nil)
        }
    }

    override func loadView() {
        view = NSView()
        buildLayout()
    }

    private func buildLayout() {
        let titleLabel = NSTextField(labelWithString: L10n.Builds.addVersionTitle)
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        platformPopup.addItems(withTitles: [
            L10n.Builds.defaultPlatform,
            "IOS",
            "MAC_OS",
            "TV_OS",
            "VISION_OS"
        ])

        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 12

        formStack.addArrangedSubview(makeRow(title: L10n.Builds.appFilter, control: appPopup))
        formStack.addArrangedSubview(makeRow(title: L10n.Builds.versionString, control: versionField))
        formStack.addArrangedSubview(makeRow(title: L10n.Builds.platform, control: platformPopup))

        let cancelButton = NSButton(title: L10n.Common.cancel, target: self, action: #selector(closeSheet))
        let addButton = NSButton(title: L10n.Common.add, target: self, action: #selector(handleAdd))
        addButton.keyEquivalent = "\r"

        let buttonRow = NSStackView(views: [cancelButton, addButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        view.addSubview(titleLabel)
        view.addSubview(formStack)
        view.addSubview(buttonRow)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        formStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        buttonRow.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(formStack.snp.bottom).offset(16)
            make.trailing.bottom.equalToSuperview().inset(20)
        }
    }

    @objc
    private func handleAdd() {
        let request = BuildService.CreateVersionRequest(
            appID: selectedAppID,
            versionString: versionField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: selectedPlatform
        )

        Task { [weak self] in
            guard let self else { return }

            do {
                _ = try await service.createVersion(request)
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

    private var selectedAppID: String {
        (appPopup.selectedItem?.representedObject as? String) ?? ""
    }

    private var selectedPlatform: String? {
        let title = platformPopup.titleOfSelectedItem ?? ""
        return title == L10n.Builds.defaultPlatform ? nil : title
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
        alert.messageText = L10n.Builds.addVersionTitle
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
