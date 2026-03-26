import Cocoa
import SnapKit

final class APIKeyViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let service: APIKeyService
    private let tableView = NSTableView()
    private let emptyLabel = NSTextField(labelWithString: L10n.APIKeys.emptyState)
    private let nameField = NSTextField()
    private let issuerField = NSTextField()
    private let keyIDField = NSTextField()
    private let dropView = APIKeyDropView()
    private var profiles: [APIKeyRecord] = []
    private var selectedProfile: APIKeyRecord?

    init(service: APIKeyService = APIKeyService(
        runner: ASCCommandRunner(
            configuration: ASCCommandConfiguration(
                settings: .shared,
                workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            ),
            logRepository: DatabaseManager.shared.commandLogRepository
        )
    )) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func presentAsSheet(from window: NSWindow?) {
        let controller = APIKeyViewController()
        let sheet = NSWindow(contentViewController: controller)
        sheet.title = L10n.APIKeys.title
        sheet.styleMask = [.titled, .closable]
        sheet.setContentSize(NSSize(width: 860, height: 520))
        sheet.isReleasedWhenClosed = false

        if let window {
            window.beginSheet(sheet)
        } else {
            let host = NSWindow(contentViewController: controller)
            host.title = L10n.APIKeys.title
            host.setContentSize(NSSize(width: 860, height: 520))
            host.makeKeyAndOrderFront(nil)
        }
    }

    override func loadView() {
        view = NSView()
        buildLayout()
        reloadProfiles()
    }

    private func buildLayout() {
        let splitView = NSSplitView()
        splitView.isVertical = true
        let left = NSView()
        let right = NSView()

        view.addSubview(splitView)
        splitView.addArrangedSubview(left)
        splitView.addArrangedSubview(right)
        splitView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        left.snp.makeConstraints { make in
            make.width.equalTo(250)
        }

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        left.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("profiles"))
        column.title = L10n.APIKeys.title
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 34
        tableView.usesAlternatingRowBackgroundColors = true

        emptyLabel.textColor = .secondaryLabelColor
        left.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(16)
        }

        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 14
        right.addSubview(formStack)
        formStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        nameField.placeholderString = L10n.APIKeys.profileName
        issuerField.placeholderString = L10n.APIKeys.issuerID
        keyIDField.placeholderString = L10n.APIKeys.keyID

        dropView.onPathChange = { [weak self] path in
            self?.dropView.filePath = path
        }

        let validateButton = NSButton(title: L10n.Common.validate, target: self, action: #selector(validateProfile))
        let saveButton = NSButton(title: L10n.Common.save, target: self, action: #selector(saveProfile))
        let activateButton = NSButton(title: L10n.Common.activate, target: self, action: #selector(activateProfile))
        let deleteButton = NSButton(title: L10n.Common.delete, target: self, action: #selector(deleteProfile))
        let closeButton = NSButton(title: L10n.Common.close, target: self, action: #selector(closeSheet))

        let buttonRow = NSStackView(views: [validateButton, saveButton, activateButton, deleteButton, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        formStack.addArrangedSubview(makeFieldRow(title: L10n.APIKeys.profileName, field: nameField))
        formStack.addArrangedSubview(makeFieldRow(title: L10n.APIKeys.issuerID, field: issuerField))
        formStack.addArrangedSubview(makeFieldRow(title: L10n.APIKeys.keyID, field: keyIDField))
        formStack.addArrangedSubview(dropView)
        formStack.addArrangedSubview(buttonRow)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        profiles.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let label = NSTextField(labelWithString: profiles[row].displayName + (profiles[row].isActive ? " • \(L10n.APIKeys.active)" : ""))
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0, tableView.selectedRow < profiles.count else {
            selectedProfile = nil
            return
        }

        let profile = profiles[tableView.selectedRow]
        selectedProfile = profile
        nameField.stringValue = profile.name
        issuerField.stringValue = profile.issuerID
        keyIDField.stringValue = profile.keyID
        dropView.filePath = profile.p8Path
    }

    @objc
    private func validateProfile() {
        Task {
            do {
                _ = try await service.validate(
                    name: nameField.stringValue,
                    issuerID: issuerField.stringValue,
                    keyID: keyIDField.stringValue,
                    privateKeyPath: dropView.filePath
                )
                presentInfo(title: L10n.Common.validate, message: L10n.APIKeys.validationSucceeded)
                if let id = selectedProfile?.id {
                    try? service.markValidationStatus(id: id, success: true, message: L10n.APIKeys.validationSucceeded)
                }
            } catch {
                presentInfo(title: L10n.APIKeys.validationFailed, message: error.localizedDescription)
                if let id = selectedProfile?.id {
                    try? service.markValidationStatus(id: id, success: false, message: error.localizedDescription)
                }
            }
        }
    }

    @objc
    private func saveProfile() {
        do {
            _ = try service.saveProfile(
                id: selectedProfile?.id,
                name: nameField.stringValue,
                issuerID: issuerField.stringValue,
                keyID: keyIDField.stringValue,
                privateKeyPath: dropView.filePath,
                activate: selectedProfile?.isActive ?? profiles.isEmpty
            )
            presentInfo(title: L10n.Common.save, message: L10n.APIKeys.saved)
            reloadProfiles()
        } catch {
            presentInfo(title: L10n.Common.save, message: error.localizedDescription)
        }
    }

    @objc
    private func activateProfile() {
        guard let id = selectedProfile?.id else { return }
        do {
            try service.activateProfile(id: id)
            reloadProfiles()
        } catch {
            presentInfo(title: L10n.Common.activate, message: error.localizedDescription)
        }
    }

    @objc
    private func deleteProfile() {
        guard let id = selectedProfile?.id else { return }
        Task {
            let confirmed = await ConfirmDialogHelper.confirm(
                title: L10n.Common.delete,
                message: L10n.APIKeys.deleteConfirm,
                confirmTitle: L10n.Common.delete,
                on: view.window
            )
            guard confirmed else { return }
            do {
                try service.deleteProfile(id: id)
                selectedProfile = nil
                reloadProfiles()
            } catch {
                presentInfo(title: L10n.Common.delete, message: error.localizedDescription)
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

    private func reloadProfiles() {
        profiles = (try? service.fetchProfiles()) ?? []
        tableView.reloadData()
        emptyLabel.isHidden = !profiles.isEmpty
        if let first = profiles.first, selectedProfile == nil {
            selectedProfile = first
            nameField.stringValue = first.name
            issuerField.stringValue = first.issuerID
            keyIDField.stringValue = first.keyID
            dropView.filePath = first.p8Path
        }
    }

    private func makeFieldRow(title: String, field: NSTextField) -> NSView {
        let container = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        container.addSubview(label)
        container.addSubview(field)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(140)
        }
        field.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(label)
        }
        return container
    }

    private func presentInfo(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        if let window = view.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
