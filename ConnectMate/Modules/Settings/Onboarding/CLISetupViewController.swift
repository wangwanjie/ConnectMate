import Cocoa
import SnapKit

enum CLISetupMode {
    case missingCLI
    case missingCredentials
}

struct CLISetupState {
    let mode: CLISetupMode
    let cliPath: String
    let cliVersion: String?
    let message: String
}

final class CLISetupViewController: NSViewController {
    private let state: CLISetupState

    init(state: CLISetupState) {
        self.state = state
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

        let titleLabel = NSTextField(labelWithString: L10n.Onboarding.title)
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)

        let messageLabel = NSTextField(wrappingLabelWithString: state.message)
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.maximumNumberOfLines = 3
        messageLabel.alignment = .center

        let cliPathLabel = NSTextField(labelWithString: "\(L10n.Onboarding.cliPath): \(state.cliPath)")
        cliPathLabel.textColor = .secondaryLabelColor

        let versionValue = state.cliVersion?.isEmpty == false ? state.cliVersion! : L10n.Onboarding.noVersion
        let cliVersionLabel = NSTextField(labelWithString: "\(L10n.Onboarding.cliVersion): \(versionValue)")
        cliVersionLabel.textColor = .secondaryLabelColor

        let preferencesButton = NSButton(title: L10n.Onboarding.openPreferences, target: self, action: #selector(openPreferences))
        let apiKeyButton = NSButton(title: L10n.Onboarding.configureAPIKey, target: self, action: #selector(openAPIKeys))
        apiKeyButton.isHidden = state.mode == .missingCLI

        let buttons = NSStackView(views: [preferencesButton, apiKeyButton])
        buttons.orientation = .horizontal
        buttons.spacing = 12

        let stack = NSStackView(views: [titleLabel, messageLabel, cliPathLabel, cliVersionLabel, buttons])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }

    @objc
    private func openPreferences() {
        SettingsWindowController.shared.present()
    }

    @objc
    private func openAPIKeys() {
        APIKeyViewController.presentAsSheet(from: view.window)
    }
}
