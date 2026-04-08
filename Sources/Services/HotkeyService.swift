import AppKit
import Carbon.HIToolbox

/// Registers a global Carbon hotkey (⌥F) that fires from any foreground app.
///
/// Carbon's RegisterEventHotKey does NOT require Accessibility permission,
/// unlike a CGEvent tap — it's the right tool for a simple single-hotkey use case.
final class HotkeyService {
    /// Called on the main thread when the ⌥F hotkey fires.
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    // MARK: - Lifecycle

    func start() {
        guard eventHandlerRef == nil else { return }

        // Install a handler for kEventHotKeyPressed events
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, refcon) -> OSStatus in
                guard let refcon else { return noErr }
                let svc = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
                // Always deliver on main thread
                DispatchQueue.main.async { svc.onTrigger?() }
                return noErr
            },
            1,
            &eventSpec,
            refcon,
            &eventHandlerRef
        )

        // Register ⌥F
        // kVK_ANSI_F = 0x03 (position-based, layout-independent)
        // optionKey   = 0x0800 in Carbon modifier constants
        var hotkeyID = EventHotKeyID()
        hotkeyID.signature = "FoxB".fourCharCode
        hotkeyID.id = 1

        RegisterEventHotKey(
            UInt32(kVK_ANSI_F),
            UInt32(optionKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        print("[FoxBuddy] Hotkey registered: ⌥F")
    }

    func stop() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }
}

// MARK: - FourCharCode helper

private extension StringProtocol {
    /// Converts the first 4 ASCII characters of a string into a FourCharCode (OSType).
    var fourCharCode: FourCharCode {
        utf8.prefix(4).reduce(0) { ($0 << 8) | FourCharCode($1) }
    }
}
