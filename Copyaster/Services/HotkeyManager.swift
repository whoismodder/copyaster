import AppKit
import Carbon.HIToolbox

/// Carbon event callback para hotkeys globales.
private func hotKeyEventHandler(
    eventHandlerCall: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    // Solo manejar key pressed, ignorar released
    let kind = GetEventKind(event)
    if kind != UInt32(kEventHotKeyPressed) {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let err = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard err == noErr else { return err }

    DispatchQueue.main.async {
        HotkeyManager.current?.onHotkeyPressed?()
    }
    return noErr
}

final class HotkeyManager {
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private(set) var isActive = false

    var onHotkeyPressed: (() -> Void)?
    static weak var current: HotkeyManager?

    private static let signature: FourCharCode = 0x43505941 // 'CPYA'

    func start() {
        HotkeyManager.current = self

        // Instalar handler con 0 types, agregar después
        let s1 = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyEventHandler,
            0,
            nil,
            nil,
            &eventHandlerRef
        )
        guard s1 == noErr, let handler = eventHandlerRef else { return }

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        let s2 = AddEventTypesToHandler(handler, 2, &eventTypes)
        guard s2 == noErr else { return }

        // Demorar registro para esperar que el run loop esté listo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.registerHotkey()
        }
    }

    func registerHotkey() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }

        let option = HotkeyOption.load()
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = Self.signature
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            option.carbonKeyCode,
            option.carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            OptionBits(0),
            &hotkeyRef
        )
        isActive = status == noErr
    }

    func stop() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
        isActive = false
        HotkeyManager.current = nil
    }

    static var hasAccessibilityPermission: Bool { AXIsProcessTrusted() }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
