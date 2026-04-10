import BalanceDisplayKit
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var configuration: AppConfiguration
    @Published private(set) var snapshots: [UUID: AccountSnapshot]
    @Published private(set) var isRefreshing = false
    @Published var transientMessage: String?

    private let configurationStore: ConfigurationStore
    private let apiClient: UsageAPIClientProtocol
    private let launchAtLoginService: LaunchAtLoginControlling

    private var refreshTask: Task<Void, Never>?
    private var refreshTimer: Timer?

    init(
        configurationStore: ConfigurationStore = ConfigurationStore(),
        apiClient: UsageAPIClientProtocol = UsageAPIClient(),
        launchAtLoginService: LaunchAtLoginControlling = LaunchAtLoginService()
    ) {
        self.configurationStore = configurationStore
        self.apiClient = apiClient
        self.launchAtLoginService = launchAtLoginService

        do {
            var loadedConfiguration = try configurationStore.load()
            loadedConfiguration.settings.launchAtLogin = launchAtLoginService.isEnabled
            self.configuration = loadedConfiguration
        } catch {
            self.configuration = AppConfiguration()
            self.transientMessage = "配置读取失败：\(error.localizedDescription)"
        }

        self.snapshots = [:]
        reconfigureAutoRefreshTimer()
        refreshCurrentAccount()
    }

    deinit {
        refreshTimer?.invalidate()
        refreshTask?.cancel()
    }

    var accounts: [AccountConfig] {
        configuration.accounts
    }

    var currentAccount: AccountConfig? {
        configuration.activeAccount
    }

    var currentSnapshot: AccountSnapshot? {
        guard let account = currentAccount else {
            return nil
        }

        return snapshots[account.id]
    }

    var currentPresentation: UsagePresentation? {
        guard let snapshot = currentSnapshot, let response = snapshot.response else {
            return nil
        }

        return UsagePresentationBuilder.makePresentation(response: response, snapshot: snapshot)
    }

    var menuBarDisplay: MenuBarDisplay {
        UsagePresentationBuilder.menuBarDisplay(snapshot: currentSnapshot)
    }

    var launchAtLoginEnabled: Bool {
        configuration.settings.launchAtLogin
    }

    func refreshCurrentAccount() {
        guard let account = currentAccount else {
            isRefreshing = false
            return
        }

        refreshTask?.cancel()
        isRefreshing = true

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            defer {
                self.isRefreshing = false
                self.refreshTask = nil
            }

            do {
                let response = try await self.apiClient.fetchUsage(for: account)
                guard !Task.isCancelled else {
                    return
                }

                self.snapshots[account.id] = AccountSnapshot(
                    response: response,
                    lastUpdated: Date(),
                    errorMessage: nil
                )
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                let existing = self.snapshots[account.id] ?? AccountSnapshot()
                self.snapshots[account.id] = AccountSnapshot(
                    response: existing.response,
                    lastUpdated: existing.lastUpdated,
                    errorMessage: error.localizedDescription
                )
            }
        }
    }

    func setActiveAccount(_ accountID: UUID) {
        guard configuration.activeAccountID != accountID else {
            refreshCurrentAccount()
            return
        }

        configuration.activeAccountID = accountID
        persistConfiguration()
        refreshCurrentAccount()
    }

    func addAccount(_ account: AccountConfig) {
        configuration.accounts.append(account)
        configuration.normalizeActiveAccount()
        configuration.activeAccountID = account.id
        persistConfiguration()
        refreshCurrentAccount()
    }

    func updateAccount(_ account: AccountConfig) {
        guard let index = configuration.accounts.firstIndex(where: { $0.id == account.id }) else {
            return
        }

        configuration.accounts[index] = account
        configuration.normalizeActiveAccount()
        persistConfiguration()

        if configuration.activeAccountID == account.id {
            refreshCurrentAccount()
        }
    }

    func deleteAccount(_ accountID: UUID) {
        configuration.accounts.removeAll(where: { $0.id == accountID })
        snapshots.removeValue(forKey: accountID)
        configuration.normalizeActiveAccount()
        persistConfiguration()
        refreshCurrentAccount()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(enabled)
            configuration.settings.launchAtLogin = enabled
            persistConfiguration()
        } catch {
            transientMessage = error.localizedDescription
        }
    }

    private func persistConfiguration() {
        do {
            try configurationStore.save(configuration)
        } catch {
            transientMessage = "配置保存失败：\(error.localizedDescription)"
        }
    }

    private func reconfigureAutoRefreshTimer() {
        refreshTimer?.invalidate()

        let interval = max(configuration.settings.refreshIntervalSeconds, 15)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCurrentAccount()
            }
        }
    }
}
