import Testing
@testable import ConnectMate

struct SigningCLIOptionsTests {
    @Test
    func certificateTypesIncludeAppleSupportedVariants() {
        #expect(SigningCLIOptions.certificateTypes.contains("DEVELOPER_ID_APPLICATION"))
        #expect(SigningCLIOptions.certificateTypes.contains("MAC_INSTALLER_DISTRIBUTION"))
        #expect(SigningCLIOptions.certificateTypes.contains("PASS_TYPE_ID_WITH_NFC"))
    }

    @Test
    func profileTypesIncludeCatalystAndDirectVariants() {
        #expect(SigningCLIOptions.profileTypes.contains("MAC_CATALYST_APP_DEVELOPMENT"))
        #expect(SigningCLIOptions.profileTypes.contains("MAC_CATALYST_APP_STORE"))
        #expect(SigningCLIOptions.profileTypes.contains("MAC_APP_DIRECT"))
    }

    @Test
    func capabilityTypesAndTemplatesCoverCommonConfigurationNeeds() {
        #expect(SigningCLIOptions.capabilityTypes.contains("ICLOUD"))
        #expect(SigningCLIOptions.capabilityTypes.contains("APPLE_ID_AUTH"))
        #expect(SigningCLIOptions.capabilityTypes.contains("APP_GROUPS"))
        #expect(SigningCLIOptions.settingsTemplate(for: "ICLOUD")?.contains("ICLOUD_VERSION") == true)
        #expect(SigningCLIOptions.settingsTemplate(for: "DATA_PROTECTION")?.contains("DATA_PROTECTION_PERMISSION_LEVEL") == true)
        #expect(SigningCLIOptions.settingsTemplate(for: "IN_APP_PURCHASE") == nil)
    }
}
