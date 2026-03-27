import Foundation

final class LocalizationManager {
    static let shared = LocalizationManager()
    static let languageDidChangeNotification = Notification.Name("ConnectMate.LanguageDidChange")

    private let settings: AppSettings
    private let mainBundle: Bundle

    init(settings: AppSettings? = nil, mainBundle: Bundle = .main) {
        self.settings = settings ?? .shared
        self.mainBundle = mainBundle
    }

    func localizedString(forKey key: String, table: String? = nil) -> String {
        let bundle = bundleForCurrentLanguage()
        let localized = bundle.localizedString(forKey: key, value: nil, table: table)
        if localized != key {
            return localized
        }
        for bundle in candidateBundles where bundle.bundleURL != mainBundle.bundleURL {
            let fallback = bundle.localizedString(forKey: key, value: nil, table: table)
            if fallback != key {
                return fallback
            }
        }
        return mainBundle.localizedString(forKey: key, value: nil, table: table)
    }

    func apply(language: AppLanguage) {
        settings.preferredLanguage = language
        NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: language)
    }

    private func bundleForCurrentLanguage() -> Bundle {
        switch settings.preferredLanguage {
        case .system:
            return candidateBundles.first ?? mainBundle
        case .simplifiedChinese:
            return localizedBundle(named: "zh-Hans") ?? mainBundle
        case .traditionalChinese:
            return localizedBundle(named: "zh-Hant") ?? mainBundle
        case .english:
            return localizedBundle(named: "en") ?? mainBundle
        }
    }

    private func localizedBundle(named localization: String) -> Bundle? {
        for bundle in candidateBundles {
            guard let path = bundle.path(forResource: localization, ofType: "lproj") else {
                continue
            }
            if let localizedBundle = Bundle(path: path) {
                return localizedBundle
            }
        }
        return nil
    }

    private var candidateBundles: [Bundle] {
        let bundledCandidates = [mainBundle, Bundle(for: BundleLocator.self)]
        return bundledCandidates.reduce(into: [Bundle]()) { result, bundle in
            guard !result.contains(where: { $0.bundleURL == bundle.bundleURL }) else { return }
            result.append(bundle)
        }
    }
}

private final class BundleLocator {}
