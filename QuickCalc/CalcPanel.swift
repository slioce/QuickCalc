import AppKit

/// Borderless, non-activating panel: takes keyboard input without stealing focus
/// from the app underneath, like Spotlight.
final class CalcPanel: NSPanel {
    var onResignKey: (() -> Void)?
    /// ⌘C with no text selected; returns false when there is no result to copy.
    var onCopyResult: (() -> Bool)?

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }

    /// Without a Dock icon there is no Edit menu, so the standard shortcuts are routed by hand.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.lowercased()
        let hasSelection = ((firstResponder as? NSTextView)?.selectedRange().length ?? 0) > 0
        if flags == .command, !hasSelection, key == "c" || key == "x" {
            // With nothing selected the text view would empty the clipboard; ⌘C copies the result instead.
            if key == "c" { _ = onCopyResult?() }
            return true
        }
        let action: Selector? = switch (flags, key) {
        case (.command, "x"): #selector(NSText.cut(_:))
        case (.command, "c"): #selector(NSText.copy(_:))
        case (.command, "v"): #selector(NSText.paste(_:))
        case (.command, "a"): #selector(NSText.selectAll(_:))
        case (.command, "z"): Selector(("undo:"))
        case ([.command, .shift], "z"): Selector(("redo:"))
        default: nil
        }
        if let action, NSApp.sendAction(action, to: nil, from: self) { return true }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
final class CalcPanelController {
    /// The status item's frame on screen, or nil when it is hidden.
    var anchorProvider: (() -> NSRect?)?

    private let panel = CalcPanel()
    private let content: CalcViewController
    private var hiddenAt = Date.distantPast

    init(history: History, rates: ExchangeRates) {
        content = CalcViewController(history: history, rates: rates)
        panel.contentViewController = content
        panel.onResignKey = { [weak self] in self?.hide() }
        panel.onCopyResult = { [weak self] in self?.content.copyResult() ?? false }
        content.onClose = { [weak self] in self?.hide() }
        content.onResize = { [weak self] in self?.fitToContent() }
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else if Date().timeIntervalSince(hiddenAt) > 0.3 {
            // A click on the status item first closes the panel via resignKey; don't reopen it.
            show()
        }
    }

    /// Opens the panel on the guide, or switches to it when already open.
    func showHelp() {
        if panel.isVisible {
            content.setHelpVisible(true)
        } else {
            show(help: true)
        }
    }

    func show(help: Bool = false) {
        content.prepareForShow(showingHelp: help)
        let size = content.view.fittingSize
        panel.setFrame(NSRect(origin: origin(for: size), size: size), display: false)
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        content.focusInput()
    }

    func hide() {
        guard panel.isVisible else { return }
        hiddenAt = Date()
        panel.orderOut(nil)
    }

    /// Grows or shrinks with the history while keeping the top edge in place.
    private func fitToContent() {
        guard panel.isVisible else { return }
        let size = content.view.fittingSize
        var frame = panel.frame
        frame.origin.y += frame.height - size.height
        frame.size = size
        panel.setFrame(frame, display: true)
        panel.invalidateShadow()
    }

    private func origin(for size: NSSize) -> NSPoint {
        if let anchor = anchorProvider?(),
           let screen = NSScreen.screens.first(where: { $0.frame.contains(NSPoint(x: anchor.midX, y: anchor.midY)) }) {
            let visible = screen.visibleFrame
            let x = min(max(anchor.midX - size.width / 2, visible.minX + 8), visible.maxX - size.width - 8)
            return NSPoint(x: x, y: anchor.minY - 6 - size.height)
        }
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        return NSPoint(x: visible.midX - size.width / 2, y: visible.maxY - visible.height * 0.2 - size.height)
    }
}
