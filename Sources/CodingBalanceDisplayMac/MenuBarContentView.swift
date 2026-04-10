import AppKit
import BalanceDisplayKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    let openAccountsWindow: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let account = model.currentAccount {
                    accountSection(account)
                    Divider()
                    actionsSection
                } else {
                    emptySection
                }

                Divider()

                HStack {
                    Spacer()

                    Button("退出") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(14)
            .frame(width: 320, alignment: .leading)
        }
    }

    @ViewBuilder
    private func accountSection(_ account: AccountConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(account.displayName)
                .font(.headline)

            if let presentation = model.currentPresentation {
                detailsView(presentation: presentation)
            } else if let snapshot = model.currentSnapshot, let errorMessage = snapshot.errorMessage {
                Text("最近一次刷新失败：\(errorMessage)")
                    .foregroundStyle(.red)
            } else {
                Text("尚未拉取余额数据")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button(model.isRefreshing ? "刷新中…" : "立即刷新") {
                    model.refreshCurrentAccount()
                }
                .disabled(model.isRefreshing)

                Button("账户管理…") {
                    openAccountsWindow()
                }
            }

            if model.accounts.count > 1 {
                Picker(
                    "当前账户",
                    selection: Binding(
                        get: { model.currentAccount?.id ?? UUID() },
                        set: { model.setActiveAccount($0) }
                    )
                ) {
                    ForEach(model.accounts) { item in
                        Text(item.displayName).tag(item.id)
                    }
                }
                .pickerStyle(.menu)
            }

            Toggle(
                "开机自启动",
                isOn: Binding(
                    get: { model.launchAtLoginEnabled },
                    set: { model.setLaunchAtLogin($0) }
                )
            )

            if let transientMessage = model.transientMessage {
                Text(transientMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var emptySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("未配置账户")
                .font(.headline)

            Text("先添加一个账户以开始拉取余额。")
                .foregroundStyle(.secondary)

            Button("添加账户…") {
                openAccountsWindow()
            }

            Toggle(
                "开机自启动",
                isOn: Binding(
                    get: { model.launchAtLoginEnabled },
                    set: { model.setLaunchAtLogin($0) }
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func detailsView(presentation: UsagePresentation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.primaryDisplay)
                .font(.title3)
                .fontWeight(.semibold)

            Text(presentation.subtitle)
                .foregroundStyle(.secondary)

            ForEach(
                [
                    presentation.statusLine,
                    presentation.balanceLine,
                    presentation.quotaLine,
                    presentation.expiryLine,
                    presentation.todayLine,
                    presentation.totalLine,
                    presentation.updatedAtLine,
                    presentation.errorLine
                ].compactMap { $0 },
                id: \.self
            ) { line in
                Text(line)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
