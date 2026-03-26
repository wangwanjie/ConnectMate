import Cocoa
import GRDB
import ServiceManagement
import SnapKit

private enum PreferencesSection: String, CaseIterable {
    case general
    case appearance
    case notifications
    case cliAndAPI
    case dataAndCache
    case updates
    case shortcuts
    case about

    var title: String {
        switch self {
        case .general:
            return L10n.Settings.Section.general
        case .appearance:
            return L10n.Settings.Section.appearance
        case .notifications:
            return L10n.Settings.Section.notifications
        case .cliAndAPI:
            return L10n.Settings.Section.cliAndAPI
        case .dataAndCache:
            return L10n.Settings.Section.dataAndCache
        case .updates:
            return L10n.Settings.Section.updates
        case .shortcuts:
            return L10n.Settings.Section.shortcuts
        case .about:
            return L10n.Settings.Section.about
        }
    }
}

final class PreferencesViewController: NSViewController {
    private let settings: AppSettings
    private let splitView = NSSplitView()
    private let sectionStack = NSStackView()
    private let contentScrollView = NSScrollView()
    private let contentContainer = NSView()
    private let contentStack = NSStackView()
    private var sectionButtons: [PreferencesSection: NSButton] = [:]
    private var renderedSection: PreferencesSection?

