import AppKit
import QuickCalcCore

@MainActor
final class CalcViewController: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?
    var onResize: (() -> Void)?

    private static let width: CGFloat = 360
    private static let rowHeight: CGFloat = 26
    private static let visibleRows = 6
    private static let helpHeight: CGFloat = 320

    private let history: History
    private let rates: ExchangeRates
    private let input = NSTextField()
    private let helpButton = NSButton()
    private let result = NSTextField(labelWithString: "")
    private let copyButton = NSButton()
    private let separator = NSBox()
    private let scrollView = NSScrollView()
    private let table = NSTableView()
    /// Built the first time the guide is opened.
    private var helpView: HelpView?
    private var historyHeight: NSLayoutConstraint!
    private var bottomWithHistory: NSLayoutConstraint!
    private var bottomWithHelp: NSLayoutConstraint?
    private var bottomWithoutHistory: NSLayoutConstraint!

    private var isShowingHelp = false {
        didSet {
            guard isShowingHelp != oldValue else { return }
            helpButton.image = Self.helpImage(filled: isShowingHelp)
            updateLowerArea()
            onResize?()
        }
    }

    private var current: CalcResult? {
        didSet { copyButton.isHidden = current == nil }
    }
    /// Position in the history while browsing with ↑/↓; nil when editing a new expression.
    private var browsingIndex: Int?
    private var draft = ""

    init(history: History, rates: ExchangeRates) {
        self.history = history
        self.rates = rates
        super.init(nibName: nil, bundle: nil)
        history.onChange = { [weak self] in self?.reloadHistory() }
        // Fresh rates arriving while a conversion is on screen.
        rates.onUpdate = { [weak self] in
            guard let self, !input.stringValue.isEmpty else { return }
            evaluate()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let background = NSVisualEffectView()
        background.material = .popover
        background.state = .active
        background.blendingMode = .behindWindow
        background.maskImage = Self.roundedMask(radius: 12)

        input.isBordered = false
        input.drawsBackground = false
        input.focusRingType = .none
        input.font = .monospacedSystemFont(ofSize: 18, weight: .regular)
        input.cell?.wraps = false
        input.cell?.isScrollable = true
        input.delegate = self

        helpButton.image = Self.helpImage(filled: false)
        helpButton.symbolConfiguration = .init(pointSize: 15, weight: .regular)
        helpButton.isBordered = false
        helpButton.imagePosition = .imageOnly
        helpButton.contentTintColor = .tertiaryLabelColor
        helpButton.target = self
        helpButton.action = #selector(helpClicked)

        result.font = .monospacedDigitSystemFont(ofSize: 20, weight: .medium)
        result.lineBreakMode = .byTruncatingTail
        result.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(copyClicked)))

        copyButton.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: String(localized: "Copy result"))
        copyButton.symbolConfiguration = .init(pointSize: 14, weight: .regular)
        copyButton.isBordered = false
        copyButton.imagePosition = .imageOnly
        copyButton.contentTintColor = .secondaryLabelColor
        copyButton.target = self
        copyButton.action = #selector(copyClicked)
        copyButton.isHidden = true

        separator.boxType = .separator

        let column = NSTableColumn(identifier: .init("entry"))
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .plain
        table.backgroundColor = .clear
        table.rowHeight = Self.rowHeight
        table.intercellSpacing = .zero
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.focusRingType = .none
        table.refusesFirstResponder = true
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(copyClickedRow)

        scrollView.documentView = table
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        for subview in [input, helpButton, result, copyButton, separator, scrollView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            background.addSubview(subview)
        }

        historyHeight = scrollView.heightAnchor.constraint(equalToConstant: 0)
        bottomWithHistory = scrollView.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -6)
        bottomWithoutHistory = result.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -14)

        NSLayoutConstraint.activate([
            background.widthAnchor.constraint(equalToConstant: Self.width),

            input.topAnchor.constraint(equalTo: background.topAnchor, constant: 14),
            input.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 16),
            input.trailingAnchor.constraint(equalTo: helpButton.leadingAnchor, constant: -8),

            helpButton.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -16),
            helpButton.centerYAnchor.constraint(equalTo: input.centerYAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 24),
            helpButton.heightAnchor.constraint(equalToConstant: 24),

            result.topAnchor.constraint(equalTo: input.bottomAnchor, constant: 6),
            result.leadingAnchor.constraint(equalTo: input.leadingAnchor),
            result.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),
            result.heightAnchor.constraint(equalToConstant: 26),

            copyButton.trailingAnchor.constraint(equalTo: helpButton.trailingAnchor),
            copyButton.centerYAnchor.constraint(equalTo: result.centerYAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 24),
            copyButton.heightAnchor.constraint(equalToConstant: 24),

            separator.topAnchor.constraint(equalTo: result.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: background.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            historyHeight,
        ])

        input.placeholderString = localized("e.g. 200+10% · 5 km in mi")
        helpButton.toolTip = String(localized: "Help (?)")
        copyButton.toolTip = String(localized: "Copy result (⌘C)")

        view = background
        updateLowerArea()
    }

    // MARK: - Showing

    func prepareForShow(showingHelp: Bool = false) {
        rates.refreshIfNeeded()
        isShowingHelp = showingHelp
        browsingIndex = nil
        if input.stringValue.isEmpty {
            showNothing()
        } else {
            evaluate()
        }
    }

    func focusInput() {
        view.window?.makeFirstResponder(input)
        input.currentEditor()?.selectAll(nil)
    }

    // MARK: - Evaluation

    func controlTextDidChange(_ notification: Notification) {
        browsingIndex = nil
        if input.stringValue == "?" {
            setInput("")
            isShowingHelp = true
            return
        }
        evaluate()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)): commit()
        case #selector(NSResponder.cancelOperation(_:)), #selector(NSTextView.complete(_:)):
            if isShowingHelp { isShowingHelp = false } else { onClose?() }
        case #selector(NSResponder.moveUp(_:)): browse(by: 1)
        case #selector(NSResponder.moveDown(_:)): browse(by: -1)
        default: return false
        }
        return true
    }

    private func evaluate() {
        do {
            let value = try Calculator.evaluate(
                input.stringValue, ans: history.lastValue, rates: rates.current, decimalMark: .current
            )
            current = value
            showValue(value.display, note: value.ratesDate.flatMap(Self.ratesNote))
        } catch {
            current = nil
            showMessage(error.message)
        }
    }

    /// Enter: copy the result, remember it, start over.
    private func commit() {
        guard let current else { return }
        copyToPasteboard(current.clipboard)
        history.add(HistoryEntry(
            expression: input.stringValue.trimmingCharacters(in: .whitespaces),
            display: current.display,
            clipboard: current.clipboard,
            value: current.value
        ))
        input.stringValue = ""
        browsingIndex = nil
        self.current = nil
        showCopied(current.display)
    }

    /// Copies the current result while keeping the expression. Returns false when there is nothing to copy.
    @discardableResult
    func copyResult() -> Bool {
        guard let current else { return false }
        copyToPasteboard(current.clipboard)
        showCopied(current.display)
        copyButton.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: String(localized: "Copied"))
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            self?.copyButton.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: String(localized: "Copy result"))
        }
        return true
    }

    @objc private func copyClicked() {
        copyResult()
    }

    // MARK: - Help

    func setHelpVisible(_ visible: Bool) {
        isShowingHelp = visible
    }

    @objc private func helpClicked() {
        isShowingHelp.toggle()
        view.window?.makeFirstResponder(input)
        input.currentEditor()?.selectedRange = NSRange(location: (input.stringValue as NSString).length, length: 0)
    }

    /// An example clicked in the guide: try it, leaving the guide open.
    private func tryExample(_ example: String) {
        view.window?.makeFirstResponder(input)
        browsingIndex = nil
        setInput(example)
    }

    private func installHelpView() -> HelpView {
        if let helpView { return helpView }
        let help = HelpView { [weak self] example in self?.tryExample(example) }
        help.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(help)
        let bottom = help.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        NSLayoutConstraint.activate([
            help.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 4),
            help.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            help.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            help.heightAnchor.constraint(equalToConstant: Self.helpHeight),
        ])
        helpView = help
        bottomWithHelp = bottom
        return help
    }

    private static func helpImage(filled: Bool) -> NSImage? {
        NSImage(systemSymbolName: filled ? "questionmark.circle.fill" : "questionmark.circle", accessibilityDescription: String(localized: "Help"))
    }

    /// ↑ goes back in the history, ↓ forward, past the newest entry back to the draft.
    private func browse(by step: Int) {
        let entries = history.entries
        guard !entries.isEmpty else { return }
        if browsingIndex == nil { draft = input.stringValue }
        let next = (browsingIndex ?? -1) + step
        guard next < entries.count else { return }

        if next < 0 {
            browsingIndex = nil
            setInput(draft)
            table.deselectAll(nil)
        } else {
            browsingIndex = next
            setInput(entries[next].expression)
            table.selectRowIndexes([next], byExtendingSelection: false)
            table.scrollRowToVisible(next)
        }
    }

    private func setInput(_ text: String) {
        input.stringValue = text
        input.currentEditor()?.selectedRange = NSRange(location: (text as NSString).length, length: 0)
        if text.isEmpty { showNothing() } else { evaluate() }
    }

    // MARK: - Result line

    private func showValue(_ text: String, note: String?) {
        let line = NSMutableAttributedString(string: text, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium),
            .foregroundColor: NSColor.labelColor,
        ])
        if let note {
            line.append(NSAttributedString(string: "  " + note, attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.tertiaryLabelColor,
            ]))
        }
        result.attributedStringValue = line
    }

    private func showMessage(_ text: String) {
        result.attributedStringValue = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ])
    }

    private func showCopied(_ text: String) {
        let line = NSMutableAttributedString(string: text, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
        line.append(NSAttributedString(string: "  " + String(localized: "copied"), attributes: [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]))
        result.attributedStringValue = line
    }

    private func showNothing() {
        current = nil
        result.stringValue = ""
    }

    /// "2026-11-02" → "ECB 2 Nov", in the user's language.
    private static func ratesNote(_ day: String) -> String? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
        else { return nil }
        return String(localized: "ECB \(date.formatted(.dateTime.day().month(.abbreviated)))")
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - History

    private func reloadHistory() {
        table.reloadData()
        updateLowerArea()
        onResize?()
    }

    /// Below the result: the guide, the history, or nothing.
    private func updateLowerArea() {
        let rows = min(history.entries.count, Self.visibleRows)
        let help = isShowingHelp ? installHelpView() : nil
        let showsHistory = help == nil && rows > 0

        separator.isHidden = help == nil && !showsHistory
        scrollView.isHidden = !showsHistory
        helpView?.isHidden = help == nil
        historyHeight.constant = CGFloat(rows) * Self.rowHeight

        // Deactivate first so the competing bottom constraints never coexist.
        let bottoms: [(NSLayoutConstraint?, Bool)] = [
            (bottomWithHistory, showsHistory),
            (bottomWithHelp, help != nil),
            (bottomWithoutHistory, help == nil && !showsHistory),
        ]
        NSLayoutConstraint.deactivate(bottoms.compactMap { $1 ? nil : $0 })
        NSLayoutConstraint.activate(bottoms.compactMap { $1 ? $0 : nil })
    }

    @objc private func copyClickedRow() {
        let row = table.clickedRow
        guard history.entries.indices.contains(row) else { return }
        let entry = history.entries[row]
        copyToPasteboard(entry.clipboard)
        table.deselectAll(nil)
        showCopied(entry.display)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        history.entries.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: HistoryCell.identifier, owner: nil) as? HistoryCell ?? HistoryCell()
        let entry = history.entries[row]
        cell.expression.stringValue = entry.expression
        cell.value.stringValue = entry.display
        return cell
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}

private final class HistoryCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("HistoryCell")

    let expression = NSTextField(labelWithString: "")
    let value = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier

        expression.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        expression.textColor = .secondaryLabelColor
        expression.lineBreakMode = .byTruncatingMiddle
        expression.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        value.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        value.alignment = .right
        value.setContentHuggingPriority(.required, for: .horizontal)
        value.setContentCompressionResistancePriority(.required, for: .horizontal)

        for label in [expression, value] {
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        NSLayoutConstraint.activate([
            expression.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            expression.centerYAnchor.constraint(equalTo: centerYAnchor),
            value.leadingAnchor.constraint(greaterThanOrEqualTo: expression.trailingAnchor, constant: 12),
            value.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            value.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
