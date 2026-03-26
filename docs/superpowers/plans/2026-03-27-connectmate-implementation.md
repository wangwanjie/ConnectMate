# ConnectMate 1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and release a fully functional AppKit-based macOS app for App Store Connect workflows, backed by the local `asc` CLI, with all requested modules completed and shipped as version 1.0.

**Architecture:** Rebuild the current template project into a code-first AppKit application with a stable app shell, shared service layer, GRDB-backed persistence, async CLI orchestration, modular feature controllers, and a release pipeline that reuses the existing HostsEditor signing and notarization model. Implement shared infrastructure first, then layer Apps, Builds, Review, TestFlight, IAP, logs, settings, updates, and release automation on top of the same command runner, task center, and cache strategy.

**Tech Stack:** Swift, AppKit, SnapKit, GRDB, Sparkle 2.x, CocoaPods for ViewScopeServer/LookinServer, `Process`/`Pipe`, Swift Testing, XCTest UI tests, `xcodebuild`, `gh`

---

## Planned File Structure

### App Shell

- Create: `ConnectMate/App/AppDelegate.swift`
- Create: `ConnectMate/App/MainWindowController.swift`
- Create: `ConnectMate/App/MainSplitViewController.swift`
- Create: `ConnectMate/App/AppThemeManager.swift`
- Create: `ConnectMate/App/AppBootstrap.swift`
- Create: `ConnectMate/App/AppRouter.swift`
- Modify: `ConnectMate.xcodeproj/project.pbxproj`
- Modify: `ConnectMate/AppDelegate.swift`
- Modify: `ConnectMate/ViewController.swift`
- Remove usage of: `ConnectMate/Base.lproj/Main.storyboard`

### Core

- Create: `ConnectMate/Core/CLI/ASCCommandRunner.swift`
- Create: `ConnectMate/Core/CLI/ASCCommandConfiguration.swift`
- Create: `ConnectMate/Core/CLI/ASCCommandResult.swift`
- Create: `ConnectMate/Core/CLI/ASCOutputParser.swift`
- Create: `ConnectMate/Core/CLI/ASCError.swift`
- Create: `ConnectMate/Core/Database/DatabaseManager.swift`
- Create: `ConnectMate/Core/Database/DatabaseMigrator.swift`
- Create: `ConnectMate/Core/Database/Models/*.swift`
- Create: `ConnectMate/Core/Settings/AppSettings.swift`
- Create: `ConnectMate/Core/Settings/PreferencesModels.swift`
- Create: `ConnectMate/Core/Settings/SettingKey.swift`
- Create: `ConnectMate/Core/Logging/CommandLogRepository.swift`
- Create: `ConnectMate/Core/Logging/CommandLogRecord.swift`
- Create: `ConnectMate/Core/Tasking/TaskCenter.swift`
- Create: `ConnectMate/Core/Tasking/TaskProgress.swift`
- Create: `ConnectMate/Core/Updater/SparkleUpdater.swift`

### Shared UI

- Create: `ConnectMate/Modules/Common/LoadingView.swift`
- Create: `ConnectMate/Modules/Common/EmptyStateView.swift`
- Create: `ConnectMate/Modules/Common/ErrorStateView.swift`
- Create: `ConnectMate/Modules/Common/ToastManager.swift`
- Create: `ConnectMate/Modules/Common/ConfirmDialogHelper.swift`
- Create: `ConnectMate/Modules/Common/AsyncImageView.swift`
- Create: `ConnectMate/Modules/Common/SectionHeaderView.swift`

### Feature Modules

- Create: `ConnectMate/Modules/Sidebar/*`
- Create: `ConnectMate/Modules/Settings/*`
- Create: `ConnectMate/Modules/Apps/*`
- Create: `ConnectMate/Modules/Builds/*`
- Create: `ConnectMate/Modules/Review/*`
- Create: `ConnectMate/Modules/TestFlight/*`
- Create: `ConnectMate/Modules/InAppPurchase/*`
- Create: `ConnectMate/Modules/Logs/*`
- Create: `ConnectMate/Modules/About/*`

### Resources and Release

