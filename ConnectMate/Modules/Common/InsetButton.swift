import AppKit

final class InsetButton: NSButton {
    private let insetCell: InsetButtonCell

    init(title: String, target: AnyObject?, action: Selector?, contentInsets: NSEdgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)) {
        self.insetCell = InsetButtonCell(textCell: title)
        self.insetCell.contentInsets = contentInsets
        super.init(frame: .zero)
        cell = insetCell
        self.title = title
        self.target = target
        self.action = action
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class InsetButtonCell: NSButtonCell {
    var contentInsets = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        super.titleRect(forBounds: rect).insetted(by: contentInsets)
    }

    override func imageRect(forBounds rect: NSRect) -> NSRect {
        var imageRect = super.imageRect(forBounds: rect)
        imageRect.origin.x += contentInsets.left
        return imageRect
    }
}

private extension NSRect {
    func insetted(by insets: NSEdgeInsets) -> NSRect {
        NSRect(
            x: origin.x + insets.left,
            y: origin.y + insets.bottom,
            width: max(0, size.width - insets.left - insets.right),
            height: max(0, size.height - insets.top - insets.bottom)
        )
    }
}
