import Cocoa
import SnapKit

final class SidebarViewController: NSViewController {
    var onSelectSection: ((AppSection) -> Void)?
    var onOpenPreferences: (() -> Void)?

    private let items: [SidebarItem]
    private let settingsTitle: String
    private var buttons: [AppSection: NSButton] = [:]
    private let buttonStack = NSStackView()
    private let footerStack = NSStackView()
    private let settingsButton = NSButton(title: "", target: nil, action: nil)
    private var selectedSection: AppSection?

    init(items: [SidebarItem], settingsTitle: String = L10n.Sidebar.settings) {
        self.items = items
        self.settingsTitle = settingsTitle
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

        let headerLabel = NSTextField(labelWithString: L10n.App.name)
        headerLabel.font = .systemFont(ofSize: 24, weight: .semibold)

        buttonStack.orientation = .vertical
        buttonStack.spacing = 8
        buttonStack.alignment = .leading

        for item in items {
            let button = makeSidebarButton(title: item.title, symbolName: item.symbolName, action: #selector(handleSectionSelection(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(item.section.rawValue)
            button.tag = items.firstIndex(of: item) ?? 0
            buttons[item.section] = button
            buttonStack.addArrangedSubview(button)
        }

        settingsButton.title = settingsTitle
        settingsButton.isBordered = false
        settingsButton.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: settingsTitle)
        settingsButton.imagePosition = .imageLeading
        settingsButton.font = .systemFont(ofSize: 13, weight: .medium)
        settingsButton.contentTintColor = .secondaryLabelColor
        settingsButton.bezelStyle = .recessed
        settingsButton.setButtonType(.momentaryPushIn)
        settingsButton.target = self
        settingsButton.action = #selector(handleOpenPreferences)

        footerStack.orientation = .vertical
        footerStack.addArrangedSubview(settingsButton)

        let container = NSStackView(views: [headerLabel, buttonStack, NSView(), footerStack])
        container.orientation = .vertical
        container.spacing = 18

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 20, left: 14, bottom: 14, right: 14))
        }
    }

    func select(section: AppSection) {
        selectedSection = section
        updateButtonStyles()
    }

    @objc
    private func handleSectionSelection(_ sender: NSButton) {
        guard sender.tag < items.count else { return }
        let section = items[sender.tag].section
        select(section: section)
        onSelectSection?(section)
    }

    @objc
    private func handleOpenPreferences() {
        onOpenPreferences?()
    }

    private func makeSidebarButton(title: String, symbolName: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.setButtonType(.momentaryChange)
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)
        button.imagePosition = .imageLeading
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.bezelStyle = .recessed
        button.contentTintColor = .secondaryLabelColor
        button.alignment = .left
        button.snp.makeConstraints { make in
            make.width.equalTo(180)
            make.height.equalTo(30)
        }
        return button
    }

    private func updateButtonStyles() {
        for (section, button) in buttons {
            let isSelected = section == selectedSection
            button.contentTintColor = isSelected ? .white : .secondaryLabelColor
            button.layer?.backgroundColor = nil

            if isSelected {
                button.wantsLayer = true
                button.layer?.cornerRadius = 8
                button.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            } else {
                button.layer?.backgroundColor = NSColor.clear.cgColor
            }
        }
    }
}