- Create: `ConnectMate/Resources/Info.plist`
- Create: `ConnectMate/en.lproj/Localizable.strings`
- Create: `ConnectMate/zh-Hans.lproj/Localizable.strings`
- Create: `ConnectMate/zh-Hant.lproj/Localizable.strings`
- Create: `ConnectMate/Scripts/build_release.sh`
- Create: `ConnectMate/Scripts/publish_release.sh`
- Create: `ConnectMate/Scripts/generate_appcast.sh`
- Modify: `Podfile`
- Modify: `ConnectMate/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Modify: `ConnectMate.xcodeproj/project.pbxproj`
- Modify: `appcast.xml`

### Tests

- Create: `ConnectMateTests/TestSupport/FixtureLoader.swift`
- Create: `ConnectMateTests/Settings/AppSettingsTests.swift`
- Create: `ConnectMateTests/Database/DatabaseMigrationTests.swift`
- Create: `ConnectMateTests/CLI/ASCCommandRunnerTests.swift`
- Create: `ConnectMateTests/CLI/ASCOutputParserTests.swift`
- Create: `ConnectMateTests/Apps/AppServiceTests.swift`
- Create: `ConnectMateTests/Builds/BuildServiceTests.swift`
- Create: `ConnectMateTests/Review/ReviewServiceTests.swift`
- Create: `ConnectMateTests/TestFlight/TestFlightServiceTests.swift`
- Create: `ConnectMateTests/InAppPurchase/IAPServiceTests.swift`
- Modify: `ConnectMateTests/ConnectMateTests.swift`
- Modify: `ConnectMateUITests/ConnectMateUITests.swift`
- Modify: `ConnectMateUITests/ConnectMateUITestsLaunchTests.swift`

### Fixtures

- Create: `ConnectMateTests/Fixtures/apps-list.json`
- Create: `ConnectMateTests/Fixtures/builds-list.json`
- Create: `ConnectMateTests/Fixtures/review-submission.json`
- Create: `ConnectMateTests/Fixtures/testflight-testers.json`
- Create: `ConnectMateTests/Fixtures/testflight-groups.json`
- Create: `ConnectMateTests/Fixtures/iap-list.json`
- Create: `ConnectMateTests/Fixtures/asc-stdout-success.txt`
- Create: `ConnectMateTests/Fixtures/asc-stderr-failure.txt`

### Build Environment Notes

- Keep CocoaPods for `ViewScopeServer` and `LookinServer`
- Add Swift Package dependencies for SnapKit, GRDB, and Sparkle in `ConnectMate.xcodeproj/project.pbxproj`
- Continue to build and test from `ConnectMate.xcworkspace`
- Normalize all deployment targets to macOS 13.0

## Task 1: Rebuild The Template Project Into A Code-First App Shell

**Files:**
- Modify: `ConnectMate.xcodeproj/project.pbxproj`
- Modify: `Podfile`
- Modify: `ConnectMate/AppDelegate.swift`
- Modify: `ConnectMate/ViewController.swift`
- Create: `ConnectMate/App/AppDelegate.swift`
- Create: `ConnectMate/App/AppBootstrap.swift`
- Create: `ConnectMate/App/MainWindowController.swift`
- Create: `ConnectMate/App/MainSplitViewController.swift`
- Create: `ConnectMate/App/AppRouter.swift`
- Create: `ConnectMate/Resources/Info.plist`
- Test: `ConnectMateUITests/ConnectMateUITests.swift`

- [ ] **Step 1: Write the failing UI smoke test for code-first launch**

```swift
@MainActor
func testLaunchesIntoThreePaneShell() throws {
    let app = XCUIApplication()
    app.launchEnvironment["CONNECTMATE_UI_TEST_MODE"] = "1"
    app.launch()

    XCTAssertTrue(app.splitGroups.firstMatch.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["我的 App"].exists)
    XCTAssertTrue(app.staticTexts["设置"].exists)
}
```

- [ ] **Step 2: Run the UI test to verify it fails**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateUITests/ConnectMateUITests/testLaunchesIntoThreePaneShell test
```

Expected: FAIL because the app still launches from the storyboard template and no split shell exists.

- [ ] **Step 3: Replace storyboard bootstrap with code-first bootstrap**

Implement:

- remove `NSMainStoryboardFile` usage from the app target
- create `App/AppDelegate.swift` as the real entry point
- initialize `MainWindowController` from code
- attach an empty `MainSplitViewController` with placeholder panes
- keep deployment target and bundle identifier intact
- keep Pods integration intact while adding SPM package references

- [ ] **Step 4: Normalize project build settings**

Set in `ConnectMate.xcodeproj/project.pbxproj`:

- app and test targets use macOS 13.0
- app uses the new `ConnectMate/Resources/Info.plist`
- storyboard is no longer required
- SPM dependencies are added for SnapKit, GRDB, Sparkle

