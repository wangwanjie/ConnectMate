import Cocoa
import GRDB
import SnapKit

@MainActor
final class BuildListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onSelectBuild: ((BuildSummary?) -> Void)?

    private let service: BuildService
    private let appRepository: AppRepository
    private let appFilterLabel = NSTextField(labelWithString: L10n.Builds.appFilter)
    private let appPopup = NSPopUpButton()
    private let refreshButton = NSButton(title: L10n.Builds.refresh, target: nil, action: nil)
    private let expireButton = NSButton(title: L10n.Builds.expireSelected, target: nil, action: nil)
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let loadingView = LoadingView(title: L10n.Builds.loading)
    private let emptyStateView = EmptyStateView(
        symbolName: "shippingbox",
        title: L10n.Builds.emptyAppsTitle,
        detail: L10n.Builds.emptyAppsDetail
    )
    private var builds: [BuildSummary] = []
    private var availableApps: [AppRecord] = []
    private var selectedAppID: String?
    private var hasLoadedInitialData = false

    init(service: BuildService = .makeDefault(), appRepository: AppRepository = AppRepository()) {
        self.service = service
        self.appRepository = appRepository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        buildLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true
        reloadAppOptions()
        loadCachedBuilds()
        if selectedAppID != nil {
            refreshBuilds()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        builds.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0, row < builds.count else {
            return nil
        }

        let build = builds[row]
        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("value")
        let cell = NSTableCellView()
        let label = NSTextField(labelWithString: value(for: build, columnIdentifier: identifier))
        label.lineBreakMode = .byTruncatingTail
        label.textColor = identifier.rawValue == "status" ? build.processingState.tintColor : .labelColor
        cell.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        expireButton.isEnabled = !selectedBuildIDs.isEmpty
        onSelectBuild?(selectedBuild)
    }

    @objc
    private func handleAppFilterChange() {
        selectedAppID = appPopup.selectedItem?.representedObject as? String
        loadCachedBuilds()
    }

    @objc
    private func handleRefresh() {
        refreshBuilds()
    }

    @objc
    private func handleExpireSelected() {
        let buildIDs = selectedBuildIDs
        guard !buildIDs.isEmpty else {
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await service.expireBuilds(buildIDs)
                ToastManager.show(message: L10n.Builds.expireSucceeded, in: self.view)
                self.refreshBuilds()
            } catch {
                ToastManager.show(message: error.localizedDescription, in: self.view)
            }
        }
    }

    private func buildLayout() {
        let titleLabel = NSTextField(labelWithString: L10n.Builds.title)
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)

        appFilterLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        appFilterLabel.textColor = .secondaryLabelColor

        appPopup.target = self
        appPopup.action = #selector(handleAppFilterChange)

        refreshButton.target = self
        refreshButton.action = #selector(handleRefresh)

        expireButton.target = self
        expireButton.action = #selector(handleExpireSelected)
        expireButton.isEnabled = false

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        tableView.headerView = nil
        tableView.allowsMultipleSelection = true
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 34
        tableView.delegate = self
        tableView.dataSource = self

        [
            (L10n.Builds.version, "version", 96.0),
            (L10n.Builds.buildNumber, "buildNumber", 72.0),
            (L10n.Builds.status, "status", 104.0),
            (L10n.Builds.platform, "platform", 88.0)
        ].forEach { title, identifier, width in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
            column.title = title
            column.width = width
            tableView.addTableColumn(column)
        }

        view.addSubview(titleLabel)
        view.addSubview(appFilterLabel)
        view.addSubview(appPopup)
        view.addSubview(refreshButton)
        view.addSubview(expireButton)
        view.addSubview(scrollView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(24)
        }

        refreshButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(titleLabel)
        }

        expireButton.snp.makeConstraints { make in
            make.trailing.equalTo(refreshButton.snp.leading).offset(-12)
            make.centerY.equalTo(refreshButton)
        }

        appFilterLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.leading.equalTo(titleLabel)
        }

        appPopup.snp.makeConstraints { make in
            make.leading.equalTo(appFilterLabel.snp.trailing).offset(10)
            make.centerY.equalTo(appFilterLabel)
            make.trailing.lessThanOrEqualTo(expireButton.snp.leading).offset(-12)
            make.width.greaterThanOrEqualTo(220)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(appPopup.snp.bottom).offset(16)
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
    }

    private var selectedBuildIDs: [String] {
        tableView.selectedRowIndexes.compactMap { index in
            guard index >= 0, index < builds.count else { return nil }
            return builds[index].id
        }
    }

    private var selectedBuild: BuildSummary? {
        let row = tableView.selectedRow
        guard row >= 0, row < builds.count else {
            return nil
        }
        return builds[row]
    }

    private func value(for build: BuildSummary, columnIdentifier: NSUserInterfaceItemIdentifier) -> String {
        switch columnIdentifier.rawValue {
        case "version":
            return build.version
        case "buildNumber":
            return build.buildNumber
        case "status":
            return build.processingState.title
        case "platform":
            return build.platform ?? L10n.Builds.unavailable
        default:
            return ""
        }
    }

    private func reloadAppOptions() {
        do {
            let activeAccountKeyID = try BuildListViewController.activeAccountKeyID()
            availableApps = try appRepository.fetchAll(accountKeyID: activeAccountKeyID, search: nil)
        } catch {
            availableApps = []
            ToastManager.show(message: error.localizedDescription, in: view)
        }

        appPopup.removeAllItems()
        appPopup.addItem(withTitle: L10n.Builds.selectApp)
        appPopup.lastItem?.representedObject = nil

        for app in availableApps {
            appPopup.addItem(withTitle: app.name)
            appPopup.lastItem?.representedObject = app.ascID
        }

        if let selectedAppID,
           let selectedIndex = availableApps.firstIndex(where: { $0.ascID == selectedAppID }) {
            appPopup.selectItem(at: selectedIndex + 1)
        } else if let firstApp = availableApps.first {
            selectedAppID = firstApp.ascID
            appPopup.selectItem(at: 1)
        } else {
            selectedAppID = nil
            appPopup.selectItem(at: 0)
        }

        refreshButton.isEnabled = selectedAppID != nil
    }

    private func loadCachedBuilds() {
        guard let selectedAppID else {
            apply(builds: [], emptyTitle: L10n.Builds.emptyAppsTitle, emptyDetail: L10n.Builds.emptyAppsDetail)
            return
        }

        do {
            apply(
                builds: try service.loadCachedBuilds(appID: selectedAppID, status: nil),
                emptyTitle: L10n.Builds.emptyBuildsTitle,
                emptyDetail: L10n.Builds.emptyBuildsDetail
            )
        } catch {
            ToastManager.show(message: error.localizedDescription, in: view)
        }
    }

    private func refreshBuilds() {
        guard let selectedAppID else {
            apply(builds: [], emptyTitle: L10n.Builds.emptyAppsTitle, emptyDetail: L10n.Builds.emptyAppsDetail)
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let builds = try await service.refreshBuilds(appID: selectedAppID, status: nil)
                reloadAppOptions()
                apply(
                    builds: builds,
                    emptyTitle: L10n.Builds.emptyBuildsTitle,
                    emptyDetail: L10n.Builds.emptyBuildsDetail
                )
            } catch {
                ToastManager.show(message: error.localizedDescription, in: self.view)
            }
            setLoading(false)
        }
    }

    private func apply(builds: [BuildSummary], emptyTitle: String, emptyDetail: String) {
        self.builds = builds
        tableView.reloadData()
        emptyStateView.update(symbolName: "shippingbox", title: emptyTitle, detail: emptyDetail)
        scrollView.isHidden = builds.isEmpty
        emptyStateView.isHidden = !builds.isEmpty
        expireButton.isEnabled = !selectedBuildIDs.isEmpty

        if builds.isEmpty {
            onSelectBuild?(nil)
            return
        }

        let targetRow = min(max(tableView.selectedRow, 0), builds.count - 1)
        tableView.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)
        onSelectBuild?(builds[targetRow])
    }

    private func setLoading(_ isLoading: Bool) {
        loadingView.isHidden = !isLoading
    }

    private static func activeAccountKeyID() throws -> Int64? {
        try DatabaseManager.shared.dbQueue.read { db in
            try APIKeyRecord
                .filter(Column("is_active") == true)
                .fetchOne(db)?
                .id
        }
    }
}
