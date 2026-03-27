import Foundation

enum SigningCLIOptions {
    static let certificateTypes = [
        "APPLE_PAY",
        "APPLE_PAY_MERCHANT_IDENTITY",
        "APPLE_PAY_PSP_IDENTITY",
        "APPLE_PAY_RSA",
        "DEVELOPER_ID_KEXT",
        "DEVELOPER_ID_KEXT_G2",
        "DEVELOPER_ID_APPLICATION",
        "DEVELOPER_ID_APPLICATION_G2",
        "DEVELOPMENT",
        "DISTRIBUTION",
        "IDENTITY_ACCESS",
        "IOS_DEVELOPMENT",
        "IOS_DISTRIBUTION",
        "MAC_APP_DISTRIBUTION",
        "MAC_INSTALLER_DISTRIBUTION",
        "MAC_APP_DEVELOPMENT",
        "PASS_TYPE_ID",
        "PASS_TYPE_ID_WITH_NFC"
    ]

    static let profileTypes = [
        "IOS_APP_DEVELOPMENT",
        "IOS_APP_STORE",
        "IOS_APP_ADHOC",
        "IOS_APP_INHOUSE",
        "MAC_APP_DEVELOPMENT",
        "MAC_APP_STORE",
        "MAC_APP_DIRECT",
        "TVOS_APP_DEVELOPMENT",
        "TVOS_APP_STORE",
        "TVOS_APP_ADHOC",
        "TVOS_APP_INHOUSE",
        "MAC_CATALYST_APP_DEVELOPMENT",
        "MAC_CATALYST_APP_STORE",
        "MAC_CATALYST_APP_DIRECT"
    ]

    static let capabilityTypes = [
        "ICLOUD",
        "IN_APP_PURCHASE",
        "GAME_CENTER",
        "PUSH_NOTIFICATIONS",
        "WALLET",
        "INTER_APP_AUDIO",
        "MAPS",
        "ASSOCIATED_DOMAINS",
        "PERSONAL_VPN",
        "APP_GROUPS",
        "HEALTHKIT",
        "HOMEKIT",
        "WIRELESS_ACCESSORY_CONFIGURATION",
        "APPLE_PAY",
        "DATA_PROTECTION",
        "SIRIKIT",
        "NETWORK_EXTENSIONS",
        "MULTIPATH",
        "HOT_SPOT",
        "NFC_TAG_READING",
        "CLASSKIT",
        "AUTOFILL_CREDENTIAL_PROVIDER",
        "ACCESS_WIFI_INFORMATION",
        "NETWORK_CUSTOM_PROTOCOL",
        "COREMEDIA_HLS_LOW_LATENCY",
        "SYSTEM_EXTENSION_INSTALL",
        "USER_MANAGEMENT",
        "APPLE_ID_AUTH"
    ]

    static func settingsTemplate(for capabilityType: String) -> String? {
        switch capabilityType {
        case "ICLOUD":
            return """
            [{"key":"ICLOUD_VERSION","options":[{"key":"XCODE_13","enabled":true}]}]
            """
        case "DATA_PROTECTION":
            return """
            [{"key":"DATA_PROTECTION_PERMISSION_LEVEL","options":[{"key":"COMPLETE_PROTECTION","enabled":true}]}]
            """
        case "APPLE_PAY":
            return """
            [{"key":"MERCHANT_IDS","options":[{"key":"merchant.com.example.connectmate","enabled":true}]}]
            """
        default:
            return nil
        }
    }
}
