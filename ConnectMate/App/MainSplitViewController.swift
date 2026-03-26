import Cocoa
import SnapKit

final class MainSplitViewController: NSSplitViewController {
    private let router: AppRouter
    private let settings: AppSettings
    private let sidebarController: SidebarViewController
    private let listController = PaneHostViewController(role: .list)
    private let detailController = PaneHostViewController(role: .detail)
    private lazy var appDetailController = AppDetailViewController()
    private lazy var buildDetailController = BuildDetailViewController()
    private lazy var appListController: AppListViewController = {
        let controller = AppListViewController()
        controller.onSelectApp = { [weak self] app in
            self?.appDetailController.render(app: app)
        }
        return controller
    }()
    private lazy var buildListController: BuildListViewController = {
        let controller = BuildListViewController()
        controller.onSelectBuild = { [weak self] build in
            self?.buildDetailController.render(build: build)
        }
        return controller
    }()

    init(router: AppRouter, settings: AppSettings) {
        self.router = router
        self.settings = settings
        self.sidebarController = SidebarViewController(
            items: router.sections.map(SidebarItem.init(section:))
        )
        super.init(nibName: nil, bundle: nil)

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarController)
        sidebarItem.minimumThickness = 180
        sidebarItem.maximumThickness = 260
        sidebarItem.canCollapse = false

        let listItem = NSSplitViewItem(viewController: listController)
        listItem.minimumThickness = 380

        let detailItem = NSSplitViewItem(viewController: detailController)
        detailItem.minimumThickness = 320

        addSplitViewItem(sidebarItem)
        addSplitViewItem(listItem)
        addSplitViewItem(detailItem)

        sidebarController.onSelectSection = { [weak self] section in
            self?.show(section: section)
        }
        sidebarController.onOpenPreferences = {
            SettingsWindowController.shared.present()
        }

        let initialSection = router.initialSection(for: settings)
        sidebarController.select(section: initialSection)
        show(section: initialSection)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func show(section: AppSection) {
        switch section {
        case .apps:
            listController.display(appListController)
            detailController.display(appDetailController)
        case .builds:
            listController.display(buildListController)
            detailController.display(buildDetailController)
        default:
            let list = ModulePaneViewController(role: .list)
            list.render(
                title: section.contentTitle,
                detail: String(format: L10n.Modules.listDescription, section.title)
            )
            let detail = ModulePaneViewController(role: .detail)
            detail.render(
                title: "\(section.contentTitle) Detail",
                detail: String(format: L10n.Modules.detailDescription, section.title)
            )
            listController.display(list)
            detailController.display(detail)
        }
    }
}

private final class PaneHostViewController: NSViewController {
    private let role: ModulePaneRole
    private var currentChild: NSViewController?

    init(role: ModulePaneRole) {
        self.role = role
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = (role == .list ? NSColor.controlBackgroundColor : NSColor.windowBackgroundColor).cgColor
    }

    func display(_ child: NSViewController) {
        if let currentChild {
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }

        addChild(child)
        view.addSubview(child.view)
        child.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        currentChild = child
    }
}

private enum ModulePaneRole {
    case list
    case detail
}

private final class ModulePaneViewController: NSViewController {
    private let role: ModulePaneRole
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(wrappingLabelWithString: "")
    private let emptyStateView = EmptyStateView(symbolName: "square.stack.3d.up", title: "", detail: "")
    private let taskLabel = NSTextField(labelWithString: "")

    init(role: ModulePaneRole) {
        self.role = role
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskCenterUpdate),
            name: TaskCenter.didUpdateNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = (role == .list ? NSColor.controlBackgroundColor : NSColor.windowBackgroundColor).cgColor

        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2

        taskLabel.font = .systemFont(ofSize: 12, weight: .medium)
        taskLabel.textColor = .tertiaryLabelColor

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emptyStateView)
        view.addSubview(taskLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        taskLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(18)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }

        updateTaskFooter()
    }

    func render(title: String, detail: String) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = detail
        emptyStateView.update(
            symbolName: role == .list ? "line.3.horizontal.decrease.circle" : "sidebar.right",
            title: title,
            detail: detail
        )
    }

    @objc
    private func handleTaskCenterUpdate() {
        updateTaskFooter()
    }

    private func updateTaskFooter() {
        let activeCount = TaskCenter.shared.activeTasks().count
        taskLabel.stringValue = activeCount == 0
            ? L10n.Tasking.noActiveTasks
            : String(format: L10n.Tasking.activeTaskCount, activeCount)
    }
}
