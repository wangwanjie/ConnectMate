import Cocoa
import SnapKit

private final class SigningActionHandler: NSObject {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc
    func invoke() {
        action()
    }
}

@MainActor
final class SigningListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onSelectItem: ((SigningAssetCategory, SigningAssetItem?) -> Void)?

    private let service: SigningAssetsService
    private let settings: AppSettings

    private let titleLabel = NSTextField(labelWithString: L10n.Signing.title)
    private let categoryControl = NSSegmentedControl()
    private let refreshButton = NSButton(title: L10n.Signing.refresh, target: nil, action: nil)
    private let primaryButton = NSButton(title: "", target: nil, action: nil)
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let loadingView = LoadingView(title: L10n.Signing.loading)
    private lazy var errorStateView = ErrorStateView(
        title: L10n.Signing.loadFailed,
        detail: "",
        actionTitle: L10n.Signing.refresh,
        actionHandler: { [weak self] in
            self?.refreshCurrentCategory()
        }
    )
    private let emptyStateView = EmptyStateView(symbolName: "checkmark.seal", title: "", detail: "")

    private var currentCategory: SigningAssetCategory = .bundleIDs
    private var items: [SigningAssetItem] = []
    private var selectedItemID: String?
    private var hasLoadedInitialData = false
    private var isRefreshingContent = false
    private var isPerformingAction = false
    private var isShowingErrorState = false
    private var actionHandlers: [SigningActionHandler] = []

    init(service: SigningAssetsService? = nil, settings: AppSettings? = nil) {
        self.service = service ?? .makeDefault()
        self.settings = settings ?? .shared
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = ThemedBackgroundView { appearance in
            NSColor.controlBackgroundColor.resolvedColor(with: appearance)
        }
        buildLayout()
        applyCategorySelection()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true
        refreshCurrentCategory()
    }

    func refreshCurrentCategory() {
        setRefreshingContent(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let loadedItems = try await self.loadItems(for: self.currentCategory)
                await MainActor.run {
                    self.apply(items: loadedItems)
                    self.setRefreshingContent(false)
                }
            } catch {
                await MainActor.run {
                    self.items = []
                    self.tableView.reloadData()
                    self.showError(error.localizedDescription)
                    self.setRefreshingContent(false)
                }
            }
        }
    }

    func presentPrimaryActionSheet(from window: NSWindow?) {
        switch currentCategory {
        case .bundleIDs:
            presentCreateBundleID(from: window)
        case .certificates:
            presentCreateCertificate(from: window)
        case .devices:
            presentRegisterDevice(from: window)
        case .profiles:
            presentCreateProfile(from: window)
        }
    }

    func requestCertificateActivation(_ certificate: CertificateSummary, activated: Bool) {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.service.updateCertificateActivation(id: certificate.id, activated: activated)
                await MainActor.run {
                    ToastManager.show(message: L10n.Signing.actionSucceeded, in: self.view)
                    self.refreshCurrentCategory()
                }
            } catch {
                await MainActor.run {
                    ToastManager.show(message: error.localizedDescription, in: self.view)
                }
            }
        }
    }

    func requestCertificateRevoke(_ certificate: CertificateSummary) {
        performConfirmedAction(
            title: L10n.Signing.revoke,
            message: certificate.name
        ) { [weak self] in
            guard let self else { return }
            _ = try await self.service.revokeCertificate(id: certificate.id)
            await MainActor.run {
                ToastManager.show(message: L10n.Signing.actionSucceeded, in: self.view)
                self.refreshCurrentCategory()
            }
        }
    }

    func requestDeviceStatusChange(_ device: RegisteredDeviceSummary, enabled: Bool) {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.service.updateDevice(
                    id: device.id,
                    name: nil,
                    status: enabled ? "ENABLED" : "DISABLED"
                )
                await MainActor.run {
                    ToastManager.show(message: L10n.Signing.actionSucceeded, in: self.view)
                    self.refreshCurrentCategory()
                }
            } catch {
                await MainActor.run {
                    ToastManager.show(message: error.localizedDescription, in: self.view)
                }
            }
        }
    }

    func requestProfileDownload(_ profile: ProvisioningProfileSummary) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(profile.name).mobileprovision"
        panel.title = L10n.Signing.download

        let handler: (URL) -> Void = { [weak self] destinationURL in
            guard let self else { return }
            Task {
                do {
                    _ = try await self.service.downloadProfile(id: profile.id, outputPath: destinationURL.path)
                    await MainActor.run {
                        ToastManager.show(message: destinationURL.path, in: self.view)
                    }
                } catch {
                    await MainActor.run {
                        ToastManager.show(message: error.localizedDescription, in: self.view)
                    }
                }
            }
        }

        if let window = view.window {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                handler(url)
            }
        } else if panel.runModal() == .OK, let url = panel.url {
            handler(url)
        }
    }

    func requestProfileDelete(_ profile: ProvisioningProfileSummary) {
        performConfirmedAction(
            title: L10n.Common.delete,
            message: profile.name
        ) { [weak self] in
            guard let self else { return }
            _ = try await self.service.deleteProfile(id: profile.id)
            await MainActor.run {
                ToastManager.show(message: L10n.Signing.actionSucceeded, in: self.view)
                self.refreshCurrentCategory()
            }
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        max(settings.listRowDensity.tableRowHeight + 12, 46)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0, row < items.count else { return nil }

        let item = items[row]
        let cell = NSTableCellView()

        let title = NSTextField(labelWithString: item.title)
        title.font = .systemFont(ofSize: 13, weight: .medium)
        title.lineBreakMode = .byTruncatingTail

        let subtitle = NSTextField(labelWithString: item.subtitle)
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byTruncatingTail

        let stack = NSStackView(views: [title, subtitle])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4

        cell.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let item = selectedItem
        selectedItemID = item?.id
        onSelectItem?(currentCategory, item)
    }

    @objc
    private func handleRefresh() {
        refreshCurrentCategory()
    }

    @objc
    private func handlePrimaryAction() {
        presentPrimaryActionSheet(from: view.window)
    }

    @objc
    private func handleCategoryChange(_ sender: NSSegmentedControl) {
        guard sender.selectedSegment >= 0, sender.selectedSegment < SigningAssetCategory.allCases.count else {
            return
        }
        currentCategory = SigningAssetCategory.allCases[sender.selectedSegment]
        selectedItemID = nil
        applyCategorySelection()
        refreshCurrentCategory()
    }

    private func buildLayout() {
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)

        categoryControl.segmentCount = SigningAssetCategory.allCases.count
        for category in SigningAssetCategory.allCases {
            categoryControl.setLabel(category.title, forSegment: category.rawValue)
        }
        categoryControl.selectedSegment = currentCategory.rawValue
        categoryControl.target = self
        categoryControl.action = #selector(handleCategoryChange(_:))

        refreshButton.target = self
        refreshButton.action = #selector(handleRefresh)

        primaryButton.target = self
        primaryButton.action = #selector(handlePrimaryAction)

        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = self
        tableView.dataSource = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("item"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        view.addSubview(titleLabel)
        view.addSubview(refreshButton)
        view.addSubview(primaryButton)
        view.addSubview(categoryControl)
        view.addSubview(scrollView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingView)
        view.addSubview(errorStateView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(24)
        }

        refreshButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(titleLabel)
        }

        primaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(refreshButton.snp.leading).offset(-12)
            make.centerY.equalTo(refreshButton)
        }

        categoryControl.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(primaryButton.snp.leading).offset(-12)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(categoryControl.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(scrollView)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalTo(scrollView)
        }

        errorStateView.snp.makeConstraints { make in
            make.center.equalTo(scrollView)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        emptyStateView.isHidden = true
        loadingView.isHidden = true
        errorStateView.isHidden = true
    }

    private func applyCategorySelection() {
        categoryControl.selectedSegment = currentCategory.rawValue
        primaryButton.title = currentCategory.primaryActionTitle
        emptyStateView.update(
            symbolName: currentCategory.symbolName,
            title: currentCategory.title,
            detail: currentCategory.emptyDetail
        )
    }

    private func apply(items: [SigningAssetItem]) {
        self.items = items
        isShowingErrorState = false
        tableView.reloadData()
        updateVisibleState()

        if let selectedIndex = items.firstIndex(where: { $0.id == selectedItemID }) ?? (hasItems ? 0 : nil) {
            tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
            let item = items[selectedIndex]
            selectedItemID = item.id
            onSelectItem?(currentCategory, item)
        } else {
            onSelectItem?(currentCategory, nil)
        }
    }

    private var hasItems: Bool {
        !items.isEmpty
    }

    private func setRefreshingContent(_ loading: Bool) {
        isRefreshingContent = loading
        if loading {
            loadingView.update(title: L10n.Signing.loading)
        }
        updateVisibleState()
    }

    private func setPerformingAction(_ performing: Bool, title: String) {
        isPerformingAction = performing
        if performing {
            loadingView.update(title: title)
        } else if isRefreshingContent {
            loadingView.update(title: L10n.Signing.loading)
        }
        updateVisibleState()
    }

    private func updateVisibleState() {
        loadingView.isHidden = !(isRefreshingContent || isPerformingAction)
        refreshButton.isEnabled = !isPerformingAction
        primaryButton.isEnabled = !isPerformingAction
        categoryControl.isEnabled = !isPerformingAction
        tableView.isEnabled = !isPerformingAction

        if isRefreshingContent {
            scrollView.isHidden = true
            emptyStateView.isHidden = true
            errorStateView.isHidden = true
            return
        }

        if isShowingErrorState {
            scrollView.isHidden = true
            emptyStateView.isHidden = true
            errorStateView.isHidden = false
            return
        }

        scrollView.isHidden = !hasItems
        emptyStateView.isHidden = hasItems
        errorStateView.isHidden = true
    }

    private func showError(_ detail: String) {
        errorStateView.updateDetail(detail)
        isShowingErrorState = true
        updateVisibleState()
        onSelectItem?(currentCategory, nil)
    }

    private func loadItems(for category: SigningAssetCategory) async throws -> [SigningAssetItem] {
        switch category {
        case .bundleIDs:
            let results = try await service.listBundleIDs()
            return results.map(SigningAssetItem.bundleID)
        case .certificates:
            let results = try await service.listCertificates()
            return results.map(SigningAssetItem.certificate)
        case .devices:
            let results = try await service.listDevices()
            return results.map(SigningAssetItem.device)
        case .profiles:
            let results = try await service.listProfiles()
            return results.map(SigningAssetItem.profile)
        }
    }

    private var selectedItem: SigningAssetItem? {
        let row = tableView.selectedRow
        guard row >= 0, row < items.count else { return nil }
        return items[row]
    }

    private func performConfirmedAction(
        title: String,
        message: String,
        action: @escaping @Sendable () async throws -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let confirmed: Bool
            if self.settings.requiresActionConfirmation {
                confirmed = await ConfirmDialogHelper.confirm(
                    title: title,
                    message: message,
                    confirmTitle: title,
                    cancelTitle: L10n.Common.cancel,
                    on: self.view.window
                )
            } else {
                confirmed = true
            }
            guard confirmed else { return }

            do {
                try await action()
            } catch {
                ToastManager.show(message: error.localizedDescription, in: self.view)
            }
        }
    }

    private func presentCreateBundleID(from window: NSWindow?) {
        let nameField = NSTextField()
        let identifierField = NSTextField()
        let platformPopup = NSPopUpButton()
        platformPopup.addItems(withTitles: ["MAC_OS", "IOS", "TV_OS", "UNIVERSAL"])

        let accessory = SigningAlertAccessoryFactory.makeContainer(rows: [
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.name, control: nameField),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.identifier, control: identifierField),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.platform, control: platformPopup)
        ])

        presentAccessoryAlert(
            title: L10n.Signing.createBundleIDTitle,
            accessoryView: accessory,
            from: window
        ) { [weak self] in
            guard let self else { return }
            let request = await MainActor.run {
                SigningAssetsService.CreateBundleIDRequest(
                    identifier: identifierField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    name: nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    platform: platformPopup.titleOfSelectedItem
                )
            }
            _ = try await self.service.createBundleID(request)
            let createdBundleID = try await self.resolveBundleIDSummary(identifier: request.identifier)
            await MainActor.run {
                ToastManager.show(message: L10n.Signing.createSucceeded, in: self.view)
                self.refreshCurrentCategory()
                self.presentConfigureCapabilities(for: createdBundleID, from: window)
            }
        }
    }

    private func presentCreateCertificate(from window: NSWindow?) {
        let typePopup = NSPopUpButton()
        typePopup.addItems(withTitles: SigningCLIOptions.certificateTypes)
        typePopup.selectItem(withTitle: "MAC_APP_DEVELOPMENT")
        let commonNameField = NSTextField(string: "\(L10n.App.name) Signing")
        let csrPathField = NSTextField()
        let keyOutputField = NSTextField()
        let generatedCSRPathField = NSTextField()
        let browseCSRButton = makeActionButton(title: L10n.Common.browse) { [weak self, weak csrPathField] in
            guard let self, let csrPathField else { return }
            self.chooseExistingFile(into: csrPathField, from: window)
        }
        let browseKeyOutputButton = makeActionButton(title: L10n.Common.browse) { [weak self, weak keyOutputField] in
            guard let self, let keyOutputField else { return }
            self.chooseSavePath(into: keyOutputField, suggestedName: "ConnectMateSigning.key", from: window)
        }
        let browseGeneratedCSRButton = makeActionButton(title: L10n.Common.browse) { [weak self, weak generatedCSRPathField] in
            guard let self, let generatedCSRPathField else { return }
            self.chooseSavePath(into: generatedCSRPathField, suggestedName: "ConnectMateSigning.csr", from: window)
        }
        let generateCSRButton = makeActionButton(title: L10n.Signing.generateCSR) { [weak self, weak commonNameField, weak keyOutputField, weak generatedCSRPathField, weak csrPathField] in
            guard
                let self,
                let commonNameField,
                let keyOutputField,
                let generatedCSRPathField,
                let csrPathField
            else { return }

            let commonName = commonNameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let keyOutputPath = keyOutputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let csrOutputPath = generatedCSRPathField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !commonName.isEmpty, !keyOutputPath.isEmpty, !csrOutputPath.isEmpty else {
                ToastManager.show(message: L10n.Signing.generateCSRMissingFields, in: self.view)
                return
            }

            self.setPerformingAction(true, title: L10n.Signing.generateCSR)
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await self.service.generateCSR(
                        .init(
                            commonName: commonName,
                            keyOutputPath: keyOutputPath,
                            csrOutputPath: csrOutputPath
                        )
                    )
                    await MainActor.run {
                        csrPathField.stringValue = csrOutputPath
                        ToastManager.show(message: L10n.Signing.csrGenerated, in: self.view)
                    }
                } catch {
                    await MainActor.run {
                        ToastManager.show(message: error.localizedDescription, in: self.view)
                    }
                }
                await MainActor.run {
                    self.setPerformingAction(false, title: L10n.Signing.loading)
                }
            }
        }

        let accessory = SigningAlertAccessoryFactory.makeContainer(rows: [
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.type, control: typePopup),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.csrPath, control: makeTrailingButtonControl(field: csrPathField, button: browseCSRButton)),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.commonName, control: commonNameField),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.privateKeyOutputPath, control: makeTrailingButtonControl(field: keyOutputField, button: browseKeyOutputButton)),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.generatedCSRPath, control: makeTrailingButtonControl(field: generatedCSRPathField, button: browseGeneratedCSRButton)),
            SigningAlertAccessoryFactory.makeRow(title: "", control: makeButtonRow(buttons: [generateCSRButton])),
            SigningAlertAccessoryFactory.makeHintLabel(L10n.Signing.certificateHint)
        ])

        presentAccessoryAlert(
            title: L10n.Signing.createCertificateTitle,
            accessoryView: accessory,
            from: window
        ) { [weak self] in
            guard let self else { return }
            let request = await MainActor.run {
                SigningAssetsService.CreateCertificateRequest(
                    certificateType: typePopup.titleOfSelectedItem ?? "MAC_APP_DEVELOPMENT",
                    csrPath: csrPathField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            _ = try await self.service.createCertificate(request)
            await MainActor.run {
                ToastManager.show(message: L10n.Signing.createSucceeded, in: self.view)
                self.refreshCurrentCategory()
            }
        }
    }

    private func presentRegisterDevice(from window: NSWindow?) {
        let nameField = NSTextField()
        let platformPopup = NSPopUpButton()
        platformPopup.addItems(withTitles: ["MAC_OS", "IOS"])
        let udidField = NSTextField()
        let currentMachineCheckbox = NSButton(checkboxWithTitle: L10n.Signing.useCurrentMachineUDID, target: nil, action: nil)
        udidField.placeholderString = "UDID"

        let accessory = SigningAlertAccessoryFactory.makeContainer(rows: [
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.name, control: nameField),
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.platform, control: platformPopup),
            currentMachineCheckbox,
            SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.udid, control: udidField)
        ])

        presentAccessoryAlert(
            title: L10n.Signing.registerDeviceTitle,
            accessoryView: accessory,
            from: window
        ) { [weak self] in
            guard let self else { return }
            let request = await MainActor.run {
                SigningAssetsService.RegisterDeviceRequest(
                    name: nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    platform: platformPopup.titleOfSelectedItem ?? "MAC_OS",
                    udid: udidField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    useCurrentMachineUDID: currentMachineCheckbox.state == .on
                )
            }
            _ = try await self.service.registerDevice(request)
            await MainActor.run {
                ToastManager.show(message: L10n.Signing.createSucceeded, in: self.view)
                self.refreshCurrentCategory()
            }
        }
    }

    private func presentCreateProfile(from window: NSWindow?) {
        setPerformingAction(true, title: L10n.Signing.createProfileTitle)
        Task { [weak self] in
            guard let self else { return }
            do {
                let bundleIDs = try await self.service.listBundleIDs()
                let certificates = try await self.service.listCertificates()
                let devices = try await self.service.listDevices()

                await MainActor.run {
                    let nameField = NSTextField()
                    let typePopup = NSPopUpButton()
                    typePopup.addItems(withTitles: SigningCLIOptions.profileTypes)
                    typePopup.selectItem(withTitle: "MAC_APP_DEVELOPMENT")

                    let bundlePopup = NSPopUpButton()
                    bundlePopup.addItems(withTitles: bundleIDs.map(\.identifier))

                    let certificatePicker = SigningMultiSelectPickerView(
                        options: certificates.map {
                            .init(
                                id: $0.id,
                                title: $0.displayName ?? $0.name,
                                detail: $0.id
                            )
                        }
                    )
                    let devicePicker = SigningMultiSelectPickerView(
                        options: devices.map {
                            .init(
                                id: $0.id,
                                title: $0.name,
                                detail: $0.udid
                            )
                        }
                    )
                    let deviceSelectAllButton = self.makeActionButton(title: L10n.Menu.selectAll) { [weak devicePicker] in
                        devicePicker?.selectAll()
                    }
                    let deviceInvertButton = self.makeActionButton(title: L10n.Signing.invertSelection) { [weak devicePicker] in
                        devicePicker?.invertSelection()
                    }

                    let accessory = SigningAlertAccessoryFactory.makeContainer(rows: [
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.name, control: nameField),
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.type, control: typePopup),
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.bundleID, control: bundlePopup),
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.certificateIDs, control: self.makePickerControl(picker: certificatePicker)),
                        SigningAlertAccessoryFactory.makeRow(
                            title: L10n.Signing.deviceIDs,
                            control: self.makePickerControl(
                                picker: devicePicker,
                                actionButtons: [deviceSelectAllButton, deviceInvertButton]
                            )
                        ),
                        SigningAlertAccessoryFactory.makeHintLabel(L10n.Signing.profileHint)
                    ])

                    self.presentAccessoryAlert(
                        title: L10n.Signing.createProfileTitle,
                        accessoryView: accessory,
                        from: window
                    ) { [weak self] in
                        guard let self else { return }
                        let request = await MainActor.run {
                            SigningAssetsService.CreateProfileRequest(
                                name: nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                                profileType: typePopup.titleOfSelectedItem ?? "MAC_APP_DEVELOPMENT",
                                bundleID: bundleIDs[bundlePopup.indexOfSelectedItem].id,
                                certificateIDs: certificatePicker.selectedIDs,
                                deviceIDs: devicePicker.selectedIDs
                            )
                        }
                        _ = try await self.service.createProfile(request)
                        await MainActor.run {
                            ToastManager.show(message: L10n.Signing.createSucceeded, in: self.view)
                            self.refreshCurrentCategory()
                        }
                    }
                    self.setPerformingAction(false, title: L10n.Signing.loading)
                }
            } catch {
                await MainActor.run {
                    self.setPerformingAction(false, title: L10n.Signing.loading)
                    ToastManager.show(message: error.localizedDescription, in: self.view)
                }
            }
        }
    }

    private func presentConfigureCapabilities(for bundleID: BundleIDSummary, from window: NSWindow?) {
        setPerformingAction(true, title: L10n.Signing.configureCapabilitiesTitle)
        Task { [weak self] in
            guard let self else { return }
            do {
                let capabilities = try await self.service.listBundleIDCapabilities(bundleID: bundleID.id)
                await MainActor.run {
                    let capabilityPopup = NSPopUpButton()
                    capabilityPopup.addItems(withTitles: SigningCLIOptions.capabilityTypes)
                    let settingsEditor = self.makeSettingsEditor(
                        initialText: SigningCLIOptions.settingsTemplate(for: capabilityPopup.titleOfSelectedItem ?? "") ?? ""
                    )
                    let settingsTextView = settingsEditor.textView
                    self.bindAction(to: capabilityPopup) { [weak capabilityPopup, weak settingsTextView] in
                        guard let capabilityPopup, let settingsTextView else { return }
                        settingsTextView.string = SigningCLIOptions.settingsTemplate(for: capabilityPopup.titleOfSelectedItem ?? "") ?? ""
                    }

                    let existingCapabilitiesLabel = NSTextField(
                        wrappingLabelWithString: capabilities.isEmpty
                            ? L10n.Apps.unavailable
                            : capabilities.map(\.capabilityType).sorted().joined(separator: ", ")
                    )
                    existingCapabilitiesLabel.maximumNumberOfLines = 0

                    let accessory = SigningAlertAccessoryFactory.makeContainer(rows: [
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.bundleID, control: NSTextField(labelWithString: bundleID.identifier)),
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.existingCapabilities, control: existingCapabilitiesLabel),
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.capability, control: capabilityPopup),
                        SigningAlertAccessoryFactory.makeRow(title: L10n.Signing.settingsJSON, control: settingsEditor.container),
                        SigningAlertAccessoryFactory.makeHintLabel(L10n.Signing.capabilityHint)
                    ])

                    self.setPerformingAction(false, title: L10n.Signing.loading)
                    self.presentAccessoryAlert(
                        title: L10n.Signing.configureCapabilitiesTitle,
                        accessoryView: accessory,
                        from: window,
                        confirmTitle: L10n.Common.add,
                        cancelTitle: L10n.Common.close
                    ) { [weak self] in
                        guard let self else { return }
                        let selectedCapability = await MainActor.run { capabilityPopup.titleOfSelectedItem ?? "" }
                        let settingsJSON = await MainActor.run {
                            settingsEditor.textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        _ = try await self.service.addBundleIDCapability(
                            .init(
                                bundleID: bundleID.id,
                                capabilityType: selectedCapability,
                                settingsJSON: settingsJSON.isEmpty ? nil : settingsJSON
                            )
                        )
                        await MainActor.run {
                            ToastManager.show(message: L10n.Signing.actionSucceeded, in: self.view)
                            DispatchQueue.main.async {
                                self.presentConfigureCapabilities(for: bundleID, from: window)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.setPerformingAction(false, title: L10n.Signing.loading)
                    ToastManager.show(message: error.localizedDescription, in: self.view)
                }
            }
        }
    }

    private func presentAccessoryAlert(
        title: String,
        accessoryView: NSView,
        from window: NSWindow?,
        action: @escaping @Sendable () async throws -> Void
    ) {
        presentAccessoryAlert(
            title: title,
            accessoryView: accessoryView,
            from: window,
            confirmTitle: L10n.Common.create,
            cancelTitle: L10n.Common.cancel,
            action: action
        )
    }

    private func presentAccessoryAlert(
        title: String,
        accessoryView: NSView,
        from window: NSWindow?,
        confirmTitle: String,
        cancelTitle: String,
        action: @escaping @Sendable () async throws -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = title
        accessoryView.layoutSubtreeIfNeeded()
        alert.accessoryView = accessoryView
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: cancelTitle)

        let handleResponse: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            self.setPerformingAction(true, title: title)
            Task {
                do {
                    try await action()
                } catch {
                    await MainActor.run {
                        ToastManager.show(message: error.localizedDescription, in: self.view)
                    }
                }
                await MainActor.run {
                    self.setPerformingAction(false, title: L10n.Signing.loading)
                }
            }
        }

        if let window {
            alert.beginSheetModal(for: window, completionHandler: handleResponse)
        } else {
            handleResponse(alert.runModal())
        }
    }

    private func resolveBundleIDSummary(identifier: String) async throws -> BundleIDSummary {
        let bundleIDs = try await service.listBundleIDs()
        if let match = bundleIDs.first(where: { $0.identifier == identifier }) {
            return match
        }

        throw NSError(
            domain: "ConnectMate.Signing",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: L10n.Signing.bundleIDResolveFailed]
        )
    }

    private func bindAction(to control: NSControl, handler: @escaping () -> Void) {
        let actionHandler = SigningActionHandler(action: handler)
        actionHandlers.append(actionHandler)
        control.target = actionHandler
        control.action = #selector(SigningActionHandler.invoke)
    }

    private func makeActionButton(title: String, handler: @escaping () -> Void) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        bindAction(to: button, handler: handler)
        return button
    }

    private func makeTrailingButtonControl(field: NSTextField, button: NSButton) -> NSView {
        let stack = NSStackView(views: [field, button])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }

    private func makeButtonRow(buttons: [NSButton]) -> NSView {
        let stack = NSStackView(views: buttons)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        return stack
    }

    private func makePickerControl(picker: SigningMultiSelectPickerView, actionButtons: [NSButton] = []) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        if !actionButtons.isEmpty {
            stack.addArrangedSubview(makeButtonRow(buttons: actionButtons))
        }
        stack.addArrangedSubview(picker)
        return stack
    }

    private func makeSettingsEditor(initialText: String) -> (container: NSView, textView: NSTextView) {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.string = initialText

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.drawsBackground = true
        scrollView.documentView = textView
        scrollView.snp.makeConstraints { make in
            make.height.equalTo(88)
            make.width.greaterThanOrEqualTo(280)
        }
        return (scrollView, textView)
    }

    private func chooseExistingFile(into field: NSTextField, from window: NSWindow?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        let applySelection: (URL) -> Void = { url in
            field.stringValue = url.path
        }

        if let window {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                applySelection(url)
            }
        } else if panel.runModal() == .OK, let url = panel.url {
            applySelection(url)
        }
    }

    private func chooseSavePath(into field: NSTextField, suggestedName: String, from window: NSWindow?) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedName

        let applySelection: (URL) -> Void = { url in
            field.stringValue = url.path
        }

        if let window {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                applySelection(url)
            }
        } else if panel.runModal() == .OK, let url = panel.url {
            applySelection(url)
        }
    }
}
