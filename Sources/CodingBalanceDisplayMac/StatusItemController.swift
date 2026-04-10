import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let openAccountsWindow: () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let buttonLabelView: StatusItemAmountView
    private var cancellables = Set<AnyCancellable>()

    init(
        model: AppModel,
        openAccountsWindow: @escaping () -> Void
    ) {
        self.model = model
        self.openAccountsWindow = openAccountsWindow
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.buttonLabelView = StatusItemAmountView(display: model.menuBarDisplay)
        super.init()
        configureStatusItem()
        configurePopover()
        bindModel()
        updateButtonDisplay()
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        guard let button = statusItem.button else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.becomeKey()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp])
        button.imagePosition = .imageOnly

        buttonLabelView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(buttonLabelView)
        buttonLabelView.setContentCompressionResistancePriority(.required, for: .horizontal)
        buttonLabelView.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            buttonLabelView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            buttonLabelView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4),
            buttonLabelView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            buttonLabelView.heightAnchor.constraint(lessThanOrEqualTo: button.heightAnchor)
        ])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 320, height: 320)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(
                model: model,
                openAccountsWindow: { [weak self] in
                    self?.popover.performClose(nil)
                    self?.openAccountsWindow()
                }
            )
        )
    }

    private func bindModel() {
        model.$configuration
            .combineLatest(model.$snapshots)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.updateButtonDisplay()
            }
            .store(in: &cancellables)
    }

    private func updateButtonDisplay() {
        let display = model.menuBarDisplay
        buttonLabelView.update(display: display)

        let fittingWidth = max(buttonLabelView.fittingSize.width, 28)
        statusItem.length = fittingWidth + 6
    }
}