    init(settings: AppSettings) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        buildLayout()
        render(section: .general)
    }

    private func buildLayout() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.adjustSubviews()

        let sidebarContainer = NSView()
        let detailContainer = NSView()

        view.addSubview(splitView)
        splitView.addArrangedSubview(sidebarContainer)
        splitView.addArrangedSubview(detailContainer)

        splitView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        sidebarContainer.snp.makeConstraints { make in
            make.width.equalTo(220)
        }

        let sidebarHeader = NSTextField(labelWithString: "ConnectMate")
        sidebarHeader.font = .systemFont(ofSize: 22, weight: .semibold)

        sectionStack.orientation = .vertical
        sectionStack.spacing = 8
        sectionStack.alignment = .leading

        for section in PreferencesSection.allCases {
            let button = NSButton(title: section.title, target: self, action: #selector(handleSectionButton(_:)))
            button.isBordered = false
            button.font = .systemFont(ofSize: 13, weight: .medium)
            button.alignment = .left
            button.bezelStyle = .recessed
            button.tag = PreferencesSection.allCases.firstIndex(of: section) ?? 0
            button.snp.makeConstraints { make in
                make.width.equalTo(180)
                make.height.equalTo(30)
            }
            sectionButtons[section] = button
            sectionStack.addArrangedSubview(button)
        }

        let sidebarLayout = NSStackView(views: [sidebarHeader, sectionStack, NSView()])
        sidebarLayout.orientation = .vertical
        sidebarLayout.spacing = 16
        sidebarContainer.addSubview(sidebarLayout)
        sidebarLayout.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 20, left: 18, bottom: 20, right: 18))
        }

        contentScrollView.drawsBackground = false
        contentScrollView.hasVerticalScroller = true
        contentScrollView.borderType = .noBorder

        detailContainer.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentScrollView.documentView = contentContainer
        contentContainer.addSubview(contentStack)
        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(contentScrollView.contentView.snp.width)
        }

        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 18
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24))
        }
    }

    @objc
    private func handleSectionButton(_ sender: NSButton) {
        guard sender.tag < PreferencesSection.allCases.count else { return }
        render(section: PreferencesSection.allCases[sender.tag])
    }

    private func render(section: PreferencesSection) {
        renderedSection = section
        updateSectionButtonStyles()

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let titleLabel = NSTextField(labelWithString: section.title)
        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(makeSectionView(for: section))
    }

    private func makeSectionView(for section: PreferencesSection) -> NSView {
        switch section {
        case .general:
            return makeGeneralSection()
        case .appearance:
            return makeAppearanceSection()
        case .notifications:
            return makeNotificationsSection()
        case .cliAndAPI:
            return makeCLISection()
        case .dataAndCache:
            return makeDataSection()
        case .updates:
            return makeUpdatesSection()
        case .shortcuts:
            return makeShortcutsSection()
        case .about:
            return makeAboutSection()
        }
    }

    private func makeGeneralSection() -> NSView {
        let stack = makeFormStack()

        let startAtLogin = makeCheckbox(title: L10n.Settings.General.startAtLogin, isOn: settings.startAtLogin, action: #selector(toggleStartAtLogin(_:)))
        let autoRefresh = makeCheckbox(title: L10n.Settings.General.autoRefreshOnLaunch, isOn: settings.autoRefreshOnLaunch, action: #selector(toggleAutoRefresh(_:)))
        let confirm = makeCheckbox(title: L10n.Settings.General.requiresConfirmation, isOn: settings.requiresActionConfirmation, action: #selector(toggleConfirmation(_:)))

        let launchPopup = NSPopUpButton()
        DefaultLaunchSection.allCases.forEach { launchPopup.addItem(withTitle: $0.localizedTitle) }
        launchPopup.selectItem(at: DefaultLaunchSection.allCases.firstIndex(of: settings.defaultLaunchSection) ?? 0)
        launchPopup.target = self
        launchPopup.action = #selector(changeDefaultSection(_:))

        stack.addArrangedSubview(startAtLogin)
        stack.addArrangedSubview(autoRefresh)
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.General.defaultLaunchSection, control: launchPopup))
        stack.addArrangedSubview(confirm)
        return stack
    }

    private func makeAppearanceSection() -> NSView {
        let stack = makeFormStack()

        let segmented = NSSegmentedControl(labels: AppearanceMode.allCases.map(\.localizedTitle), trackingMode: .selectOne, target: self, action: #selector(changeAppearanceMode(_:)))
        segmented.selectedSegment = AppearanceMode.allCases.firstIndex(of: settings.appearanceMode) ?? 0

        let sidebarPopup = NSPopUpButton()
        SidebarItemStyle.allCases.forEach { sidebarPopup.addItem(withTitle: $0.localizedTitle) }
        sidebarPopup.selectItem(at: SidebarItemStyle.allCases.firstIndex(of: settings.sidebarItemStyle) ?? 0)
        sidebarPopup.target = self
        sidebarPopup.action = #selector(changeSidebarStyle(_:))

        let densityPopup = NSPopUpButton()
        ListRowDensity.allCases.forEach { densityPopup.addItem(withTitle: $0.localizedTitle) }
        densityPopup.selectItem(at: ListRowDensity.allCases.firstIndex(of: settings.listRowDensity) ?? 0)
        densityPopup.target = self
        densityPopup.action = #selector(changeListDensity(_:))

        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Appearance.themeMode, control: segmented))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Appearance.sidebarStyle, control: sidebarPopup))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Appearance.listDensity, control: densityPopup))
        return stack
    }

    private func makeNotificationsSection() -> NSView {
        let stack = makeFormStack()

        let review = makeCheckbox(title: L10n.Settings.Notifications.reviewStatus, isOn: settings.reviewStatusNotifications, action: #selector(toggleReviewNotifications(_:)))
        let build = makeCheckbox(title: L10n.Settings.Notifications.buildProcessing, isOn: settings.buildProcessingNotifications, action: #selector(toggleBuildNotifications(_:)))
        let tester = makeCheckbox(title: L10n.Settings.Notifications.testerAcceptance, isOn: settings.testerAcceptanceNotifications, action: #selector(toggleTesterNotifications(_:)))

        let deliveryPopup = NSPopUpButton()
        NotificationDeliveryMode.allCases.forEach { deliveryPopup.addItem(withTitle: $0.localizedTitle) }
        deliveryPopup.selectItem(at: NotificationDeliveryMode.allCases.firstIndex(of: settings.notificationDeliveryMode) ?? 0)
        deliveryPopup.target = self
        deliveryPopup.action = #selector(changeNotificationMode(_:))

        stack.addArrangedSubview(review)
        stack.addArrangedSubview(build)
        stack.addArrangedSubview(tester)
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Notifications.deliveryMode, control: deliveryPopup))
        return stack
    }

    private func makeCLISection() -> NSView {
        let stack = makeFormStack()

        let cliField = NSTextField(string: settings.cliPath)
        cliField.target = self
        cliField.action = #selector(commitCLIPath(_:))

        let browseButton = NSButton(title: L10n.Common.browse, target: self, action: #selector(browseCLIPath))
        let cliRow = makeSplitRow(title: L10n.Settings.CLI.cliPath, leading: cliField, trailing: browseButton)

        let timeoutField = NSTextField(string: "\(settings.commandTimeout)")
        timeoutField.target = self
        timeoutField.action = #selector(commitCommandTimeout(_:))

        let retryField = NSTextField(string: "\(settings.apiRetryCount)")
        retryField.target = self
        retryField.action = #selector(commitRetryCount(_:))

        let proxyEnabled = makeCheckbox(title: L10n.Settings.CLI.proxyEnabled, isOn: settings.proxyEnabled, action: #selector(toggleProxy(_:)))
        let proxyField = NSTextField(string: settings.proxyURL)
        proxyField.target = self
        proxyField.action = #selector(commitProxyURL(_:))
        proxyField.isEnabled = settings.proxyEnabled
        proxyField.identifier = NSUserInterfaceItemIdentifier("proxyField")

        stack.addArrangedSubview(cliRow)
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.CLI.commandTimeout, control: timeoutField))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.CLI.retryCount, control: retryField))
        stack.addArrangedSubview(proxyEnabled)
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.CLI.proxyURL, control: proxyField))
        return stack
    }

    private func makeDataSection() -> NSView {
        let stack = makeFormStack()

        let cachePopup = NSPopUpButton()
        CachePolicy.allCases.forEach { cachePopup.addItem(withTitle: $0.localizedTitle) }
        cachePopup.selectItem(at: CachePolicy.allCases.firstIndex(of: settings.cachePolicy) ?? 0)
        cachePopup.target = self
        cachePopup.action = #selector(changeCachePolicy(_:))

        let retentionPopup = NSPopUpButton()
        LogRetentionPolicy.allCases.forEach { retentionPopup.addItem(withTitle: $0.localizedTitle) }
        retentionPopup.selectItem(at: LogRetentionPolicy.allCases.firstIndex(of: settings.logRetention) ?? 0)
        retentionPopup.target = self
        retentionPopup.action = #selector(changeLogRetention(_:))

        let clearCacheButton = NSButton(title: L10n.Settings.Data.clearCache, target: self, action: #selector(clearCache))
        let exportButton = NSButton(title: L10n.Settings.Data.exportData, target: self, action: #selector(exportData))

        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Data.cachePolicy, control: cachePopup))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Data.logRetention, control: retentionPopup))
        stack.addArrangedSubview(clearCacheButton)
        stack.addArrangedSubview(exportButton)
        return stack
    }

    private func makeUpdatesSection() -> NSView {
        let stack = makeFormStack()

        let autoCheck = makeCheckbox(title: L10n.Settings.Updates.autoCheck, isOn: settings.autoCheckUpdates, action: #selector(toggleAutoCheckUpdates(_:)))

        let frequencyPopup = NSPopUpButton()
        UpdateCheckFrequency.allCases.forEach { frequencyPopup.addItem(withTitle: $0.localizedTitle) }
        frequencyPopup.selectItem(at: UpdateCheckFrequency.allCases.firstIndex(of: settings.updateCheckFrequency) ?? 0)
        frequencyPopup.target = self
        frequencyPopup.action = #selector(changeUpdateFrequency(_:))

        let channelPopup = NSPopUpButton()
        UpdateChannel.allCases.forEach { channelPopup.addItem(withTitle: $0.localizedTitle) }
        channelPopup.selectItem(at: UpdateChannel.allCases.firstIndex(of: settings.updateChannel) ?? 0)
        channelPopup.target = self
        channelPopup.action = #selector(changeUpdateChannel(_:))

        let checkNowButton = NSButton(title: L10n.Settings.Updates.checkNow, target: self, action: #selector(checkForUpdatesNow))

        stack.addArrangedSubview(autoCheck)
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Updates.frequency, control: frequencyPopup))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Updates.channel, control: channelPopup))
        stack.addArrangedSubview(checkNowButton)
        return stack
    }

    private func makeShortcutsSection() -> NSView {
        let stack = makeFormStack()

        let globalRecorder = makeRecorder(initialValue: settings.globalHotkey, action: #selector(commitGlobalShortcut(_:)))
        let refreshRecorder = makeRecorder(initialValue: settings.refreshShortcut, action: #selector(commitRefreshShortcut(_:)))
        let newTaskRecorder = makeRecorder(initialValue: settings.newTaskShortcut, action: #selector(commitNewTaskShortcut(_:)))
        let appearanceRecorder = makeRecorder(initialValue: settings.toggleAppearanceShortcut, action: #selector(commitAppearanceShortcut(_:)))

        let note = NSTextField(wrappingLabelWithString: L10n.Settings.Shortcuts.conflictHint)
        note.textColor = .secondaryLabelColor
        note.font = .systemFont(ofSize: 12)

        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Shortcuts.globalShortcut, control: globalRecorder))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Shortcuts.refreshCurrentPage, control: refreshRecorder))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Shortcuts.newTask, control: newTaskRecorder))
        stack.addArrangedSubview(makeLabeledRow(title: L10n.Settings.Shortcuts.toggleAppearance, control: appearanceRecorder))
        stack.addArrangedSubview(note)
        return stack
    }

    private func makeAboutSection() -> NSView {
        let stack = makeFormStack()

        let iconView = NSImageView(image: NSApp.applicationIconImage)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(72)
        }

        let versionLabel = NSTextField(labelWithString: L10n.Settings.About.versionLine(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        ))
        versionLabel.font = .systemFont(ofSize: 13)

        let licenseLabel = NSTextField(labelWithString: L10n.Settings.About.license)
        licenseLabel.textColor = .secondaryLabelColor

        let checkUpdates = NSButton(title: L10n.Settings.About.checkUpdates, target: self, action: #selector(checkForUpdatesNow))
        let feedback = NSButton(title: L10n.Settings.About.feedback, target: self, action: #selector(openFeedback))
        let thanks = NSButton(title: L10n.Settings.About.acknowledgements, target: self, action: #selector(showAcknowledgements))

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(versionLabel)
        stack.addArrangedSubview(licenseLabel)
        stack.addArrangedSubview(checkUpdates)
        stack.addArrangedSubview(feedback)
        stack.addArrangedSubview(thanks)
        return stack
    }

    private func makeFormStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        return stack
    }

    private func makeCheckbox(title: String, isOn: Bool, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.state = isOn ? .on : .off
        return button
    }

    private func makeLabeledRow(title: String, control: NSView) -> NSView {
        let container = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)

        container.addSubview(label)
        container.addSubview(control)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(220)
        }

        control.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(18)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(label)
        }

        return container
    }

    private func makeSplitRow(title: String, leading: NSView, trailing: NSView) -> NSView {
        let container = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)

        container.addSubview(label)
        container.addSubview(leading)
        container.addSubview(trailing)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(220)
        }

        trailing.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(label)
        }

        leading.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(18)
            make.trailing.equalTo(trailing.snp.leading).offset(-12)
            make.centerY.equalTo(label)
        }

        return container
    }

    private func makeRecorder(initialValue: String, action: Selector) -> HotKeyRecorderView {
        let recorder = HotKeyRecorderView()
        recorder.shortcut = initialValue
        recorder.onShortcutChange = { [weak self] value in
            guard let self else { return }
            switch action {
            case #selector(commitGlobalShortcut(_:)):
                self.settings.globalHotkey = value
                GlobalHotKey.shared.update(shortcut: value)
            case #selector(commitRefreshShortcut(_:)):
                self.settings.refreshShortcut = value
            case #selector(commitNewTaskShortcut(_:)):
                self.settings.newTaskShortcut = value
            case #selector(commitAppearanceShortcut(_:)):
                self.settings.toggleAppearanceShortcut = value
            default:
                break
            }
        }
        return recorder
    }

    private func updateSectionButtonStyles() {
        for (section, button) in sectionButtons {
            let isSelected = section == renderedSection
            button.contentTintColor = isSelected ? .white : .secondaryLabelColor
            button.wantsLayer = true
            button.layer?.cornerRadius = 8
            button.layer?.backgroundColor = isSelected ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor
        }
    }

    @objc
    private func toggleStartAtLogin(_ sender: NSButton) {
        let enabled = sender.state == .on
        settings.startAtLogin = enabled
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            settings.startAtLogin = !enabled
            sender.state = enabled ? .off : .on
            presentInfo(title: L10n.Settings.General.startAtLogin, message: error.localizedDescription)
        }
    }

    @objc private func toggleAutoRefresh(_ sender: NSButton) { settings.autoRefreshOnLaunch = sender.state == .on }
    @objc private func toggleConfirmation(_ sender: NSButton) { settings.requiresActionConfirmation = sender.state == .on }
    @objc private func toggleReviewNotifications(_ sender: NSButton) { settings.reviewStatusNotifications = sender.state == .on }
    @objc private func toggleBuildNotifications(_ sender: NSButton) { settings.buildProcessingNotifications = sender.state == .on }
    @objc private func toggleTesterNotifications(_ sender: NSButton) { settings.testerAcceptanceNotifications = sender.state == .on }
    @objc private func toggleAutoCheckUpdates(_ sender: NSButton) { settings.autoCheckUpdates = sender.state == .on }
    @objc private func toggleProxy(_ sender: NSButton) {
        settings.proxyEnabled = sender.state == .on
        if let proxyField = contentStack.subviews.recursiveSubviews().compactMap({ $0 as? NSTextField }).first(where: { $0.identifier?.rawValue == "proxyField" }) {
            proxyField.isEnabled = settings.proxyEnabled
        }
    }

    @objc
    private func changeDefaultSection(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.defaultLaunchSection = DefaultLaunchSection.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func changeAppearanceMode(_ sender: NSSegmentedControl) {
        guard sender.selectedSegment >= 0 else { return }
        settings.appearanceMode = AppearanceMode.allCases[sender.selectedSegment]
        AppThemeManager.shared.applyStoredPreference(settings: settings, application: NSApp)
    }

    @objc
    private func changeSidebarStyle(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.sidebarItemStyle = SidebarItemStyle.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func changeListDensity(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.listRowDensity = ListRowDensity.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func changeNotificationMode(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.notificationDeliveryMode = NotificationDeliveryMode.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func commitCLIPath(_ sender: NSTextField) {
        settings.cliPath = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc
    private func browseCLIPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: view.window ?? NSApp.keyWindow!) { [weak self] response in
            guard response == .OK, let self, let url = panel.url else { return }
            self.settings.cliPath = url.path
            self.render(section: .cliAndAPI)
        }
    }

    @objc
    private func commitCommandTimeout(_ sender: NSTextField) {
        settings.commandTimeout = Int(sender.stringValue) ?? settings.commandTimeout
        sender.stringValue = "\(settings.commandTimeout)"
    }

    @objc
    private func commitRetryCount(_ sender: NSTextField) {
        settings.apiRetryCount = Int(sender.stringValue) ?? settings.apiRetryCount
        sender.stringValue = "\(settings.apiRetryCount)"
    }

    @objc
    private func commitProxyURL(_ sender: NSTextField) {
        settings.proxyURL = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc
    private func changeCachePolicy(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.cachePolicy = CachePolicy.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func changeLogRetention(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.logRetention = LogRetentionPolicy.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func clearCache() {
        do {
            try DatabaseManager.shared.dbQueue.write { db in
                try db.execute(sql: "DELETE FROM apps")
                try db.execute(sql: "DELETE FROM builds")
                try db.execute(sql: "DELETE FROM review_submissions")
                try db.execute(sql: "DELETE FROM testers")
                try db.execute(sql: "DELETE FROM beta_groups")
                try db.execute(sql: "DELETE FROM iap_products")
            }
            presentInfo(title: L10n.Settings.Data.clearCache, message: L10n.Settings.Data.cacheCleared)
        } catch {
            presentInfo(title: L10n.Settings.Data.clearCache, message: error.localizedDescription)
        }
    }

    @objc
    private func exportData() {
        do {
            let exportURL = try makeExportURL()
            let payload = try DatabaseManager.shared.dbQueue.read { db -> [String: [[String: String]]] in
                func fetchTable(_ name: String) throws -> [[String: String]] {
                    try Row.fetchAll(db, sql: "SELECT * FROM \(name)").map { row in
                        var object: [String: String] = [:]
                        for column in row.columnNames {
                            object[column] = row[column].map { String(describing: $0) } ?? ""
                        }
                        return object
                    }
                }

                return [
                    "api_keys": try fetchTable("api_keys"),
                    "apps": try fetchTable("apps"),
                    "builds": try fetchTable("builds"),
                    "review_submissions": try fetchTable("review_submissions"),
                    "testers": try fetchTable("testers"),
                    "beta_groups": try fetchTable("beta_groups"),
                    "iap_products": try fetchTable("iap_products"),
                    "command_logs": try fetchTable("command_logs")
                ]
            }

            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: exportURL)
            presentInfo(title: L10n.Settings.Data.exportData, message: exportURL.path)
        } catch {
            presentInfo(title: L10n.Settings.Data.exportData, message: error.localizedDescription)
        }
    }

    @objc
    private func changeUpdateFrequency(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.updateCheckFrequency = UpdateCheckFrequency.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func changeUpdateChannel(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.updateChannel = UpdateChannel.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func checkForUpdatesNow() {
        presentInfo(title: L10n.Settings.Updates.checkNow, message: L10n.Settings.Updates.sparklePending)
    }

    @objc
    private func commitGlobalShortcut(_ sender: Any?) {
        _ = sender
    }

    @objc
    private func commitRefreshShortcut(_ sender: Any?) {
        _ = sender
    }

    @objc
    private func commitNewTaskShortcut(_ sender: Any?) {
        _ = sender
    }

    @objc
    private func commitAppearanceShortcut(_ sender: Any?) {
        _ = sender
    }

    @objc
    private func openFeedback() {
        presentInfo(title: L10n.Settings.About.feedback, message: L10n.Settings.About.feedbackMessage)
    }

    @objc
    private func showAcknowledgements() {
        presentInfo(title: L10n.Settings.About.acknowledgements, message: "SnapKit\nGRDB\nSparkle\nApp Store Connect CLI")
    }

    private func makeExportURL() throws -> URL {
        let directory = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return directory.appendingPathComponent("ConnectMate-export-\(formatter.string(from: Date())).json")
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

private extension Array where Element == NSView {
    func recursiveSubviews() -> [NSView] {
        flatMap { [$0] + $0.subviews.recursiveSubviews() }
    }
}