- [ ] **Step 5: Re-run the UI smoke test**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateUITests/ConnectMateUITests/testLaunchesIntoThreePaneShell test
```

Expected: PASS with a visible three-pane shell.

- [ ] **Step 6: Commit**

```bash
git add ConnectMate.xcodeproj/project.pbxproj Podfile ConnectMate/AppDelegate.swift ConnectMate/ViewController.swift ConnectMate/App ConnectMate/Resources/Info.plist ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: rebuild ConnectMate as code-first app shell"
```

## Task 2: Add Shared Settings, Localization, Theme, And Preferences Models

**Files:**
- Create: `ConnectMate/Core/Settings/AppSettings.swift`
- Create: `ConnectMate/Core/Settings/SettingKey.swift`
- Create: `ConnectMate/Core/Settings/PreferencesModels.swift`
- Create: `ConnectMate/App/AppThemeManager.swift`
- Create: `ConnectMate/Modules/Settings/Localization.swift`
- Create: `ConnectMate/en.lproj/Localizable.strings`
- Create: `ConnectMate/zh-Hans.lproj/Localizable.strings`
- Create: `ConnectMate/zh-Hant.lproj/Localizable.strings`
- Test: `ConnectMateTests/Settings/AppSettingsTests.swift`

- [ ] **Step 1: Write the failing settings persistence tests**

```swift
@Test
func persistsAppearanceAndCliPreferences() throws {
    let settings = AppSettings(userDefaults: UserDefaults(suiteName: "AppSettingsTests")!)
    settings.appearanceMode = .dark
    settings.cliPath = "/opt/homebrew/bin/asc"
    settings.commandTimeout = 45

    let reloaded = AppSettings(userDefaults: settings.userDefaults)
    #expect(reloaded.appearanceMode == .dark)
    #expect(reloaded.cliPath == "/opt/homebrew/bin/asc")
    #expect(reloaded.commandTimeout == 45)
}
```

- [ ] **Step 2: Run the settings tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/AppSettingsTests test
```

Expected: FAIL because `AppSettings` and preference enums do not exist.

- [ ] **Step 3: Implement strongly typed settings models**

Implement:

- enums for appearance, list density, notification mode, cache policy, update strategy
- `AppSettings` wrappers around `UserDefaults`
- centralized keys in `SettingKey`
- localization helper for all user-facing setting labels

- [ ] **Step 4: Implement theme application**

Implement:

- `AppThemeManager` that maps `.system`, `.light`, `.dark` to `NSApplication.appearance`
- startup hook in the app shell to apply the saved theme

- [ ] **Step 5: Re-run the settings tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/AppSettingsTests test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ConnectMate/Core/Settings ConnectMate/App/AppThemeManager.swift ConnectMate/Modules/Settings/Localization.swift ConnectMate/en.lproj/Localizable.strings ConnectMate/zh-Hans.lproj/Localizable.strings ConnectMate/zh-Hant.lproj/Localizable.strings ConnectMateTests/Settings/AppSettingsTests.swift
git commit -m "feat: add settings, localization, and theme infrastructure"
```

## Task 3: Add GRDB Database, Migrations, And Command Logging

**Files:**
- Create: `ConnectMate/Core/Database/DatabaseManager.swift`
- Create: `ConnectMate/Core/Database/DatabaseMigrator.swift`
- Create: `ConnectMate/Core/Database/Models/APIKeyRecord.swift`
- Create: `ConnectMate/Core/Database/Models/AppRecord.swift`
- Create: `ConnectMate/Core/Database/Models/BuildRecord.swift`
- Create: `ConnectMate/Core/Database/Models/ReviewSubmissionRecord.swift`
- Create: `ConnectMate/Core/Database/Models/TesterRecord.swift`
- Create: `ConnectMate/Core/Database/Models/BetaGroupRecord.swift`
- Create: `ConnectMate/Core/Database/Models/IAPProductRecord.swift`
- Create: `ConnectMate/Core/Logging/CommandLogRecord.swift`
- Create: `ConnectMate/Core/Logging/CommandLogRepository.swift`
- Test: `ConnectMateTests/Database/DatabaseMigrationTests.swift`

- [ ] **Step 1: Write the failing migration test**

```swift
@Test
func migrationsCreateCoreTables() throws {
    let dbQueue = try DatabaseQueue()
    try DatabaseMigrator.connectMate.migrate(dbQueue)

    try dbQueue.read { db in
        #expect(try db.tableExists("api_keys"))
        #expect(try db.tableExists("apps"))
        #expect(try db.tableExists("builds"))
        #expect(try db.tableExists("command_logs"))
    }
}
```

- [ ] **Step 2: Run the migration test to verify it fails**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/DatabaseMigrationTests test
```

Expected: FAIL because GRDB migration code does not exist.

- [ ] **Step 3: Implement database bootstrapping and schema**

Implement:

- database location under Application Support
- migrator with the core tables from the approved spec
- lightweight records for CRUD and cache persistence
- startup initialization through `AppBootstrap`

- [ ] **Step 4: Add command log repository**

Implement:

- insert log row for every command execution
- query rows for the future logs page
- cleanup API for retention policy

