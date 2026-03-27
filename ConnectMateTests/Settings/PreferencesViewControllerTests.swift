import AppKit
import GRDB
import Testing
@testable import ConnectMate

@MainActor
struct PreferencesViewControllerTests {
    @Test
    func committingCLIPathOnEndEditingPersistsValue() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )

        _ = controller.view
        controller.navigate(to: PreferencesSection.cliAndAPI)

        let cliField = try #require(findTextField(in: controller.view, identifier: "cliPathField"))
        cliField.stringValue = "/opt/homebrew/bin/asc"
        controller.controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification, object: cliField))

        #expect(settings.cliPath == "/opt/homebrew/bin/asc")
    }

    @Test
    func cliPathFieldHasVisibleWidthAndDisplaysSavedValue() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        settings.cliPath = "/usr/local/bin/asc"

        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )
        let window = NSWindow(contentViewController: controller)
        window.setContentSize(NSSize(width: 920, height: 720))

        _ = controller.view
        controller.navigate(to: PreferencesSection.cliAndAPI)
        controller.view.layoutSubtreeIfNeeded()

        let cliField = try #require(findTextField(in: controller.view, identifier: "cliPathField"))
        #expect(cliField.stringValue == "/usr/local/bin/asc")
        #expect(cliField.bounds.width > 200)
    }

    @Test
    func usesSegmentedControlForSectionNavigation() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )

        _ = controller.view

        let segmentedControl = try #require(findSegmentedControl(in: controller.view))
        #expect(segmentedControl.segmentCount == PreferencesSection.allCases.count)
        #expect(segmentedControl.label(forSegment: 0) == PreferencesSection.general.title)
    }

    @Test
    func switchingSectionsResizesHostingWindowHeight() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )
        let window = NSWindow(contentViewController: controller)
        window.setContentSize(NSSize(width: 720, height: 420))

        _ = controller.view
        controller.view.layoutSubtreeIfNeeded()
        let initialHeight = window.frame.height

        controller.navigate(to: .about)
        controller.view.layoutSubtreeIfNeeded()

        #expect(abs(window.frame.height - initialHeight) > 1)
    }

    @Test
    func clipsSectionContainerDuringResizeAnimation() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )
        let window = NSWindow(contentViewController: controller)
        window.setContentSize(NSSize(width: 720, height: 420))

        _ = controller.view
        controller.navigate(to: .about)
        controller.view.layoutSubtreeIfNeeded()

        let sectionContainer = try #require(findView(in: controller.view, identifier: "preferences.sectionContainer"))
        #expect(sectionContainer.wantsLayer)
        #expect(sectionContainer.layer?.masksToBounds == true)
    }

    @Test
    func hostedWindowResizeDoesNotUsePreferredContentSize() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )
        let window = NSWindow(contentViewController: controller)
        window.setContentSize(NSSize(width: 720, height: 420))

        _ = controller.view
        controller.navigate(to: .about)
        controller.view.layoutSubtreeIfNeeded()

        #expect(controller.preferredContentSize == .zero)
    }

    @Test
    func detachedControllerDoesNotSetPreferredContentSizeDuringSectionSync() throws {
        let suiteName = "ConnectMateTests.PreferencesViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = PreferencesViewController(
            settings: settings,
            updateManager: PreferencesUpdateManagerStub(),
            dataExportService: AppDataExportService(dbWriter: try DatabaseQueue())
        )

        _ = controller.view
        controller.navigate(to: .about)

        #expect(controller.preferredContentSize == .zero)
    }

    private func findTextField(in rootView: NSView, identifier: String) -> NSTextField? {
        if let textField = rootView as? NSTextField, textField.identifier?.rawValue == identifier {
            return textField
        }

        for subview in rootView.subviews {
            if let match = findTextField(in: subview, identifier: identifier) {
                return match
            }
        }
        return nil
    }

    private func findSegmentedControl(in rootView: NSView) -> NSSegmentedControl? {
        if let segmentedControl = rootView as? NSSegmentedControl {
            return segmentedControl
        }

        for subview in rootView.subviews {
            if let match = findSegmentedControl(in: subview) {
                return match
            }
        }

        return nil
    }

    private func findView(in rootView: NSView, identifier: String) -> NSView? {
        if rootView.identifier?.rawValue == identifier {
            return rootView
        }

        for subview in rootView.subviews {
            if let match = findView(in: subview, identifier: identifier) {
                return match
            }
        }

        return nil
    }
}

@MainActor
private final class PreferencesUpdateManagerStub: AppUpdateManaging {
    var canCheckForUpdates: Bool = true

    func configure() {}
    func scheduleBackgroundUpdateCheck() {}
    func checkForUpdates() {}
    func openRepository() {}
    func openIssues() {}
    func openCLIRepository() {}
}
