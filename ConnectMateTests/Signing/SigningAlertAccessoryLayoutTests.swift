import AppKit
import Testing
@testable import ConnectMate

@MainActor
struct SigningAlertAccessoryLayoutTests {
    @Test
    func accessoryContainerProvidesStableInitialFrame() {
        let field = NSTextField()
        let row = SigningAlertAccessoryFactory.makeRow(title: "Name", control: field)
        let container = SigningAlertAccessoryFactory.makeContainer(rows: [row])

        #expect(container.frame.width >= 300)
        #expect(container.frame.height > 0)
    }

    @Test
    func multiSelectPickerReturnsSelectedIdentifiers() {
        let picker = SigningMultiSelectPickerView(
            options: [
                .init(id: "CERT_1", title: "Apple Development", detail: "CERT_1"),
                .init(id: "CERT_2", title: "Apple Distribution", detail: "CERT_2")
            ],
            initiallySelectedIDs: ["CERT_2"]
        )

        #expect(picker.frame.height > 0)
        #expect(picker.selectedIDs == ["CERT_2"])
        #expect(findCheckboxButtons(in: picker).count == 2)
    }

    @Test
    func multiSelectPickerProvidesVisibleCheckboxFramesInsideAlertAccessory() throws {
        let picker = SigningMultiSelectPickerView(
            options: [
                .init(id: "CERT_1", title: "Apple Development", detail: "CERT_1"),
                .init(id: "CERT_2", title: "Apple Distribution", detail: "CERT_2"),
                .init(id: "CERT_3", title: "Apple Development", detail: "CERT_3")
            ]
        )
        let row = SigningAlertAccessoryFactory.makeRow(title: "Certificates", control: picker)
        let container = SigningAlertAccessoryFactory.makeContainer(rows: [row])
        let hostingWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
        hostingWindow.contentView = container

        hostingWindow.contentView?.layoutSubtreeIfNeeded()
        container.layoutSubtreeIfNeeded()
        row.layoutSubtreeIfNeeded()
        picker.layoutSubtreeIfNeeded()

        let checkboxFrames = findCheckboxButtons(in: picker).map(\.frame)
        let accessibilityFrames = findCheckboxButtons(in: picker).map { $0.accessibilityFrame() }
        #expect(checkboxFrames.count == 3)
        #expect(checkboxFrames.allSatisfy { $0.width > 40 && $0.height > 16 })
        #expect(accessibilityFrames.allSatisfy { $0.width > 40 && $0.height > 16 })
    }

    @Test
    func multiSelectPickerSelectAllAndInvertSelection() {
        let picker = SigningMultiSelectPickerView(
            options: [
                .init(id: "DEVICE_1", title: "Device 1", detail: "UDID-1"),
                .init(id: "DEVICE_2", title: "Device 2", detail: "UDID-2"),
                .init(id: "DEVICE_3", title: "Device 3", detail: "UDID-3")
            ],
            initiallySelectedIDs: ["DEVICE_2"]
        )

        picker.selectAll()
        #expect(picker.selectedIDs == ["DEVICE_1", "DEVICE_2", "DEVICE_3"])

        picker.invertSelection()
        #expect(picker.selectedIDs.isEmpty)

        picker.invertSelection()
        #expect(picker.selectedIDs == ["DEVICE_1", "DEVICE_2", "DEVICE_3"])
    }

    private func findCheckboxButtons(in rootView: NSView) -> [NSButton] {
        let current = (rootView as? NSButton).map { [$0] } ?? []
        return current + rootView.subviews.flatMap(findCheckboxButtons(in:))
    }
}
