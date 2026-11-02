import AppKit
import ServiceManagement

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// There is no main nib, so `NSApplicationMain` would never create the delegate.
    /// `NSApplication.delegate` is weak, so the instance must outlive `run()`.
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let history = History()
    private let rates = ExchangeRates()
    private var panel: CalcPanelController!
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = CalcPanelController(history: history, rates: rates)
        panel.anchorProvider = { [weak self] in self?.visibleButtonFrame() }
        rates.refreshIfNeeded()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "plus.forwardslash.minus", accessibilityDescription: "QuickCalc")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(buttonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let hotKey = HotKey()
        hotKey.action = { [weak self] in self?.panel.toggle() }
        self.hotKey = hotKey
    }

    // MARK: Status item

    @objc private func buttonClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            panel.toggle()
        }
    }

    private func showMenu() {
        panel.hide()

        let menu = NSMenu()
        menu.autoenablesItems = false

        let shortcut = NSMenuItem(
            title: hotKey?.isRegistered == true
                ? String(localized: "Open with \(HotKey.label)")
                : String(localized: "Shortcut \(HotKey.label) unavailable"),
            action: nil, keyEquivalent: ""
        )
        shortcut.isEnabled = false

        let launchAtLogin = item(String(localized: "Launch at Login"), #selector(toggleLaunchAtLogin))
        launchAtLogin.state = SMAppService.mainApp.status == .enabled ? .on : .off
        let clearHistory = item(String(localized: "Clear History"), #selector(clearHistory))
        clearHistory.isEnabled = !history.entries.isEmpty

        menu.items = [
            shortcut,
            item(String(localized: "Help"), #selector(showHelp)),
            .separator(),
            launchAtLogin,
            clearHistory,
            .separator(),
            item(String(localized: "About QuickCalc"), #selector(showAbout)),
            NSMenuItem(title: String(localized: "Quit QuickCalc"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ]

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    /// nil when the icon isn't on screen, e.g. pushed behind the notch by other menu bar items.
    private func visibleButtonFrame() -> NSRect? {
        guard let window = statusItem.button?.window, window.isVisible, let screen = window.screen else { return nil }
        let frame = window.frame
        guard screen.frame.contains(NSPoint(x: frame.midX, y: frame.midY)) else { return nil }
        if screen.safeAreaInsets.top > 0, let right = screen.auxiliaryTopRightArea, frame.minX < right.minX {
            return nil
        }
        return frame
    }

    // MARK: Actions

    @objc private func showHelp() {
        panel.showHelp()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSSound.beep()
        }
    }

    @objc private func clearHistory() {
        history.clear()
    }

    @objc private func showAbout() {
        NSApp.activate()  // a menu bar app has no key window, so the panel would otherwise open behind others
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(
                string: String(localized: "Free software under the GNU General Public License v3."),
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize), .foregroundColor: NSColor.labelColor]
            ),
        ])
    }
}
