import Carbon.HIToolbox

/// Global shortcut through Carbon, which needs no Accessibility permission.
/// ⌃⌥Space rather than ⌥Space: some macOS 15 releases rejected shortcuts whose only modifier is ⌥.
@MainActor
final class HotKey {
    static let keyCode = UInt32(kVK_Space)
    static let modifiers = UInt32(controlKey | optionKey)
    static let label = "⌃⌥Space"

    var action: (() -> Void)?
    private(set) var isRegistered = false
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
                MainActor.assumeIsolated { hotKey.action?() }
                return noErr
            },
            1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef
        )
        guard installed == noErr else { return }

        let id = EventHotKeyID(signature: OSType(0x5143_4C43), id: 1) // "QCLC"
        let registered = RegisterEventHotKey(Self.keyCode, Self.modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        isRegistered = registered == noErr
    }
}
