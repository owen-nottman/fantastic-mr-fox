import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // Single source of truth for all UI state
    private let store = FoxStore()

    private var overlayController: OverlayWindowController!
    private var inputPanelController: InputPanelController!
    private let hotkeyService = HotkeyService()

    private var statusItem: NSStatusItem?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and app switcher — FoxBuddy lives in the menu bar only
        NSApp.setActivationPolicy(.accessory)

        setupControllers()
        setupMenuBar()
        setupHotkey()

        // Prompt for Screen Recording permission (required for window capture)
        PermissionService.shared.requestIfNeeded()

        // Show the fox mascot
        overlayController.show()

        // Start watching store.showInputPanel to drive the input panel
        observeInputPanel()
    }

    // MARK: - Setup

    private func setupControllers() {
        overlayController = OverlayWindowController(store: store)
        inputPanelController = InputPanelController(store: store)
    }

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
                self?.store.openInputPanel()
            }
        }
        hotkeyService.start()
    }

    @objc private func triggerFox() {
        store.openInputPanel()
    }

    // MARK: - Input panel observation
    //
    // Uses @Observable's withObservationTracking to react to store.showInputPanel changes
    // without Combine or NotificationCenter. The pattern is: track → onChange fires → show/hide
    // → re-register tracking. This keeps the recursive call on the main actor.

    @MainActor
    private func observeInputPanel() {
        withObservationTracking {
            _ = store.showInputPanel
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.store.showInputPanel {
                    self.inputPanelController.show()
                } else {
                    self.inputPanelController.hide()
                }
                // Re-register to watch the next change
                self.observeInputPanel()
            }
        }
    }
}
