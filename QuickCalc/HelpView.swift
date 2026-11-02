import AppKit
import QuickCalcCore

/// Everything the calculator understands, by section. Clicking an example tries it.
final class HelpView: NSScrollView {
    /// The engine's sections, translated: their English text doubles as the localization key.
    private static var calculatorSections: [HelpSection] {
        Help.sections(for: .current).map { section in
            HelpSection(title: localized(section.title), items: section.items.map { item in
                item.kind == .list
                    ? HelpItem(kind: .list, label: localized(item.label), detail: item.detail)
                    : HelpItem(kind: item.kind, label: item.label, detail: localized(item.detail))
            })
        }
    }

    private static var keys: HelpSection {
        HelpSection(title: String(localized: "Keys"), items: [
            HelpItem(kind: .shortcut, label: HotKey.label, detail: String(localized: "opens QuickCalc from any app")),
            HelpItem(kind: .shortcut, label: String(localized: "Return"), detail: String(localized: "copies the result and saves it")),
            HelpItem(kind: .shortcut, label: "⌘C", detail: String(localized: "copies without clearing the field")),
            HelpItem(kind: .shortcut, label: "↑ ↓", detail: String(localized: "recalls previous calculations")),
            HelpItem(kind: .shortcut, label: "Esc", detail: String(localized: "closes the help, then the panel")),
            HelpItem(kind: .shortcut, label: "?", detail: String(localized: "opens this help")),
        ])
    }

    private static var about: HelpSection {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        return HelpSection(title: String(localized: "About"), items: [
            HelpItem(kind: .info, label: "QuickCalc", detail: String(localized: "Version \(version)")),
            HelpItem(kind: .info, label: String(localized: "Author"), detail: "© 2026 Alessandro Lioce"),
            HelpItem(kind: .info, label: String(localized: "License"), detail: "GNU GPL v3"),
            HelpItem(kind: .info, label: String(localized: "Exchange rates"), detail: String(localized: "European Central Bank")),
            HelpItem(kind: .info, label: String(localized: "Icons"), detail: String(localized: "Apple SF Symbols")),
        ])
    }

    /// Panel width minus margins, leaving room for the overlay scroller on the right.
    private static let rowWidth: CGFloat = 320

    init(onPick: @escaping (String) -> Void) {
        super.init(frame: .zero)
        drawsBackground = false
        hasVerticalScroller = true
        autohidesScrollers = true
        borderType = .noBorder

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 16, bottom: 14, right: 24)

        for section in Self.calculatorSections + [Self.keys, Self.about] {
            let header = Self.label(section.title.uppercased(), font: .systemFont(ofSize: 10, weight: .semibold), color: .tertiaryLabelColor)
            stack.addArrangedSubview(header)
            stack.setCustomSpacing(4, after: header)
            for item in section.items {
                let row = Self.row(for: item, onPick: onPick)
                row.widthAnchor.constraint(equalToConstant: Self.rowWidth).isActive = true
                stack.addArrangedSubview(row)
            }
            stack.setCustomSpacing(14, after: stack.arrangedSubviews.last!)
        }

        // Laid out once: the content never changes while the app runs.
        stack.frame = NSRect(origin: .zero, size: stack.fittingSize)
        let document = FlippedView(frame: stack.frame)
        document.addSubview(stack)
        documentView = document
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private static func row(for item: HelpItem, onPick: @escaping (String) -> Void) -> NSView {
        switch item.kind {
        case .example:
            let row = HelpRow(
                label: label(item.label, font: .monospacedSystemFont(ofSize: 12.5, weight: .regular), color: .controlAccentColor),
                detail: label(item.detail, font: .systemFont(ofSize: 11.5), color: .secondaryLabelColor)
            )
            row.onClick = { onPick(item.label) }
            row.toolTip = String(localized: "Click to try it")
            return row
        case .shortcut:
            return HelpRow(
                label: label(item.label, font: .monospacedSystemFont(ofSize: 12.5, weight: .semibold), color: .labelColor),
                detail: label(item.detail, font: .systemFont(ofSize: 11.5), color: .secondaryLabelColor)
            )
        case .info:
            return HelpRow(
                label: label(item.label, font: .systemFont(ofSize: 11.5), color: .secondaryLabelColor),
                detail: label(item.detail, font: .systemFont(ofSize: 11.5), color: .labelColor)
            )
        case .list:
            let title = label(item.label, font: .systemFont(ofSize: 11, weight: .medium), color: .secondaryLabelColor)
            let names = NSTextField(wrappingLabelWithString: item.detail)
            names.font = .monospacedSystemFont(ofSize: 11.5, weight: .regular)
            names.textColor = .labelColor
            names.preferredMaxLayoutWidth = rowWidth
            let stack = NSStackView(views: [title, names])
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 1
            stack.edgeInsets = NSEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
            return stack
        }
    }

    private static func label(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        return label
    }
}

/// Label on the left, description on the right, optionally clickable.
private final class HelpRow: NSView {
    var onClick: (() -> Void)? {
        didSet { addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(clicked))) }
    }

    init(label: NSTextField, detail: NSTextField) {
        super.init(frame: .zero)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        detail.lineBreakMode = .byTruncatingTail
        detail.alignment = .right
        detail.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for subview in [label, detail] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            detail.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 12),
            detail.trailingAnchor.constraint(equalTo: trailingAnchor),
            detail.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func clicked() {
        onClick?()
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
