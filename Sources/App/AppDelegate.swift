import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // Single source of truth for all UI state
    private let store = FoxStore()

    private var overlayController: OverlayWindowController!
    private let hotkeyService = HotkeyService()

    private var statusItem: NSStatusItem?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and app switcher — FoxBuddy lives in the menu bar only
        NSApp.setActivationPolicy(.accessory)

        overlayController = OverlayWindowController(store: store)

        setupMenuBar()
        setupHotkey()

        // Prompt for Screen Recording permission (required for all capture modes)
        PermissionService.shared.requestIfNeeded()

        // Show the fox mascot overlay
        overlayController.show()
    }

    // MARK: - Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.title = "🦊"

        let menu = NSMenu()

        let askItem = NSMenuItem(title: "Ask FoxBuddy…  ⌥F", action: #selector(triggerFox), keyEquivalent: "")
        askItem.target = self
        menu.addItem(askItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit FoxBuddy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func setupHotkey() {
        hotkeyService.onTrigger = { [weak self] in
            DispatchQueue.main.async {
                self?.store.trigger()
            }
        }
        hotkeyService.start()
    }

    @objc private func triggerFox() {
        store.trigger()
    }
}
