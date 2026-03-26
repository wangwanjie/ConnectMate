import Cocoa
import SnapKit

final class APIKeyDropView: NSView {
    var onPathChange: ((String) -> Void)?

    private let titleLabel = NSTextField(labelWithString: "")
    private let pathLabel = NSTextField(labelWithString: "")
    private let chooseButton = NSButton(title: "", target: nil, action: nil)

    var filePath: String = "" {
        didSet {
            pathLabel.stringValue = filePath.isEmpty ? L10n.APIKeys.dragHint : filePath
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard
            let item = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]),
            let url = item.first as? URL,
            url.pathExtension.lowercased() == "p8"
        else {
            return false
        }

        apply(path: url.path)
        return true
    }

    @objc
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window ?? NSApp.keyWindow!) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.apply(path: url.path)
        }
    }

    private func configure() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        titleLabel.stringValue = L10n.APIKeys.privateKeyPath
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)

        pathLabel.stringValue = L10n.APIKeys.dragHint
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.lineBreakMode = .byTruncatingMiddle

        chooseButton.title = L10n.Common.browse
        chooseButton.target = self
        chooseButton.action = #selector(chooseFile)

        addSubview(titleLabel)
        addSubview(pathLabel)
        addSubview(chooseButton)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
        }

        chooseButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(titleLabel)
        }

        pathLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    private func apply(path: String) {
        filePath = path
        onPathChange?(path)
    }
}
