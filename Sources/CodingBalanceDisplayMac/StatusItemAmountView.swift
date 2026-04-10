import AppKit
import BalanceDisplayKit

final class StatusItemAmountView: NSView {
    private let topLabel = StatusItemAmountView.makeLabel()
    private let bottomLabel = StatusItemAmountView.makeLabel()
    private let lineSpacing: CGFloat = -2

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    convenience init(display: MenuBarDisplay) {
        self.init(frame: .zero)
        update(display: display)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        let topSize = topLabel.fittingSize
        let bottomSize = bottomLabel.fittingSize
        let width = ceil(max(topSize.width, bottomSize.width))
        let height = ceil(topSize.height + bottomSize.height + lineSpacing)
        return NSSize(width: width, height: height)
    }

    override func layout() {
        super.layout()

        let topSize = topLabel.fittingSize
        let bottomSize = bottomLabel.fittingSize
        let contentHeight = topSize.height + bottomSize.height + lineSpacing
        let originY = floor((bounds.height - contentHeight) / 2)

        bottomLabel.frame = NSRect(
            x: 0,
            y: originY,
            width: bounds.width,
            height: bottomSize.height
        )

        topLabel.frame = NSRect(
            x: 0,
            y: originY + bottomSize.height + lineSpacing,
            width: bounds.width,
            height: topSize.height
        )
    }

    func update(display: MenuBarDisplay) {
        topLabel.stringValue = display.topLine
        bottomLabel.stringValue = display.bottomLine
        invalidateIntrinsicContentSize()
        needsLayout = true
    }

    private func configure() {
        addSubview(topLabel)
        addSubview(bottomLabel)
    }

    private static func makeLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "--")
        label.font = .monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        label.alignment = .right
        label.lineBreakMode = .byClipping
        label.maximumNumberOfLines = 1
        label.textColor = .labelColor
        label.isSelectable = false
        return label
    }
}