- [ ] **Step 5: Re-run the migration test**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/DatabaseMigrationTests test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ConnectMate/Core/Database ConnectMate/Core/Logging ConnectMateTests/Database/DatabaseMigrationTests.swift
git commit -m "feat: add GRDB schema and command logging"
```

## Task 4: Implement The ASC Command Runner And Output Parser Foundation

**Files:**
- Create: `ConnectMate/Core/CLI/ASCCommandConfiguration.swift`
- Create: `ConnectMate/Core/CLI/ASCCommandResult.swift`
- Create: `ConnectMate/Core/CLI/ASCError.swift`
- Create: `ConnectMate/Core/CLI/ASCCommandRunner.swift`
- Create: `ConnectMate/Core/CLI/ASCOutputParser.swift`
- Create: `ConnectMateTests/TestSupport/FixtureLoader.swift`
- Create: `ConnectMateTests/Fixtures/apps-list.json`
- Create: `ConnectMateTests/Fixtures/builds-list.json`
- Create: `ConnectMateTests/Fixtures/asc-stdout-success.txt`
- Create: `ConnectMateTests/Fixtures/asc-stderr-failure.txt`
- Create: `ConnectMateTests/CLI/ASCCommandRunnerTests.swift`
- Create: `ConnectMateTests/CLI/ASCOutputParserTests.swift`

- [ ] **Step 1: Write the failing parser tests**

```swift
@Test
func parsesAppListResponse() throws {
    let json = try FixtureLoader.data(named: "apps-list.json")
    let apps = try ASCOutputParser().decodeApps(from: json)

    #expect(apps.count == 2)
    #expect(apps.first?.bundleID == "com.example.first")
}
```

```swift
@Test
func runnerSurfacesTimeoutAsStructuredError() async throws {
    let runner = ASCCommandRunner(configuration: .init(cliPath: "/bin/sleep", timeout: 0.1))
    await #expect(throws: ASCError.timeout) {
        _ = try await runner.run(arguments: ["2"])
    }
}
```

- [ ] **Step 2: Run the CLI tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/ASCOutputParserTests -only-testing:ConnectMateTests/ASCCommandRunnerTests test
```

Expected: FAIL because the parser, fixtures, and runner do not exist.

- [ ] **Step 3: Implement the async runner**

Implement:

- `Process` + `Pipe`
- timeout and cancellation
- env injection for `HTTP_PROXY`, `HTTPS_PROXY`, `ASC_TIMEOUT`, `ASC_PROFILE`
- retry wrapper driven by settings
- structured stdout/stderr/exit code result

- [ ] **Step 4: Implement parser entry points**

Implement:

- app list decoder
- build list decoder
- generic JSON decoding helper
- fallback plain-text extraction for diagnostics

- [ ] **Step 5: Wire logging into runner execution**

Integrate `CommandLogRepository` so every run captures command, output, exit code, and duration.

- [ ] **Step 6: Re-run the CLI tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/ASCOutputParserTests -only-testing:ConnectMateTests/ASCCommandRunnerTests test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add ConnectMate/Core/CLI ConnectMateTests/TestSupport ConnectMateTests/Fixtures ConnectMateTests/CLI
git commit -m "feat: add asc command runner and parser foundation"
```

## Task 5: Build Shared UI Shell, Sidebar, Task Center, And Preferences Window

**Files:**
- Create: `ConnectMate/Core/Tasking/TaskCenter.swift`
- Create: `ConnectMate/Core/Tasking/TaskProgress.swift`
- Create: `ConnectMate/Modules/Common/LoadingView.swift`
- Create: `ConnectMate/Modules/Common/EmptyStateView.swift`
- Create: `ConnectMate/Modules/Common/ErrorStateView.swift`
- Create: `ConnectMate/Modules/Common/ToastManager.swift`
- Create: `ConnectMate/Modules/Common/ConfirmDialogHelper.swift`
- Create: `ConnectMate/Modules/Common/AsyncImageView.swift`
- Create: `ConnectMate/Modules/Sidebar/SidebarItem.swift`
- Create: `ConnectMate/Modules/Sidebar/SidebarViewController.swift`
- Create: `ConnectMate/Modules/Settings/SettingsWindowController.swift`
- Create: `ConnectMate/Modules/Settings/PreferencesViewController.swift`
- Create: `ConnectMate/Modules/Settings/Shortcuts/HotKeyRecorderView.swift`
- Create: `ConnectMate/Modules/Settings/Shortcuts/GlobalHotKey.swift`
- Test: `ConnectMateUITests/ConnectMateUITests.swift`

- [ ] **Step 1: Write the failing UI navigation test**

```swift
@MainActor
func testCanOpenPreferencesAndSelectBuildsModule() throws {
    let app = XCUIApplication()
    app.launchEnvironment["CONNECTMATE_UI_TEST_MODE"] = "1"
    app.launch()

    app.buttons["设置"].click()
    XCTAssertTrue(app.windows["Preferences"].waitForExistence(timeout: 3))
    app.staticTexts["构建版本"].click()
    XCTAssertTrue(app.staticTexts["Builds"].waitForExistence(timeout: 3))
}
```

- [ ] **Step 2: Run the UI navigation test to verify it fails**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateUITests/ConnectMateUITests/testCanOpenPreferencesAndSelectBuildsModule test
```

Expected: FAIL because the sidebar and preferences window do not exist yet.

- [ ] **Step 3: Implement shared shell UI**

Implement:

- sidebar item model and AppKit outline/table presentation
- placeholder list/detail panes per module
- reusable loading, empty, and error views
- toast manager and confirm helper
- `TaskCenter` UI hooks for future background operations

