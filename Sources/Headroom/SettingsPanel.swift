import AppKit
import ServiceManagement
import SwiftUI
import HeadroomCore

/// Owns the Settings window directly with plain AppKit, rather than
/// routing through SwiftUI's `Settings { }` scene: triggering that scene
/// on demand needs either a private selector (`showSettingsWindow:`,
/// which broke on macOS 26) or the public `openSettings` environment
/// action (only in the macOS 15+ SDK — too new for this project's macOS
/// 13 minimum, and not present in CI's SDK either). Managing the window
/// ourselves needs no OS-version-specific API at all.
enum SettingsWindowController {
    private static weak var window: NSWindow?

    static func show(store: UsageStore) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }
        // NSWindow(contentViewController:) sizes the window to the hosted
        // SwiftUI view's own ideal size; assigning a plain NSHostingView to
        // a zero-rect window's contentView wouldn't auto-size it.
        let controller = NSHostingController(rootView: SettingsPanel().environmentObject(store))
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Headroom Settings"
        window.isReleasedWhenClosed = false
        // Without this an accessory app's window stays pinned to whichever
        // macOS Space it first opened on.
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.center()
        // Switching back to .accessory (see the gear button) hides the
        // Dock icon again once Settings is closed.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { _ in
            NSApp.setActivationPolicy(.accessory)
        }
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }
}

struct SettingsPanel: View {
    @EnvironmentObject private var store: UsageStore
    @AppStorage(SettingsKey.refreshMinutes) private var refreshMinutes = 5
    @AppStorage(SettingsKey.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(SettingsKey.sessionThresholds) private var sessionThresholds = "75, 90"
    @AppStorage(SettingsKey.weeklyThresholds) private var weeklyThresholds = "75, 90"
    @AppStorage(SettingsKey.menuBarText) private var menuBarText = MenuBarTextMode.sessionUsed.rawValue
    @AppStorage(SettingsKey.menuBarStyle) private var menuBarStyle = MenuBarStyle.combined.rawValue
    @AppStorage(SettingsKey.providerEnabled(.claude)) private var claudeEnabled = true
    @AppStorage(SettingsKey.providerEnabled(.codex)) private var codexEnabled = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            section("Services") {
                Toggle("Claude (Claude Code sign-in)", isOn: $claudeEnabled)
                    .onChange(of: claudeEnabled) { _ in store.applyEnabledProviders() }
                Toggle("Codex (Codex CLI sign-in)", isOn: $codexEnabled)
                    .onChange(of: codexEnabled) { _ in store.applyEnabledProviders() }
                Text("Codex shows Codex limits only; ChatGPT chat message limits aren't available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            section("Refresh") {
                Picker("Check every", selection: $refreshMinutes) {
                    ForEach(AppSettings.refreshChoices, id: \.self) { Text("\($0) min").tag($0) }
                }
                .onChange(of: refreshMinutes) { _ in store.refreshAll() }
            }

            section("Notifications") {
                Toggle("Alert before hitting limits", isOn: $notificationsEnabled)
                thresholdField("Session at", text: $sessionThresholds)
                thresholdField("Weekly at", text: $weeklyThresholds)
                Button("Send test notification") { store.notifier.postTest() }
                    .disabled(!store.notifier.isAvailable)
            }

            section("Menu bar") {
                Picker("Icons", selection: $menuBarStyle) {
                    ForEach(MenuBarStyle.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Show", selection: $menuBarText) {
                    ForEach(MenuBarTextMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in setLaunchAtLogin(enabled) }
                if let launchAtLoginError {
                    Text(launchAtLoginError).font(.caption).foregroundStyle(.orange)
                }
            }

            Text("Reads Claude Code's and Codex's existing sign-ins (never refreshes or changes them) and asks the same usage endpoints their /usage and /status commands use. Nothing leaves your Mac except those requests to api.anthropic.com and chatgpt.com.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 360)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
            content()
        }
    }

    private func thresholdField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            TextField("75, 90", text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 110)
            Text("%").foregroundStyle(.secondary)
            Spacer()
        }
        .disabled(!notificationsEnabled)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        // Also stops the onChange loop when the catch below resets the toggle.
        let status = SMAppService.mainApp.status
        guard enabled != (status == .enabled || status == .requiresApproval) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Couldn't change login item: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
