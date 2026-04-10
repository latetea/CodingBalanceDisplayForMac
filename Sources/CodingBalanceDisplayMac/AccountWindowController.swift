import AppKit
import SwiftUI

@MainActor
final class AccountWindowController: NSWindowController {
    init(model: AppModel) {
        let hostingController = NSHostingController(rootView: AccountManagementView(model: model))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "账户管理"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 760, height: 500))
        window.minSize = NSSize(width: 680, height: 440)
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showManagedWindow() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