- [ ] **Step 4: Implement preferences window sections**

Implement:

- General, Appearance, Notifications, CLI & API, Data & Cache, Updates, Shortcuts, About
- controls bound to `AppSettings`
- hotkey recorder shell using the referenced Carbon pattern when needed
- clear messaging when only partial conflict detection is available

- [ ] **Step 5: Re-run the UI navigation test**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateUITests/ConnectMateUITests/testCanOpenPreferencesAndSelectBuildsModule test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ConnectMate/Core/Tasking ConnectMate/Modules/Common ConnectMate/Modules/Sidebar ConnectMate/Modules/Settings ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: add shared shell ui, preferences, and task center"
```

## Task 6: Implement API Key Management And First-Launch Checks

**Files:**
- Create: `ConnectMate/Modules/Settings/APIKey/APIKeyViewController.swift`
- Create: `ConnectMate/Modules/Settings/APIKey/APIKeyService.swift`
- Create: `ConnectMate/Modules/Settings/APIKey/APIKeyDropView.swift`
- Create: `ConnectMate/Modules/Settings/Onboarding/CLISetupViewController.swift`
- Modify: `ConnectMate/App/AppBootstrap.swift`
- Modify: `ConnectMate/Core/Database/Models/APIKeyRecord.swift`
- Test: `ConnectMateTests/Settings/APIKeyServiceTests.swift`
- Test: `ConnectMateUITests/ConnectMateUITests.swift`

- [ ] **Step 1: Write the failing API key service test**

```swift
@Test
func validateProfileBuildsExpectedAscLoginArguments() throws {
    let service = APIKeyService(runner: .capturing())
    try await service.validate(
        name: "Main",
        issuerID: "ISSUER",
        keyID: "KEY",
        privateKeyPath: "/tmp/AuthKey.p8"
    )

    #expect(service.capturedArguments == [
        "auth", "login",
        "--name", "Main",
        "--key-id", "KEY",
        "--issuer-id", "ISSUER",
        "--private-key", "/tmp/AuthKey.p8",
        "--network"
    ])
}
```

- [ ] **Step 2: Run the API key tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/APIKeyServiceTests test
```

Expected: FAIL because the API key feature does not exist yet.

- [ ] **Step 3: Implement API key CRUD and validation flow**

Implement:

- create, edit, activate, and switch profiles
- drag-and-drop `.p8` field
- validation via `asc auth login --network`
- status via `asc auth status --validate` and `asc auth doctor`
- persistent storage in GRDB

- [ ] **Step 4: Implement first-launch checks**

Implement:

- check if the configured CLI path exists
- run `asc version`
- detect missing credentials
- route users into the CLI setup / API key onboarding screen when required

- [ ] **Step 5: Add a UI test for the missing-cli onboarding path**

Extend `ConnectMateUITests/ConnectMateUITests.swift` with a launch environment override that points `asc` to a missing binary and verifies the setup screen appears.

- [ ] **Step 6: Run tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/APIKeyServiceTests -only-testing:ConnectMateUITests/ConnectMateUITests test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add ConnectMate/Modules/Settings/APIKey ConnectMate/Modules/Settings/Onboarding ConnectMate/App/AppBootstrap.swift ConnectMate/Core/Database/Models/APIKeyRecord.swift ConnectMateTests/Settings/APIKeyServiceTests.swift ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: add api key management and first-launch checks"
```

## Task 7: Implement The Apps Module With Cache, Search, And Detail Pane

**Files:**
- Create: `ConnectMate/Modules/Apps/AppSummary.swift`
- Create: `ConnectMate/Modules/Apps/AppRepository.swift`
- Create: `ConnectMate/Modules/Apps/AppService.swift`
- Create: `ConnectMate/Modules/Apps/AppListViewController.swift`
- Create: `ConnectMate/Modules/Apps/AppDetailViewController.swift`
- Modify: `ConnectMate/Core/CLI/ASCOutputParser.swift`
- Modify: `ConnectMate/Core/Database/Models/AppRecord.swift`
- Create: `ConnectMateTests/Apps/AppServiceTests.swift`
- Create: `ConnectMateTests/Fixtures/apps-list.json`

- [ ] **Step 1: Write the failing app service test**

```swift
@Test
func refreshAppsParsesAndCachesAppList() async throws {
    let service = AppService(runner: .fixture("apps-list.json"), repository: .inMemory)
    let apps = try await service.refreshApps(search: nil)

    #expect(apps.count == 2)
    #expect(try service.repository.fetchAll().count == 2)
}
```

- [ ] **Step 2: Run the app service test to verify it fails**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/AppServiceTests test
```

Expected: FAIL because the Apps module service and repository do not exist.

- [ ] **Step 3: Implement app repository and service**

Implement:

- fetch from cache
- refresh via `asc apps list --output json`
- filter by search text
- cache by active account
- expose selection state for the detail pane

- [ ] **Step 4: Implement app list and detail controllers**

