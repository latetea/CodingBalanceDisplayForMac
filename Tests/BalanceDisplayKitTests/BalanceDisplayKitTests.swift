import BalanceDisplayKit
import Foundation
import XCTest

final class BalanceDisplayKitTests: XCTestCase {
    func testQuotaExhaustedUsesStatusText() {
        let response = UsageResponse(
            daysUntilExpiry: 5,
            isValid: true,
            mode: "quota_limited",
            quota: UsageResponse.Quota(
                limit: Decimal(string: "500"),
                remaining: Decimal.zero,
                unit: "USD",
                used: Decimal(string: "510.05")
            ),
            remaining: Decimal.zero,
            status: "quota_exhausted",
            unit: "USD"
        )

        XCTAssertEqual(
            UsagePresentationBuilder.primaryDisplay(from: response, now: .distantPast),
            "已用满"
        )
    }

    func testWalletBalanceFallsBackToBalanceField() {
        let response = UsageResponse(
            balance: Decimal(string: "12.29829069"),
            isValid: true,
            mode: "unrestricted",
            planName: "钱包余额",
            unit: "USD"
        )

        XCTAssertEqual(
            UsagePresentationBuilder.primaryDisplay(from: response),
            "$12.30"
        )
    }

    func testTitleContainsAccountNameAndValue() {
        let snapshot = AccountSnapshot(
            response: UsageResponse(
                balance: Decimal(string: "8.50"),
                unit: "USD"
            ),
            lastUpdated: Date(),
            errorMessage: nil
        )

        XCTAssertEqual(
            UsagePresentationBuilder.title(accountName: "测试账户", snapshot: snapshot),
            "测试账户 $8.50"
        )
    }

    func testMenuBarDisplayUsesTodayAndBalanceWithPrefixes() {
        let response = UsageResponse(
            balance: Decimal(string: "12.29829069"),
            unit: "USD",
            usage: UsageResponse.UsageStats(
                today: UsageResponse.TokenStats(
                    actualCost: Decimal(string: "0.025892125"),
                    requests: 6
                )
            )
        )

        let display = UsagePresentationBuilder.menuBarDisplay(
            snapshot: AccountSnapshot(response: response, lastUpdated: Date(), errorMessage: nil)
        )

        XCTAssertEqual(display.topLine, "今$0.03")
        XCTAssertEqual(display.bottomLine, "余$12.30")
    }

    func testConfigurationStoreNormalizesMissingActiveAccount() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let configURL = tempDirectory.appendingPathComponent("config.json")
        let store = ConfigurationStore(fileURL: configURL)
        let account = AccountConfig(
            id: UUID(),
            displayName: "Primary",
            baseURL: "https://code.rayinai.com",
            apiKey: "sk-test"
        )

        try store.save(
            AppConfiguration(
                accounts: [account],
                activeAccountID: UUID(),
                settings: SettingsState(refreshIntervalSeconds: 60, launchAtLogin: false)
            )
        )

        let loaded = try store.load()
        XCTAssertEqual(loaded.activeAccountID, account.id)
    }
}
