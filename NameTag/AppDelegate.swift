import AppKit
import Combine
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let appState = AppState()
    private var optionsWindowController: OptionsWindowController!
    private var cancellable: AnyCancellable?
    private var loginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        optionsWindowController = OptionsWindowController(appState: appState)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = appState.displayLabel

        buildMenu()

        cancellable = appState.$customLabel
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.statusItem.button?.title = self.appState.displayLabel
            }
    }

    private func buildMenu() {
        let menu = NSMenu()

        loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        updateLoginCheckmark()
        menu.addItem(loginItem)

        let optionsItem = NSMenuItem(title: "Options...", action: #selector(openOptions), keyEquivalent: "")
        optionsItem.target = self
        menu.addItem(optionsItem)

        let refreshItem = NSMenuItem(title: "Refresh Hostname", action: #selector(refreshHostname), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateLoginCheckmark() {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Login Item Error"
            alert.informativeText = "Could not update login item: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.runModal()
        }
        updateLoginCheckmark()
    }

    @objc private func refreshHostname() {
        statusItem.button?.title = appState.displayLabel
    }

    @objc private func openOptions() {
        optionsWindowController.showOptionsPanel()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
