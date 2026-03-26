import Cocoa

final class MainSplitViewController: NSSplitViewController {
    init(router: AppRouter) {
        super.init(nibName: nil, bundle: nil)

        let sidebarController = SidebarPlaceholderViewController(sections: router.sections)
        let listController = PanePlaceholderViewController(
            title: "List",
            subtitle: "ConnectMate will render module lists here."
        )
        let detailController = PanePlaceholderViewController(
            title: "Detail",
            subtitle: "ConnectMate will render module detail content here."
        )

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
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SidebarPlaceholderViewController: NSViewController {
    private let sections: [AppSection]

    init(sections: [AppSection]) {
        self.sections = sections
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = NSTextField(labelWithString: L10n.App.name)
        headerLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        stackView.addArrangedSubview(headerLabel)

        let separator = NSBox()
        separator.boxType = .separator
        stackView.addArrangedSubview(separator)

        for section in sections {
            let label = NSTextField(labelWithString: section.title)
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.setContentCompressionResistancePriority(.required, for: .vertical)
            stackView.addArrangedSubview(label)
        }

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
}

private final class PanePlaceholderViewController: NSViewController {
    private let titleText: String
    private let subtitleText: String

    init(title: String, subtitle: String) {
        self.titleText = title
        self.subtitleText = subtitle
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

        let titleLabel = NSTextField(labelWithString: titleText)
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = NSTextField(wrappingLabelWithString: subtitleText)
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -28)
        ])
    }
}
