import Cocoa
import GRDB
import ServiceManagement
import SnapKit
import UniformTypeIdentifiers

enum PreferencesSection: String, CaseIterable {
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

@MainActor
final class PreferencesViewController: NSViewController, NSTextFieldDelegate {
    private enum Metrics {
        static let defaultContentWidth: CGFloat = 720
        static let minimumContentHeight: CGFloat = 240
        static let horizontalInset: CGFloat = 24
        static let topInset: CGFloat = 22
        static let bottomInset: CGFloat = 22
        static let sectionSpacing: CGFloat = 18
        static let sectionCornerRadius: CGFloat = 14
        static let sectionBorderWidth: CGFloat = 1
        static let cardInset: CGFloat = 18
        static let cardSpacing: CGFloat = 12
        static let labelWidth: CGFloat = 180
        static let controlWidth: CGFloat = 280
        static let wideControlWidth: CGFloat = 360
        static let hintWidth: CGFloat = 520
    }

    private let settings: AppSettings
    private let updateManager: any AppUpdateManaging
    private let dataExportService: AppDataExportService

    private let sectionControl = NSSegmentedControl()
    private let sectionContainerView = NSView()
    private var sectionControlWidthConstraint: NSLayoutConstraint?
    private var sectionContainerHeightConstraint: NSLayoutConstraint?
    private var activeSectionHeightConstraint: NSLayoutConstraint?
    private var activeSectionView: NSView?
    private var sectionViews: [PreferencesSection: NSView] = [:]
    private var renderedSection: PreferencesSection = .general
    private var cardViews: [NSView] = []

    private weak var cliPathField: NSTextField?
    private weak var commandTimeoutField: NSTextField?
    private weak var retryCountField: NSTextField?
    private weak var proxyURLField: NSTextField?

    init(
        settings: AppSettings,
        updateManager: (any AppUpdateManaging)? = nil,
        dataExportService: AppDataExportService? = nil
    ) {
        self.settings = settings
        self.updateManager = updateManager ?? AppUpdateManager.shared
        self.dataExportService = dataExportService ?? AppDataExportService()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        let backgroundView = ThemedBackgroundView { appearance in
            NSColor.windowBackgroundColor.resolvedColor(with: appearance)
        }
        backgroundView.onEffectiveAppearanceChange = { [weak self] in
            self?.updateCardColors()
        }
        view = backgroundView
        buildLayout()
        applyLocalization()
        rebuildSectionView(for: renderedSection)
        syncVisibleSection(animated: false)
        installObservers()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        syncVisibleSection(animated: false)
    }

    func prepareForPresentation() {
        syncVisibleSection(animated: false)
    }