Implement:

- icon loading
- search field
- manual refresh
- detail cards for bundle ID, platform, current state, and raw identifiers

- [ ] **Step 5: Add a UI test for sidebar -> Apps**

Add a test that launches in fixture mode and verifies the apps table and detail pane populate with stubbed data.

- [ ] **Step 6: Run tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/AppServiceTests -only-testing:ConnectMateUITests/ConnectMateUITests test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add ConnectMate/Modules/Apps ConnectMate/Core/CLI/ASCOutputParser.swift ConnectMate/Core/Database/Models/AppRecord.swift ConnectMateTests/Apps/AppServiceTests.swift ConnectMateTests/Fixtures/apps-list.json ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: add apps browsing and caching"
```

## Task 8: Implement The Builds Module And Shared Batch Expiration Flow

**Files:**
- Create: `ConnectMate/Modules/Builds/BuildSummary.swift`
- Create: `ConnectMate/Modules/Builds/BuildRepository.swift`
- Create: `ConnectMate/Modules/Builds/BuildService.swift`
- Create: `ConnectMate/Modules/Builds/BuildListViewController.swift`
- Create: `ConnectMate/Modules/Builds/BuildDetailViewController.swift`
- Modify: `ConnectMate/Core/CLI/ASCOutputParser.swift`
- Modify: `ConnectMate/Core/Database/Models/BuildRecord.swift`
- Create: `ConnectMateTests/Builds/BuildServiceTests.swift`
- Create: `ConnectMateTests/Fixtures/builds-list.json`

- [ ] **Step 1: Write the failing build service tests**

```swift
@Test
func refreshBuildsForAppCachesProcessingState() async throws {
    let service = BuildService(runner: .fixture("builds-list.json"), repository: .inMemory)
    let builds = try await service.refreshBuilds(appID: "123")

    #expect(builds.first?.processingState == .valid)
}
```

```swift
@Test
func expireSelectedBuildsSchedulesBatchTasks() async throws {
    let service = BuildService(runner: .capturing(), repository: .inMemory)
    try await service.expireBuilds(["BUILD_1", "BUILD_2"])
    #expect(service.capturedCommands.count == 2)
}
```

- [ ] **Step 2: Run the build service tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/BuildServiceTests test
```

Expected: FAIL because the Builds module does not exist.

- [ ] **Step 3: Implement build repository and service**

Implement:

- app-scoped build refresh
- parser support for version/build/status/uploaded date
- batch expiration flow with `TaskCenter`
- list filters by app and status

- [ ] **Step 4: Implement build list and detail controllers**

Implement:

- app filter popup
- batch selection UI
- expire action with confirmation
- detail pane for build metadata and TestFlight linkage

- [ ] **Step 5: Run tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/BuildServiceTests test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ConnectMate/Modules/Builds ConnectMate/Core/CLI/ASCOutputParser.swift ConnectMate/Core/Database/Models/BuildRecord.swift ConnectMateTests/Builds/BuildServiceTests.swift ConnectMateTests/Fixtures/builds-list.json
git commit -m "feat: add build management and batch expiration"
```

## Task 9: Implement Review Submission, Status Tracking, And Batch Submission

**Files:**
- Create: `ConnectMate/Modules/Review/ReviewSubmissionDraft.swift`
- Create: `ConnectMate/Modules/Review/ReviewService.swift`
- Create: `ConnectMate/Modules/Review/SubmitReviewViewController.swift`
- Create: `ConnectMate/Modules/Review/ReviewStatusViewController.swift`
- Create: `ConnectMate/Modules/Review/ReviewBatchProgressViewController.swift`
- Create: `ConnectMateTests/Review/ReviewServiceTests.swift`
- Create: `ConnectMateTests/Fixtures/review-submission.json`

- [ ] **Step 1: Write the failing review service tests**

```swift
@Test
func preflightRunsBeforeSubmission() async throws {
    let service = ReviewService(runner: .capturing(), repository: .inMemory)
    try await service.submit(
        drafts: [.fixture(appID: "123", versionID: "456", buildID: "789")]
    )

    #expect(service.capturedCommands.first?.prefix(3) == ["submit", "preflight", "--app"])
    #expect(service.capturedCommands.count >= 2)
}
```

- [ ] **Step 2: Run the review tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/ReviewServiceTests test
```

Expected: FAIL because the Review module does not exist.

- [ ] **Step 3: Implement review service orchestration**

Implement:

- preflight check
- review detail create/update
- create submission
- add items / submit
- fetch status / history
- batch progress reporting via `TaskCenter`

- [ ] **Step 4: Implement review controllers**

Implement:

- app + version selection
- notes and contact info entry
- optional demo account fields
- status pane for current review state
- batch submission progress list

- [ ] **Step 5: Add UI fixture mode for review**

Add fixture-backed UI state so the Review pane can be verified without live submission in unattended UI tests.

