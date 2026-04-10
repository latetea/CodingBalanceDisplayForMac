import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    private var accountWindowController: AccountWindowController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        accountWindowController = AccountWindowController(model: model)
        statusItemController = StatusItemController(
            model: model,
            openAccountsWindow: { [weak self] in
                self?.accountWindowController?.showManagedWindow()
            }
        )
    }
}