    private func installObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageChange),
            name: LocalizationManager.languageDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemeChange),
            name: AppThemeManager.didChangeNotification,
            object: nil
        )
    }

    private func buildLayout() {
        sectionControl.segmentStyle = .rounded
        sectionControl.trackingMode = .selectOne
        sectionControl.target = self
        sectionControl.action = #selector(handleSectionChange(_:))
        sectionControl.setContentHuggingPriority(.required, for: .horizontal)
        sectionControl.setContentCompressionResistancePriority(.required, for: .horizontal)

        sectionContainerView.identifier = NSUserInterfaceItemIdentifier("preferences.sectionContainer")
        sectionContainerView.wantsLayer = true
        sectionContainerView.layer?.masksToBounds = true
        sectionContainerView.setContentHuggingPriority(.required, for: .vertical)
        sectionContainerView.setContentCompressionResistancePriority(.required, for: .vertical)

        view.addSubview(sectionControl)
        view.addSubview(sectionContainerView)

        sectionControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Metrics.topInset)
            make.leading.equalToSuperview().offset(Metrics.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(Metrics.horizontalInset)
        }
        sectionControlWidthConstraint = sectionControl.widthAnchor.constraint(equalToConstant: 0)
        sectionControlWidthConstraint?.isActive = true

        sectionContainerView.snp.makeConstraints { make in
            make.top.equalTo(sectionControl.snp.bottom).offset(Metrics.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(Metrics.horizontalInset)
        }
        sectionContainerHeightConstraint = sectionContainerView.heightAnchor.constraint(equalToConstant: 1)
        sectionContainerHeightConstraint?.isActive = true
    }

    private func applyLocalization() {
        sectionControl.segmentCount = PreferencesSection.allCases.count
        for (index, section) in PreferencesSection.allCases.enumerated() {
            sectionControl.setLabel(section.title, forSegment: index)
        }
        updateSectionControlWidths()
        sectionControl.selectedSegment = PreferencesSection.allCases.firstIndex(of: renderedSection) ?? 0
    }

    private func updateSectionControlWidths() {
        let font = sectionControl.font ?? .systemFont(ofSize: NSFont.systemFontSize)
        let horizontalPadding: CGFloat = 28
        let minimumSegmentWidth: CGFloat = 72
        var totalWidth: CGFloat = 0

        for (index, section) in PreferencesSection.allCases.enumerated() {
            let title = section.title as NSString
            let textWidth = ceil(title.size(withAttributes: [.font: font]).width)
            let segmentWidth = max(minimumSegmentWidth, textWidth + horizontalPadding)
            sectionControl.setWidth(segmentWidth, forSegment: index)
            totalWidth += segmentWidth
        }

        sectionControlWidthConstraint?.constant = ceil(totalWidth)
        sectionControl.layoutSubtreeIfNeeded()
    }

    @objc
    private func handleSectionChange(_ sender: NSSegmentedControl) {
        guard sender.selectedSegment >= 0, sender.selectedSegment < PreferencesSection.allCases.count else {
            return
        }
        selectSection(PreferencesSection.allCases[sender.selectedSegment], animated: true)
    }

    @objc
    private func handleLanguageChange() {
        sectionViews.removeAll()
        applyLocalization()
        rebuildSectionView(for: renderedSection)
        syncVisibleSection(animated: false)
    }

    @objc
    private func handleThemeChange() {
        updateCardColors()
    }

    private func selectSection(_ section: PreferencesSection, animated: Bool, forceRebuild: Bool = false) {
        renderedSection = section
        sectionControl.selectedSegment = PreferencesSection.allCases.firstIndex(of: section) ?? 0
        if forceRebuild || sectionViews[section] == nil {
            rebuildSectionView(for: section)
        }
        syncVisibleSection(animated: animated)
    }

    private func rebuildSectionView(for section: PreferencesSection) {
        sectionViews[section] = makeSectionView(for: section)
    }

    private func syncVisibleSection(animated: Bool) {
        let sectionView = sectionViews[renderedSection] ?? makeSectionView(for: renderedSection)
        sectionViews[renderedSection] = sectionView
        let targetHeight = fittingHeight(for: sectionView)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            installSectionViewIfNeeded(sectionView, targetHeight: targetHeight)
            sectionContainerHeightConstraint?.constant = targetHeight
            activeSectionHeightConstraint?.constant = targetHeight
            sectionContainerView.needsLayout = true
            sectionContainerView.layoutSubtreeIfNeeded()
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
        }
        resizeWindowToFit(sectionHeight: targetHeight, animated: animated)
    }

    private func installSectionViewIfNeeded(_ sectionView: NSView, targetHeight: CGFloat) {
        guard activeSectionView !== sectionView else {
            activeSectionHeightConstraint?.constant = targetHeight
            return
        }

        activeSectionView?.removeFromSuperview()
        activeSectionHeightConstraint?.isActive = false
        sectionContainerView.addSubview(sectionView)
        sectionView.setContentHuggingPriority(.required, for: .vertical)
        sectionView.setContentCompressionResistancePriority(.required, for: .vertical)
        sectionView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        let heightConstraint = sectionView.heightAnchor.constraint(equalToConstant: targetHeight)
        heightConstraint.isActive = true
        activeSectionHeightConstraint = heightConstraint
        activeSectionView = sectionView
        sectionContainerView.needsLayout = true
        sectionContainerView.layoutSubtreeIfNeeded()
    }

    private func resizeWindowToFit(sectionHeight: CGFloat, animated: Bool) {
        guard let window = view.window else {
            return
        }

        window.contentView?.layoutSubtreeIfNeeded()
        view.layoutSubtreeIfNeeded()
        sectionContainerView.layoutSubtreeIfNeeded()

        let targetContentHeight = max(
            Metrics.minimumContentHeight,
            ceil(
                Metrics.topInset
                    + sectionControl.fittingSize.height
                    + Metrics.sectionSpacing
                    + sectionHeight
                    + Metrics.bottomInset
            )
        )
        let contentWidth = max(Metrics.defaultContentWidth, window.contentLayoutRect.width)
        let targetFrameSize = window.frameRect(
            forContentRect: NSRect(origin: .zero, size: NSSize(width: contentWidth, height: targetContentHeight))
        ).size

        var frame = window.frame
        let deltaHeight = targetFrameSize.height - frame.height
        let deltaWidth = targetFrameSize.width - frame.width
        guard abs(deltaHeight) > 0.5 || abs(deltaWidth) > 0.5 else { return }

        frame.origin.y -= deltaHeight
        frame.size.height += deltaHeight
        frame.size.width += deltaWidth

        if animated, window.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.allowsImplicitAnimation = false
                window.animator().setFrame(frame, display: true)
            }
        } else {
            window.setFrame(frame, display: true)
        }
    }

    private func fittingHeight(for sectionView: NSView) -> CGFloat {
        sectionView.layoutSubtreeIfNeeded()
        return ceil(sectionView.fittingSize.height)
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
        let startAtLogin = makeCheckbox(title: L10n.Settings.General.startAtLogin, isOn: settings.startAtLogin, action: #selector(toggleStartAtLogin(_:)))
        let autoRefresh = makeCheckbox(title: L10n.Settings.General.autoRefreshOnLaunch, isOn: settings.autoRefreshOnLaunch, action: #selector(toggleAutoRefresh(_:)))
        let confirm = makeCheckbox(title: L10n.Settings.General.requiresConfirmation, isOn: settings.requiresActionConfirmation, action: #selector(toggleConfirmation(_:)))

        let launchPopup = makePopup(DefaultLaunchSection.allCases.map(\.localizedTitle), selectedIndex: DefaultLaunchSection.allCases.firstIndex(of: settings.defaultLaunchSection))
        launchPopup.action = #selector(changeDefaultSection(_:))

        let languagePopup = makePopup(AppLanguage.allCases.map(\.localizedTitle), selectedIndex: AppLanguage.allCases.firstIndex(of: settings.preferredLanguage))
        languagePopup.action = #selector(changeLanguage(_:))

        return makeSectionCard(contentViews: [
            startAtLogin,
            autoRefresh,
            makeLabeledRow(title: L10n.Settings.General.defaultLaunchSection, control: launchPopup),
            makeLabeledRow(title: L10n.Settings.General.appLanguage, control: languagePopup),
            confirm
        ])
    }

    private func makeAppearanceSection() -> NSView {
        let segmented = NSSegmentedControl(
            labels: AppearanceMode.allCases.map(\.localizedTitle),
            trackingMode: .selectOne,
            target: self,
            action: #selector(changeAppearanceMode(_:))
        )
        segmented.selectedSegment = AppearanceMode.allCases.firstIndex(of: settings.appearanceMode) ?? 0

        let sidebarPopup = makePopup(SidebarItemStyle.allCases.map(\.localizedTitle), selectedIndex: SidebarItemStyle.allCases.firstIndex(of: settings.sidebarItemStyle))
        sidebarPopup.action = #selector(changeSidebarStyle(_:))

        let densityPopup = makePopup(ListRowDensity.allCases.map(\.localizedTitle), selectedIndex: ListRowDensity.allCases.firstIndex(of: settings.listRowDensity))
        densityPopup.action = #selector(changeListDensity(_:))

        return makeSectionCard(contentViews: [
            makeLabeledRow(title: L10n.Settings.Appearance.themeMode, control: segmented),
            makeLabeledRow(title: L10n.Settings.Appearance.sidebarStyle, control: sidebarPopup),
            makeLabeledRow(title: L10n.Settings.Appearance.listDensity, control: densityPopup)
        ])
    }

    private func makeNotificationsSection() -> NSView {
        let review = makeCheckbox(title: L10n.Settings.Notifications.reviewStatus, isOn: settings.reviewStatusNotifications, action: #selector(toggleReviewNotifications(_:)))
        let build = makeCheckbox(title: L10n.Settings.Notifications.buildProcessing, isOn: settings.buildProcessingNotifications, action: #selector(toggleBuildNotifications(_:)))
        let tester = makeCheckbox(title: L10n.Settings.Notifications.testerAcceptance, isOn: settings.testerAcceptanceNotifications, action: #selector(toggleTesterNotifications(_:)))

        let deliveryPopup = makePopup(NotificationDeliveryMode.allCases.map(\.localizedTitle), selectedIndex: NotificationDeliveryMode.allCases.firstIndex(of: settings.notificationDeliveryMode))
        deliveryPopup.action = #selector(changeNotificationMode(_:))

        return makeSectionCard(contentViews: [
            review,
            build,
            tester,
            makeLabeledRow(title: L10n.Settings.Notifications.deliveryMode, control: deliveryPopup)
        ])
    }

    private func makeCLISection() -> NSView {
        let cliField = makeTextField(settings.cliPath, identifier: "cliPathField", width: Metrics.wideControlWidth)
        cliField.action = #selector(commitCLIPath(_:))
        cliPathField = cliField

        let browseButton = NSButton(title: L10n.Common.browse, target: self, action: #selector(browseCLIPath))
        let cliRow = makeSplitRow(title: L10n.Settings.CLI.cliPath, leading: cliField, trailing: browseButton)

        let timeoutField = makeTextField("\(settings.commandTimeout)", identifier: "commandTimeoutField", width: 96)
        timeoutField.action = #selector(commitCommandTimeout(_:))
        commandTimeoutField = timeoutField

        let retryField = makeTextField("\(settings.apiRetryCount)", identifier: "retryCountField", width: 96)
        retryField.action = #selector(commitRetryCount(_:))
        retryCountField = retryField

        let proxyEnabled = makeCheckbox(title: L10n.Settings.CLI.proxyEnabled, isOn: settings.proxyEnabled, action: #selector(toggleProxy(_:)))
        let proxyField = makeTextField(settings.proxyURL, identifier: "proxyField", width: Metrics.wideControlWidth)
        proxyField.action = #selector(commitProxyURL(_:))
        proxyField.isEnabled = settings.proxyEnabled
        proxyURLField = proxyField

        let apiKeyButton = NSButton(title: L10n.Settings.CLI.manageAPIKeys, target: self, action: #selector(openAPIKeyManager))

        return makeSectionCard(contentViews: [
            cliRow,
            makeLabeledRow(title: L10n.Settings.CLI.commandTimeout, control: timeoutField),
            makeLabeledRow(title: L10n.Settings.CLI.retryCount, control: retryField),
            proxyEnabled,
            makeLabeledRow(title: L10n.Settings.CLI.proxyURL, control: proxyField),
            makeSingleButtonRow(apiKeyButton)
        ])
    }

    private func makeDataSection() -> NSView {
        let cachePopup = makePopup(CachePolicy.allCases.map(\.localizedTitle), selectedIndex: CachePolicy.allCases.firstIndex(of: settings.cachePolicy))
        cachePopup.action = #selector(changeCachePolicy(_:))

        let retentionPopup = makePopup(LogRetentionPolicy.allCases.map(\.localizedTitle), selectedIndex: LogRetentionPolicy.allCases.firstIndex(of: settings.logRetention))
        retentionPopup.action = #selector(changeLogRetention(_:))

        let clearCacheButton = NSButton(title: L10n.Settings.Data.clearCache, target: self, action: #selector(clearCache))
        let exportButton = NSButton(title: L10n.Settings.Data.exportData, target: self, action: #selector(exportData))
        let exportDescription = makeHintLabel(L10n.Settings.Data.exportDataDescription)

        return makeSectionCard(contentViews: [
            makeLabeledRow(title: L10n.Settings.Data.cachePolicy, control: cachePopup),
            makeLabeledRow(title: L10n.Settings.Data.logRetention, control: retentionPopup),
            makeSingleButtonRow(clearCacheButton),
            exportDescription,
            makeSingleButtonRow(exportButton)
        ])
    }

    private func makeUpdatesSection() -> NSView {
        let autoCheck = makeCheckbox(title: L10n.Settings.Updates.autoCheck, isOn: settings.autoCheckUpdates, action: #selector(toggleAutoCheckUpdates(_:)))

        let frequencyPopup = makePopup(UpdateCheckFrequency.allCases.map(\.localizedTitle), selectedIndex: UpdateCheckFrequency.allCases.firstIndex(of: settings.updateCheckFrequency))
        frequencyPopup.action = #selector(changeUpdateFrequency(_:))

        let channelPopup = makePopup(UpdateChannel.allCases.map(\.localizedTitle), selectedIndex: UpdateChannel.allCases.firstIndex(of: settings.updateChannel))
        channelPopup.action = #selector(changeUpdateChannel(_:))

        let checkNowButton = NSButton(title: L10n.Settings.Updates.checkNow, target: self, action: #selector(checkForUpdatesNow))

        return makeSectionCard(contentViews: [
            autoCheck,
            makeLabeledRow(title: L10n.Settings.Updates.frequency, control: frequencyPopup),
            makeLabeledRow(title: L10n.Settings.Updates.channel, control: channelPopup),
            makeSingleButtonRow(checkNowButton)
        ])
    }

    private func makeShortcutsSection() -> NSView {
        let globalRecorder = makeRecorder(initialValue: settings.globalHotkey, action: #selector(commitGlobalShortcut(_:)))
        let refreshRecorder = makeRecorder(initialValue: settings.refreshShortcut, action: #selector(commitRefreshShortcut(_:)))
        let newTaskRecorder = makeRecorder(initialValue: settings.newTaskShortcut, action: #selector(commitNewTaskShortcut(_:)))
        let appearanceRecorder = makeRecorder(initialValue: settings.toggleAppearanceShortcut, action: #selector(commitAppearanceShortcut(_:)))
        let note = makeHintLabel(L10n.Settings.Shortcuts.conflictHint)

        return makeSectionCard(contentViews: [
            makeLabeledRow(title: L10n.Settings.Shortcuts.globalShortcut, control: globalRecorder),
            makeLabeledRow(title: L10n.Settings.Shortcuts.refreshCurrentPage, control: refreshRecorder),
            makeLabeledRow(title: L10n.Settings.Shortcuts.newTask, control: newTaskRecorder),
            makeLabeledRow(title: L10n.Settings.Shortcuts.toggleAppearance, control: appearanceRecorder),
            note
        ])
    }

    private func makeAboutSection() -> NSView {
        let iconView = NSImageView(image: NSApp.applicationIconImage)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(72)
        }

        let versionLabel = NSTextField(labelWithString: L10n.Settings.About.versionLine(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        ))
        versionLabel.font = .systemFont(ofSize: 13)

        let licenseLabel = makeHintLabel(L10n.Settings.About.license)

        let checkUpdates = NSButton(title: L10n.Settings.About.checkUpdates, target: self, action: #selector(checkForUpdatesNow))
        let feedback = NSButton(title: L10n.Settings.About.feedback, target: self, action: #selector(openFeedback))
        let thanks = NSButton(title: L10n.Settings.About.acknowledgements, target: self, action: #selector(showAcknowledgements))

        return makeSectionCard(contentViews: [
            iconView,
            versionLabel,
            licenseLabel,
            makeButtonRow([checkUpdates, feedback, thanks])
        ])
    }

    private func makeSectionCard(contentViews: [NSView]) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = Metrics.sectionCornerRadius
        card.layer?.masksToBounds = true
        card.layer?.borderWidth = Metrics.sectionBorderWidth
        cardViews.append(card)

        let contentStack = NSStackView(views: contentViews)
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = Metrics.cardSpacing

        card.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Metrics.cardInset)
            make.bottom.lessThanOrEqualToSuperview().inset(Metrics.cardInset)
        }

        updateCardColors()
        return card
    }

    private func makeCheckbox(title: String, isOn: Bool, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.state = isOn ? .on : .off
        return button
    }

    private func makePopup(_ titles: [String], selectedIndex: Int?) -> NSPopUpButton {
        let popup = NSPopUpButton()
        popup.addItems(withTitles: titles)
        if let selectedIndex, selectedIndex >= 0 {
            popup.selectItem(at: selectedIndex)
        }
        popup.target = self
        popup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        popup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        popup.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(Metrics.controlWidth).priority(.high)
        }
        return popup
    }

    private func makeTextField(_ value: String, identifier: String, width: CGFloat) -> NSTextField {
        let textField = NSTextField(string: value)
        textField.identifier = NSUserInterfaceItemIdentifier(identifier)
        textField.delegate = self
        textField.target = self
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(width).priority(.high)
        }
        return textField
    }

    private func makeHintLabel(_ string: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: string)
        label.textColor = .secondaryLabelColor
        label.font = .systemFont(ofSize: 12)
        label.maximumNumberOfLines = 0
        label.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(Metrics.hintWidth)
        }
        return label
    }

    private func makeLabeledRow(title: String, control: NSView) -> NSView {
        let row = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
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
            make.leading.equalTo(label.snp.trailing).offset(16)
            make.top.trailing.bottom.equalToSuperview()
        }

        label.snp.makeConstraints { make in
            make.centerY.equalTo(control.snp.centerY)
        }
        return row
    }

    private func makeSplitRow(title: String, leading: NSView, trailing: NSView) -> NSView {
        let row = NSView()
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let controls = NSStackView(views: [leading, trailing])
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 12
        controls.setContentHuggingPriority(.defaultLow, for: .horizontal)
        controls.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        row.addSubview(label)
        row.addSubview(controls)

        label.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalTo(Metrics.labelWidth).priority(.high)
            make.bottom.lessThanOrEqualToSuperview()
        }

        controls.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(16)
            make.top.trailing.bottom.equalToSuperview()
        }

        label.snp.makeConstraints { make in
            make.centerY.equalTo(controls.snp.centerY)
        }
        return row
    }

    private func makeSingleButtonRow(_ button: NSButton) -> NSView {
        let row = NSStackView(views: [button])
        row.orientation = .horizontal
        row.alignment = .centerY
        return row
    }

    private func makeButtonRow(_ buttons: [NSButton]) -> NSView {
        let row = NSStackView(views: buttons)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    private func makeRecorder(initialValue: String, action: Selector) -> HotKeyRecorderView {
        let recorder = HotKeyRecorderView()
        recorder.setContentHuggingPriority(.defaultLow, for: .horizontal)
        recorder.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        recorder.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(Metrics.controlWidth).priority(.high)
        }
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

    private func updateCardColors() {
        let appearance = view.effectiveAppearance
        for card in cardViews {
            card.layer?.backgroundColor = NSColor.controlBackgroundColor.resolvedColor(with: appearance).cgColor
            card.layer?.borderColor = NSColor.separatorColor.resolvedColor(with: appearance).cgColor
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

    @objc
    private func toggleProxy(_ sender: NSButton) {
        settings.proxyEnabled = sender.state == .on
        proxyURLField?.isEnabled = settings.proxyEnabled
    }

    @objc
    private func changeDefaultSection(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        settings.defaultLaunchSection = DefaultLaunchSection.allCases[sender.indexOfSelectedItem]
    }

    @objc
    private func changeLanguage(_ sender: NSPopUpButton) {
        guard sender.indexOfSelectedItem >= 0 else { return }
        LocalizationManager.shared.apply(language: AppLanguage.allCases[sender.indexOfSelectedItem])
        presentInfo(title: L10n.Settings.General.appLanguage, message: L10n.Settings.General.languageChangeHint)
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
        let value = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.cliPath = value.isEmpty ? "/usr/local/bin/asc" : value
        sender.stringValue = settings.cliPath
    }

    @objc
    private func browseCLIPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.data]

        guard let window = view.window else {
            if panel.runModal() == .OK, let url = panel.url {
                settings.cliPath = url.path
                cliPathField?.stringValue = url.path
            }
            return
        }

        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let self, let url = panel.url else { return }
            self.settings.cliPath = url.path
            self.cliPathField?.stringValue = url.path
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

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }

        switch textField.identifier?.rawValue {
        case "cliPathField":
            commitCLIPath(textField)
        case "commandTimeoutField":
            commitCommandTimeout(textField)
        case "retryCountField":
            commitRetryCount(textField)
        case "proxyField":
            commitProxyURL(textField)
        default:
            break
        }
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            let confirmed = await ConfirmDialogHelper.confirm(
                title: L10n.Settings.Data.clearCacheConfirmTitle,
                message: L10n.Settings.Data.clearCacheConfirmMessage,
                confirmTitle: L10n.Settings.Data.clearCache,
                cancelTitle: L10n.Common.cancel,
                on: self.view.window
            )
            guard confirmed else { return }

            do {
                try await DatabaseManager.shared.dbQueue.write { db in
                    try db.execute(sql: "DELETE FROM apps")
                    try db.execute(sql: "DELETE FROM builds")
                    try db.execute(sql: "DELETE FROM review_submissions")
                    try db.execute(sql: "DELETE FROM testers")
                    try db.execute(sql: "DELETE FROM beta_groups")
                    try db.execute(sql: "DELETE FROM iap_products")
                }
                self.presentInfo(title: L10n.Settings.Data.clearCache, message: L10n.Settings.Data.cacheCleared)
            } catch {
                self.presentInfo(title: L10n.Settings.Data.clearCache, message: error.localizedDescription)
            }
        }
    }

    @objc
    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "ConnectMate-export-\(timestampString()).json"
        panel.title = L10n.Settings.Data.exportData
        panel.message = L10n.Settings.Data.exportDataDescription

        if let window = view.window {
            panel.beginSheetModal(for: window) { [weak self] response in
                guard response == .OK, let self, let exportURL = panel.url else { return }
                self.performDataExport(to: exportURL)
            }
        } else if panel.runModal() == .OK, let exportURL = panel.url {
            performDataExport(to: exportURL)
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
        updateManager.checkForUpdates()
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
        updateManager.openIssues()
    }

    @objc
    private func openAPIKeyManager() {
        APIKeyViewController.presentAsSheet(from: view.window)
    }

    @objc
    private func showAcknowledgements() {
        presentInfo(title: L10n.Settings.About.acknowledgements, message: "SnapKit\nGRDB\nSparkle\nApp Store Connect CLI")
    }

    private func presentInfo(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: L10n.Common.ok)
        if let window = view.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    func navigate(to section: PreferencesSection, presentAPIKeys: Bool = false, showAcknowledgements: Bool = false) {
        selectSection(section, animated: false, forceRebuild: true)

        if presentAPIKeys {
            openAPIKeyManager()
        } else if showAcknowledgements {
            self.showAcknowledgements()
        }
    }

    func exportCommandLogsFromMenu() {
        do {
            let exportURL = try dataExportService.exportCommandLogs()
            presentInfo(title: L10n.Menu.exportCommandLogs, message: exportURL.path)
        } catch {
            presentInfo(title: L10n.Menu.exportCommandLogs, message: error.localizedDescription)
        }
    }

    private func performDataExport(to exportURL: URL) {
        do {
            let finalURL = try dataExportService.exportAllData(to: exportURL)
            presentInfo(title: L10n.Settings.Data.exportData, message: finalURL.path)
        } catch {
            presentInfo(title: L10n.Settings.Data.exportData, message: error.localizedDescription)
        }
    }

    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
