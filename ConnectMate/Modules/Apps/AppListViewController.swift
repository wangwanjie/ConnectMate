import Cocoa
import SnapKit

@MainActor
final class AppListViewController: NSViewController, NSSearchFieldDelegate {
    var onSelectApp: ((AppSummary?) -> Void)?

    private let service: AppService
    private let settings: AppSettings
    private let createButton = NSButton(title: L10n.Apps.createApp, target: nil, action: nil)
    private let searchField = NSSearchField()
    private let loadingView = LoadingView(title: L10n.Apps.loading)
    private lazy var errorStateView = ErrorStateView(
        title: L10n.Apps.loadFailed,
        detail: "",
        actionTitle: L10n.Apps.refresh,
        actionHandler: { [weak self] in
            self?.refreshApps()
        }
    )
    private let emptyStateView = EmptyStateView(
        symbolName: "tray",
        title: L10n.Apps.emptyTitle,
        detail: L10n.Apps.emptyDetail
    )
    private let listContainer = NSView()
    private let rowStack = NSStackView()
    private var rowButtons: [AppRowButton] = []
    private var apps: [AppSummary] = []
    private var selectedAppID: String?
    private var hasLoadedInitialData = false

    init(service: AppService? = nil, settings: AppSettings? = nil) {
        let resolvedService = service ?? .makeDefault()
        let resolvedSettings = settings ?? .shared
        self.service = resolvedService
        self.settings = resolvedSettings
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange(_:)),
            name: AppSettings.didChangeNotification,
            object: resolvedSettings
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let backgroundView = ThemedBackgroundView { appearance in
            NSColor.controlBackgroundColor.resolvedColor(with: appearance)
        }
        backgroundView.onEffectiveAppearanceChange = { [weak self] in
            self?.rowButtons.forEach { button in
                button.refreshSelectionStyle()
            }
        }
        view = backgroundView
        buildLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true
        loadInitialData()
    }

    func controlTextDidChange(_ obj: Notification) {
        applySearch()
    }

    @objc
    private func refreshApps() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let apps = try await service.refreshApps(search: searchField.stringValue)
                await MainActor.run {
                    self.errorStateView.isHidden = true
                    self.apply(apps: apps)
                    self.setLoading(false)
                }
            } catch {
                await MainActor.run {
                    self.apply(apps: [])
                    self.showError(detail: error.localizedDescription)
                    self.setLoading(false)
                }
            }
        }
    }

    func performRefreshFromMenu() {
        refreshApps()
    }

    func presentCreateAppSheet(from window: NSWindow?) {
        CreateAppSheetController.presentAsSheet(from: window, service: service) { [weak self] request in
            guard let self else { return }
            ToastManager.show(message: String(format: L10n.Apps.createSucceeded, request.name), in: self.view)
            self.refreshApps()
        }
    }

    @objc
    private func handleAppSelection(_ sender: NSButton) {
        selectApp(at: sender.tag)
    }

    @objc
    private func handleCreateApp() {
        presentCreateAppSheet(from: view.window)
    }

    private func buildLayout() {
        let titleLabel = NSTextField(labelWithString: L10n.Apps.title)
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)

        searchField.placeholderString = L10n.Apps.searchPlaceholder
        searchField.delegate = self

        createButton.target = self
        createButton.action = #selector(handleCreateApp)

        let refreshButton = NSButton(title: L10n.Apps.refresh, target: self, action: #selector(refreshApps))

        rowStack.orientation = .vertical
        rowStack.spacing = settings.listRowDensity.appRowSpacing
        rowStack.alignment = .leading

        listContainer.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        }

        view.addSubview(titleLabel)
        view.addSubview(searchField)
        view.addSubview(createButton)
        view.addSubview(refreshButton)
        view.addSubview(listContainer)
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

        createButton.snp.makeConstraints { make in
            make.trailing.equalTo(refreshButton.snp.leading).offset(-12)
            make.centerY.equalTo(refreshButton)
        }

        searchField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(createButton.snp.leading).offset(-12)
        }

        listContainer.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(listContainer)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalTo(listContainer)
        }

        errorStateView.snp.makeConstraints { make in
            make.center.equalTo(listContainer)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        emptyStateView.isHidden = true
        loadingView.isHidden = true
        errorStateView.isHidden = true
    }

    private func loadInitialData() {
        if let cachedApps = try? service.loadCachedApps(search: nil), !cachedApps.isEmpty {
            apply(apps: cachedApps)
        }
        refreshApps()
    }

    private func applySearch() {
        do {
            apply(apps: try service.loadCachedApps(search: searchField.stringValue))
        } catch {
            showError(detail: error.localizedDescription)
        }
    }

    private func apply(apps: [AppSummary]) {
        self.apps = apps
        rebuildRows()

        let hasApps = !apps.isEmpty
        listContainer.isHidden = !hasApps
        emptyStateView.isHidden = hasApps
        errorStateView.isHidden = true

        if hasApps {
            let selectedIndex = apps.firstIndex { $0.id == selectedAppID } ?? 0
            selectApp(at: selectedIndex)
        } else {
            selectedAppID = nil
            onSelectApp?(nil)
        }
    }

    private func rebuildRows() {
        rowButtons.forEach { button in
            rowStack.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        rowButtons.removeAll()

        for (index, app) in apps.enumerated() {
            let button = AppRowButton()
            button.tag = index
            button.target = self
            button.action = #selector(handleAppSelection(_:))
            button.configure(with: app)
            button.applyDensity(settings.listRowDensity)
            rowStack.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
            rowButtons.append(button)
        }
    }

    @objc
    private func handleSettingsChange(_ notification: Notification) {
        guard
            let key = notification.userInfo?[AppSettings.changedKeyUserInfoKey] as? String,
            key == SettingKey.listRowDensity.rawValue
        else {
            return
        }

        rowStack.spacing = settings.listRowDensity.appRowSpacing
        rowButtons.forEach { $0.applyDensity(settings.listRowDensity) }
        view.needsLayout = true
    }

    private func selectApp(at index: Int) {
        guard index >= 0, index < apps.count else {
            onSelectApp?(nil)
            return
        }

        selectedAppID = apps[index].id
        for (offset, button) in rowButtons.enumerated() {
            button.updateSelection(isSelected: offset == index)
        }
        onSelectApp?(apps[index])
    }

    private func setLoading(_ isLoading: Bool) {
        loadingView.isHidden = !isLoading
    }

    private func showError(detail: String) {
        errorStateView.isHidden = false
        listContainer.isHidden = true
        emptyStateView.isHidden = true
        onSelectApp?(nil)

        if let detailLabel = errorStateView.subviews
            .compactMap({ $0 as? NSStackView })
            .first?
            .arrangedSubviews
            .compactMap({ $0 as? NSTextField })
            .dropFirst()
            .first {
            detailLabel.stringValue = detail
        }
    }
}