- [ ] **Step 6: Run tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/ReviewServiceTests -only-testing:ConnectMateUITests/ConnectMateUITests test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add ConnectMate/Modules/Review ConnectMateTests/Review/ReviewServiceTests.swift ConnectMateTests/Fixtures/review-submission.json ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: add review submission and status workflows"
```

## Task 10: Implement TestFlight Testers, Groups, Distribution, And Drag-Drop Membership

**Files:**
- Create: `ConnectMate/Modules/TestFlight/TesterSummary.swift`
- Create: `ConnectMate/Modules/TestFlight/BetaGroupSummary.swift`
- Create: `ConnectMate/Modules/TestFlight/TestFlightService.swift`
- Create: `ConnectMate/Modules/TestFlight/TesterListViewController.swift`
- Create: `ConnectMate/Modules/TestFlight/BetaGroupViewController.swift`
- Create: `ConnectMate/Modules/TestFlight/InviteTesterViewController.swift`
- Create: `ConnectMate/Modules/TestFlight/BuildDistributionViewController.swift`
- Create: `ConnectMateTests/TestFlight/TestFlightServiceTests.swift`
- Create: `ConnectMateTests/Fixtures/testflight-testers.json`
- Create: `ConnectMateTests/Fixtures/testflight-groups.json`

- [ ] **Step 1: Write the failing TestFlight service tests**

```swift
@Test
func bulkInviteSplitsEmailsAndInvokesInvitePerRecipient() async throws {
    let service = TestFlightService(runner: .capturing(), repository: .inMemory)
    try await service.inviteTesters(
        appID: "123",
        emails: "a@example.com\nb@example.com",
        groupIDs: ["GROUP_1"]
    )

    #expect(service.capturedCommands.count == 2)
}
```

```swift
@Test
func assignBuildToGroupUsesBuildAddGroupsCommand() async throws {
    let service = TestFlightService(runner: .capturing(), repository: .inMemory)
    try await service.assignBuild("BUILD_1", toGroups: ["GROUP_1"])
    #expect(service.capturedCommands.first == ["builds", "add-groups", "--build", "BUILD_1", "--group", "GROUP_1"])
}
```

- [ ] **Step 2: Run the TestFlight tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/TestFlightServiceTests test
```

Expected: FAIL because the TestFlight service and controllers do not exist.

- [ ] **Step 3: Implement TestFlight service**

Implement:

- testers list/add/invite/remove
- groups list/create/edit/delete
- add/remove testers from groups
- build distribution using `asc builds add-groups`
- cache testers and groups

- [ ] **Step 4: Implement TestFlight UI**

Implement:

- testers list with bulk invite text area
- batch delete
- group management pane
- drag-and-drop between tester list and group membership views
- build distribution panel

- [ ] **Step 5: Add fixture-backed UI tests for TestFlight**

Cover:

- navigation into TestFlight
- opening invite sheet/panel
- verifying fixture rows render for testers and groups

