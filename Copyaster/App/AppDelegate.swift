import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var mainPopover: NSPopover!
    private var hoverPopover: NSPopover!
    private var selectorWindow: NSWindow?
    private var localMonitor: Any?

    let appState = AppState()
    let clipboardMonitor = ClipboardMonitor()
    let hotkeyManager = HotkeyManager()
    let storageManager = StorageManager()

    private var hoverTimer: Timer?
    private var isHovering = false
    private var clickMonitor: Any?
    private var previousApp: NSRunningApplication?
    private var selectorPreviousApp: NSRunningApplication?
    private var selectorSelectedIndex: Int = 0

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopovers()
        setupClipboardMonitor()
        setupHotkey()
        loadSavedClips()
        appState.onSavedChanged = { [weak self] in self?.persistSaved() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotkeyManager.stop()
        persistSaved()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }

        button.image = Self.makeMenuBarIcon()
        button.toolTip = "Copyaster"

        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Hover tracking
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)
    }

    /// Clipboard + "C" template image for the menu bar (adapts to light/dark).
    private static func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // SF Symbol clipboard as base
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            guard let clipboard = NSImage(
                systemSymbolName: "clipboard",
                accessibilityDescription: "Copyaster"
            )?.withSymbolConfiguration(symbolConfig) else { return false }

            let symSize = clipboard.size
            let symX = (rect.width - symSize.width) / 2
            let symY = (rect.height - symSize.height) / 2
            clipboard.draw(in: NSRect(x: symX, y: symY, width: symSize.width, height: symSize.height))

            // "C" letter centered in the clipboard body
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 7.5, weight: .heavy),
                .foregroundColor: NSColor.black
            ]
            let letter = "C" as NSString
            let letterSize = letter.size(withAttributes: attrs)
            let letterX = (rect.width - letterSize.width) / 2
            let letterY = (rect.height - letterSize.height) / 2 - 1.5
            letter.draw(at: NSPoint(x: letterX, y: letterY), withAttributes: attrs)

            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Popovers

    private func setupPopovers() {
        mainPopover = NSPopover()
        mainPopover.contentSize = NSSize(width: 320, height: 420)
        mainPopover.behavior = .transient
        mainPopover.animates = true

        hoverPopover = NSPopover()
        hoverPopover.contentSize = NSSize(width: 260, height: 100)
        hoverPopover.behavior = .transient
        hoverPopover.animates = false
    }

    private func updateMainPopover() {
        mainPopover.contentViewController = NSHostingController(
            rootView: PanelView(state: appState, onPaste: { [weak self] item in
                self?.pasteFromPanel(item)
            })
        )
    }

    private func pasteFromPanel(_ item: ClipboardItem) {
        let targetApp = previousApp
        appState.copyToClipboard(item)
        mainPopover.performClose(nil)

        // Devolver foco — el usuario pega con ⌘V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            targetApp?.activate()
        }
    }

    // MARK: - Click

    @objc private func statusItemClicked() {
        hideHoverPreview()

        // Right click → context menu
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if mainPopover.isShown {
            mainPopover.performClose(nil)
        } else {
            // Guardar la app que tiene foco para volver después de pegar
            previousApp = NSWorkspace.shared.frontmostApplication

            appState.selectedTab = .recents
            appState.searchText = ""
            updateMainPopover()

            guard let button = statusItem.button else { return }
            mainPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            mainPopover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Hover

    @objc func mouseEntered(with event: NSEvent) {
        guard !mainPopover.isShown else { return }
        isHovering = true

        hoverTimer?.invalidate()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self, self.isHovering else { return }
            self.showHoverPreview()
        }
    }

    @objc func mouseExited(with event: NSEvent) {
        isHovering = false
        hoverTimer?.invalidate()
        hideHoverPreview()
    }

    private func showHoverPreview() {
        let currentItem = appState.recents.first
        hoverPopover.contentViewController = NSHostingController(
            rootView: HoverPreviewView(item: currentItem)
        )
        guard let button = statusItem.button else { return }
        hoverPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func hideHoverPreview() {
        if hoverPopover.isShown {
            hoverPopover.performClose(nil)
        }
    }

    // MARK: - Clipboard Monitor

    private func setupClipboardMonitor() {
        clipboardMonitor.onChange = { [weak self] item in
            DispatchQueue.main.async {
                self?.appState.addRecent(item)
            }
        }
        clipboardMonitor.start()
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.toggleInlineSelector()
        }
        hotkeyManager.start()
    }

    // MARK: - Inline Selector

    private func toggleInlineSelector() {
        if let window = selectorWindow, window.isVisible {
            dismissSelector()
            return
        }
        showInlineSelector()
    }

    private func showInlineSelector() {
        // Limpiar monitors anteriores que puedan haber quedado
        dismissSelector()

        guard !appState.allItems.isEmpty else { return }

        let mouseLocation = NSEvent.mouseLocation

        let selectorView = InlineSelectorView(
            recents: appState.recents,
            saved: appState.saved,
            onSelect: { [weak self] item in
                self?.dismissSelector()
                self?.pasteItem(item)
            },
            onDismiss: { [weak self] in
                self?.dismissSelector()
            }
        )

        let hostingView = NSHostingView(rootView: selectorView)
        let size = hostingView.fittingSize
        let w: CGFloat = max(size.width, 300)
        let h: CGFloat = max(min(size.height, 360), 80)

        let window = FloatingPanel(contentRect: NSRect(
            x: mouseLocation.x - w / 2,
            y: mouseLocation.y - h,
            width: w,
            height: h
        ))
        window.contentView = hostingView

        // Guardar app anterior para devolver foco al pegar
        selectorPreviousApp = NSWorkspace.shared.frontmostApplication

        // Activar y mostrar — NO devolver foco, el selector necesita recibir teclas
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        selectorWindow = window
        selectorSelectedIndex = 0

        // Teclado: flechas + Enter + Escape — usa items vivos, no snapshot
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let liveItems = self.appState.recents + self.appState.saved
            guard !liveItems.isEmpty else { return event }

            switch Int(event.keyCode) {
            case 125: // Down
                self.selectorSelectedIndex = min(self.selectorSelectedIndex + 1, liveItems.count - 1)
                self.updateSelectorView()
                return nil
            case 126: // Up
                self.selectorSelectedIndex = max(self.selectorSelectedIndex - 1, 0)
                self.updateSelectorView()
                return nil
            case 36: // Enter
                if self.selectorSelectedIndex < liveItems.count {
                    let item = liveItems[self.selectorSelectedIndex]
                    self.dismissSelector()
                    self.pasteItem(item)
                }
                return nil
            case 53: // Escape
                self.dismissSelector()
                return nil
            default:
                return event
            }
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let win = self.selectorWindow else { return }
            if !win.frame.contains(NSEvent.mouseLocation) {
                self.dismissSelector()
            }
        }
    }

    private func dismissSelector() {
        selectorWindow?.close()
        selectorWindow = nil
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    private func updateSelectorView() {
        guard let window = selectorWindow else { return }
        let view = InlineSelectorView(
            recents: appState.recents,
            saved: appState.saved,
            selectedOverride: selectorSelectedIndex,
            onSelect: { [weak self] item in
                self?.dismissSelector()
                self?.pasteItem(item)
            },
            onDismiss: { [weak self] in
                self?.dismissSelector()
            }
        )
        window.contentView = NSHostingView(rootView: view)
    }

    private func pasteItem(_ item: ClipboardItem) {
        let targetApp = selectorPreviousApp ?? previousApp
        appState.copyToClipboard(item)

        // Devolver foco a la app — el usuario pega con ⌘V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            targetApp?.activate()
        }
    }

    // MARK: - Context Menu (right click)

    private var settingsWindow: NSWindow?

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Ajustes...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Salir de Copyaster", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { self.statusItem.menu = nil }
    }

    @objc private func openSettings() {
        if let win = settingsWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView(onHotkeyChanged: { [weak self] in
            self?.hotkeyManager.registerHotkey()
        })
        let hostingView = NSHostingView(rootView: settingsView)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 240),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.contentView = hostingView
        win.center()
        win.isReleasedWhenClosed = false

        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        settingsWindow = win
    }

    @objc private func quitApp() {
        persistSaved()
        NSApp.terminate(nil)
    }

    // MARK: - Persistence

    private func loadSavedClips() {
        appState.saved = storageManager.loadSaved()
    }

    func persistSaved() {
        storageManager.saveToDisk(appState.saved)
    }
}