private final class AppRowButton: NSButton {
    private let nameLabel = NSTextField(labelWithString: "")
    private let bundleLabel = NSTextField(labelWithString: "")
    private let stack = NSStackView()
    private var isSelectedState = false
    private var topConstraint: Constraint?
    private var leadingConstraint: Constraint?
    private var bottomConstraint: Constraint?
    private var trailingConstraint: Constraint?
    private var minimumHeightConstraint: Constraint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        isBordered = false
        bezelStyle = .recessed
        setButtonType(.momentaryChange)
        wantsLayer = true
        layer?.cornerRadius = 10

        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        bundleLabel.font = .systemFont(ofSize: 12)
        bundleLabel.textColor = .secondaryLabelColor

        stack.orientation = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(bundleLabel)

        addSubview(stack)
        stack.snp.makeConstraints { make in
            topConstraint = make.top.equalToSuperview().inset(10).constraint
            leadingConstraint = make.leading.equalToSuperview().inset(14).constraint
            bottomConstraint = make.bottom.equalToSuperview().inset(10).constraint
            trailingConstraint = make.trailing.equalToSuperview().inset(14).constraint
        }
        snp.makeConstraints { make in
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(52).constraint
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with app: AppSummary) {
        title = app.name
        nameLabel.stringValue = app.name
        bundleLabel.stringValue = app.bundleID
        setAccessibilityLabel(app.name)
    }

    func updateSelection(isSelected: Bool) {
        isSelectedState = isSelected
        applySelectionStyle()
    }

    func applyDensity(_ density: ListRowDensity) {
        let insets = density.appRowInsets
        topConstraint?.update(inset: insets.top)
        leadingConstraint?.update(inset: insets.left)
        bottomConstraint?.update(inset: insets.bottom)
        trailingConstraint?.update(inset: insets.right)
        minimumHeightConstraint?.update(offset: density.appRowMinimumHeight)
    }

    func refreshSelectionStyle() {
        applySelectionStyle()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applySelectionStyle()
    }

    private func applySelectionStyle() {
        let accentColor = NSColor.controlAccentColor.resolvedColor(with: effectiveAppearance)
        let idleColor = NSColor.quaternaryLabelColor
            .withAlphaComponent(0.08)
            .resolvedColor(with: effectiveAppearance)
        layer?.backgroundColor = (isSelectedState ? accentColor : idleColor).cgColor
        nameLabel.textColor = isSelectedState ? .white : .labelColor
        bundleLabel.textColor = isSelectedState ? NSColor.white.withAlphaComponent(0.85) : .secondaryLabelColor
    }
}