- [ ] **Step 6: Run tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/TestFlightServiceTests -only-testing:ConnectMateUITests/ConnectMateUITests test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add ConnectMate/Modules/TestFlight ConnectMateTests/TestFlight/TestFlightServiceTests.swift ConnectMateTests/Fixtures/testflight-testers.json ConnectMateTests/Fixtures/testflight-groups.json ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: add testflight testers groups and distribution"
```

## Task 11: Implement IAP Management, Logs, And About/Updates

**Files:**
- Create: `ConnectMate/Modules/InAppPurchase/IAPSummary.swift`
- Create: `ConnectMate/Modules/InAppPurchase/IAPService.swift`
- Create: `ConnectMate/Modules/InAppPurchase/IAPListViewController.swift`
- Create: `ConnectMate/Modules/InAppPurchase/IAPEditViewController.swift`
- Create: `ConnectMate/Modules/Logs/CommandLogViewController.swift`
- Create: `ConnectMate/Modules/About/AboutViewController.swift`
- Modify: `ConnectMate/Core/Updater/SparkleUpdater.swift`
- Create: `ConnectMateTests/InAppPurchase/IAPServiceTests.swift`
- Create: `ConnectMateTests/Fixtures/iap-list.json`

- [ ] **Step 1: Write the failing IAP and updater tests**

```swift
@Test
func iapSetupUsesExpectedAscCommand() async throws {
    let service = IAPService(runner: .capturing(), repository: .inMemory)
    try await service.createSetupDraft(.fixture)
    #expect(service.capturedCommands.first?.prefix(2) == ["iap", "setup"])
}
```

```swift
@Test
func logsRepositoryExportsPlainText() throws {
    let repository = CommandLogRepository.inMemory
    try repository.insertFixtureRows()
    let output = try repository.exportPlainText()
    #expect(output.contains("asc apps list"))
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/IAPServiceTests -only-testing:ConnectMateTests/DatabaseMigrationTests test
```

Expected: FAIL because the IAP module and export helpers do not exist yet.

- [ ] **Step 3: Implement IAP service and controllers**

Implement:

- list/view/create/setup/update/delete/submit flows
- localization and price summary presentation
- subscription group lookup fallback through `asc subscriptions` when needed

- [ ] **Step 4: Implement logs and about/updates UI**

Implement:

- logs list with export to `.txt`
- about screen with version/build/open-source acknowledgements
- check-for-updates entry backed by Sparkle
- feedback button to GitHub Issues

- [ ] **Step 5: Re-run the tests**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' -only-testing:ConnectMateTests/IAPServiceTests -only-testing:ConnectMateTests/DatabaseMigrationTests -only-testing:ConnectMateUITests/ConnectMateUITests test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ConnectMate/Modules/InAppPurchase ConnectMate/Modules/Logs ConnectMate/Modules/About ConnectMate/Core/Updater/SparkleUpdater.swift ConnectMateTests/InAppPurchase/IAPServiceTests.swift ConnectMateTests/Fixtures/iap-list.json ConnectMateUITests/ConnectMateUITests.swift
git commit -m "feat: add iap management logs and about updates"
```

## Task 12: Add Release Scripts, Run Full Verification, And Publish Version 1.0

**Files:**
- Create: `ConnectMate/Scripts/build_release.sh`
- Create: `ConnectMate/Scripts/publish_release.sh`
- Create: `ConnectMate/Scripts/generate_appcast.sh`
- Modify: `ConnectMate.xcodeproj/project.pbxproj`
- Modify: `appcast.xml`
- Modify: `ConnectMate/Resources/Info.plist`

- [ ] **Step 1: Write the failing release smoke verification**

Document and verify these commands against missing scripts first:

```bash
./ConnectMate/Scripts/build_release.sh
./ConnectMate/Scripts/publish_release.sh --dry-run
```

Expected: FAIL because the release scripts do not exist yet.

- [ ] **Step 2: Implement the build script**

Implement:

- derive version/build from `project.pbxproj`
- archive and export the signed app
- notarize using the same credentials model as HostsEditor
- call the global DMG helper

Required DMG call:

```bash
dmg_path="$(create_pretty_dmg.sh --app-path \"./ConnectMate.app\" --dmg-name \"ConnectMate\" --append-version --append-build | awk -F': ' '/^DMG_PATH: / {print $2}' | tail -n 1)"
```

- [ ] **Step 3: Implement the publish script**

Implement:

- tag and publish GitHub release with `gh`
- upload DMG asset
- reuse release notes as Sparkle inline notes
- regenerate `appcast.xml`
- print the release URL and generated DMG path

- [ ] **Step 4: Run the full automated test suite**

Run:

```bash
xcodebuild -workspace ConnectMate.xcworkspace -scheme ConnectMate -destination 'platform=macOS' test
```

Expected: PASS for unit and unattended UI tests.

- [ ] **Step 5: Run live CLI verification**

Run:

```bash
/usr/local/bin/asc auth status --validate
/usr/local/bin/asc apps list --output json --pretty
/usr/local/bin/asc builds list --app "$( /usr/local/bin/asc apps list --output json | /usr/bin/python3 -c 'import json,sys; data=json.load(sys.stdin); print(data[0]["id"])' )"
```

Expected: PASS using the configured local credentials and return real App Store Connect data.

- [ ] **Step 6: Build and notarize the release artifact**

Run:

```bash
./ConnectMate/Scripts/build_release.sh
```

Expected: PASS with a stapled, notarized DMG path printed by the script.

- [ ] **Step 7: Publish version 1.0**

Run:

```bash
git tag v1.0
git push origin main --tags
./ConnectMate/Scripts/publish_release.sh --tag v1.0
```

Expected: PASS with a GitHub Release created in `wangwanjie/ConnectMate` and `appcast.xml` updated for Sparkle.

- [ ] **Step 8: Final verification**

Run:

```bash
xcrun stapler validate "<DMG_PATH>"
gh release view v1.0 -R wangwanjie/ConnectMate
git status --short
```

Expected:

- stapler validation succeeds
- GitHub release exists
- only intended post-release changes remain, ideally a clean tree after appcast commit/push

- [ ] **Step 9: Commit**

```bash
git add ConnectMate/Scripts appcast.xml ConnectMate.xcodeproj/project.pbxproj ConnectMate/Resources/Info.plist
git commit -m "chore: add release pipeline and publish v1.0"
```

## Execution Notes

- Use TDD exactly as written: write the failing test, run it to confirm the right failure, then implement the minimum code.
- Do not bring back storyboard/XIB usage.
- Keep all new UI in AppKit + SnapKit.
- Keep `ViewScopeServer` and `LookinServer` CocoaPods integration intact.
- Do not commit the local `.p8` file.
- Prefer fixture-driven UI tests for unattended reliability.
- When live CLI verification is needed, use the configured local environment and record failures in `command_logs`.
- If Sparkle keys or notarization credentials are missing, stop and fix environment configuration before claiming release readiness.
