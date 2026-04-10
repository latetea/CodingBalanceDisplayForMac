import AppKit
import BalanceDisplayKit
import SwiftUI

private struct AccountDraft: Equatable {
    var id: UUID?
    var displayName: String
    var baseURL: String
    var apiKey: String

    init(account: AccountConfig? = nil) {
        id = account?.id
        displayName = account?.displayName ?? ""
        baseURL = account?.baseURL ?? ""
        apiKey = account?.apiKey ?? ""
    }

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func makeAccount() -> AccountConfig {
        AccountConfig(
            id: id ?? UUID(),
            displayName: displayName,
            baseURL: baseURL,
            apiKey: apiKey
        )
    }
}

private struct AccountEditorContext: Identifiable {
    let id = UUID()
    let title: String
    let draft: AccountDraft
}

struct AccountManagementView: View {
    @ObservedObject var model: AppModel

    @State private var selectedAccountID: UUID?
    @State private var editorContext: AccountEditorContext?

    private var selectedAccount: AccountConfig? {
        guard let selectedAccountID else {
            return model.currentAccount
        }

        return model.accounts.first(where: { $0.id == selectedAccountID })
    }

    private var selectedSnapshot: AccountSnapshot? {
        guard let selectedAccount else {
            return nil
        }

        return model.snapshots[selectedAccount.id]
    }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 12) {
                List(selection: $selectedAccountID) {
                    ForEach(model.accounts) { account in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.displayName)
                                Text(account.baseURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if account.id == model.currentAccount?.id {
                                Text("当前")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(account.id)
                    }
                }

                HStack {
                    Button("添加") {
                        editorContext = AccountEditorContext(title: "添加账户", draft: AccountDraft())
                    }

                    Button("编辑") {
                        guard let selectedAccount else {
                            return
                        }

                        editorContext = AccountEditorContext(
                            title: "编辑账户",
                            draft: AccountDraft(account: selectedAccount)
                        )
                    }
                    .disabled(selectedAccount == nil)

                    Button("删除") {
                        guard let selectedAccountID else {
                            return
                        }

                        model.deleteAccount(selectedAccountID)
                        self.selectedAccountID = model.currentAccount?.id
                    }
                    .disabled(selectedAccount == nil)
                }
            }
            .frame(minWidth: 280)
            .padding()

            VStack(alignment: .leading, spacing: 16) {
                if let selectedAccount {
                    detailCard(for: selectedAccount, snapshot: selectedSnapshot)

                    HStack {
                        Button("设为当前账户") {
                            model.setActiveAccount(selectedAccount.id)
                        }
                        .disabled(selectedAccount.id == model.currentAccount?.id)

                        Button("立即刷新") {
                            model.setActiveAccount(selectedAccount.id)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)

                        Text("暂无账户")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("添加一个账户后，应用会开始请求余额接口。")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

                Spacer()
            }
            .frame(minWidth: 360)
            .padding()
        }
        .sheet(item: $editorContext) { context in
            AccountEditorView(title: context.title, draft: context.draft) { draft in
                let account = draft.makeAccount()

                if context.draft.id == nil {
                    model.addAccount(account)
                } else {
                    model.updateAccount(account)
                }

                selectedAccountID = account.id
            }
            .frame(width: 420)
        }
        .onAppear {
            selectedAccountID = model.currentAccount?.id
        }
        .onChange(of: model.accounts) { _ in
            if let selectedAccountID,
               model.accounts.contains(where: { $0.id == selectedAccountID }) {
                return
            }

            self.selectedAccountID = model.currentAccount?.id
        }
    }

    @ViewBuilder
    private func detailCard(for account: AccountConfig, snapshot: AccountSnapshot?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(account.displayName)
                .font(.title2)
                .fontWeight(.semibold)

            Text(account.baseURL)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if let snapshot, let response = snapshot.response {
                let presentation = UsagePresentationBuilder.makePresentation(response: response, snapshot: snapshot)

                Text("状态：\(presentation.primaryDisplay)")
                    .font(.headline)

                ForEach(
                    [
                        presentation.subtitle,
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
                }
            } else if let errorMessage = snapshot?.errorMessage {
                Text("最近一次刷新失败：\(errorMessage)")
                    .foregroundStyle(.red)
            } else {
                Text("尚未拉取数据")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AccountEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (AccountDraft) -> Void

    @State private var draft: AccountDraft

    init(
        title: String,
        draft: AccountDraft,
        onSave: @escaping (AccountDraft) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Form {
                TextField("账户名称", text: $draft.displayName)
                TextField("Base URL", text: $draft.baseURL, prompt: Text("https://code.xxxx.com"))
                SecureField("API Key", text: $draft.apiKey, prompt: Text("sk-..."))
            }
            .formStyle(.grouped)

            HStack {
                Spacer()

                Button("取消") {
                    dismiss()
                }

                Button("保存") {
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!draft.isValid)
            }
        }
        .padding(20)
    }
}
