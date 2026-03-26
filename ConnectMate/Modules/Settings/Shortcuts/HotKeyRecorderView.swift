import Cocoa
import SnapKit

final class HotKeyRecorderView: NSView {
    var onShortcutChange: ((String) -> Void)?

    private let valueField = NSTextField(labelWithString: "")
    private let recordButton = NSButton(title: "", target: nil, action: nil)
    private var isRecording = false {
        didSet { updateRecordingState() }
    }

    var shortcut: String = "" {
        didSet {
            valueField.stringValue = shortcut.isEmpty ? L10n.Settings.Shortcuts.notConfigured : shortcut
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let shortcut = Self.describe(event: event)
        self.shortcut = shortcut
        onShortcutChange?(shortcut)
        isRecording = false
    }

    @objc
    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            window?.makeFirstResponder(self)
        }
    }

    private func configure() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        valueField.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        valueField.stringValue = L10n.Settings.Shortcuts.notConfigured

        recordButton.title = L10n.Settings.Shortcuts.record
        recordButton.target = self
        recordButton.action = #selector(toggleRecording)

        addSubview(valueField)
        addSubview(recordButton)

        valueField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(recordButton.snp.leading).offset(-12)
        }

        recordButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(6)
        }

        snp.makeConstraints { make in
            make.height.equalTo(36)
        }
    }

    private func updateRecordingState() {
        recordButton.title = isRecording ? L10n.Settings.Shortcuts.stop : L10n.Settings.Shortcuts.record
        layer?.borderColor = (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
    }

    private static func describe(event: NSEvent) -> String {
        var parts: [String] = []
        if event.modifierFlags.contains(.command) { parts.append("cmd") }
        if event.modifierFlags.contains(.option) { parts.append("opt") }
        if event.modifierFlags.contains(.control) { parts.append("ctrl") }
        if event.modifierFlags.contains(.shift) { parts.append("shift") }

        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let key = characters.isEmpty ? "?" : characters
        parts.append(key)
        return parts.joined(separator: "+")
    }
}
