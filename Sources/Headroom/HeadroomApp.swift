import SwiftUI
import HeadroomCore

@main
struct HeadroomApp: App {
    @StateObject private var store: UsageStore
    @AppStorage(SettingsKey.menuBarStyle) private var style = MenuBarStyle.combined.rawValue
    @AppStorage(SettingsKey.providerEnabled(.claude)) private var claudeEnabled = true
    @AppStorage(SettingsKey.providerEnabled(.codex)) private var codexEnabled = true

    init() {
        AppSettings.registerDefaults()
        _store = StateObject(wrappedValue: UsageStore())
    }

    /// Separate icons need at least one provider; with none enabled, fall back
    /// to the combined icon so Settings stays reachable.
    private var showsCombined: Bool {
        MenuBarStyle(rawValue: style) != .separate || (!claudeEnabled && !codexEnabled)
    }

    var body: some Scene {
        MenuBarExtra(isInserted: inserted(showsCombined)) {
            PopoverView(scope: nil).environmentObject(store)
        } label: {
            CombinedMenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)

        MenuBarExtra(isInserted: inserted(!showsCombined && claudeEnabled)) {
            PopoverView(scope: .claude).environmentObject(store)
        } label: {
            ProviderMenuBarLabel(store: store.store(for: .claude))
        }
        .menuBarExtraStyle(.window)

        MenuBarExtra(isInserted: inserted(!showsCombined && codexEnabled)) {
            PopoverView(scope: .codex).environmentObject(store)
        } label: {
            ProviderMenuBarLabel(store: store.store(for: .codex))
        }
        .menuBarExtraStyle(.window)

        // A real window rather than embedding it in a MenuBarExtra popover:
        // that popover's window doesn't reliably shrink back down once it's
        // grown to fit a taller view. Opened via the gear button's
        // `showSettingsWindow:` selector, since an LSUIElement app has no
        // visible app-menu "Settings…" item of its own.
        Settings {
            SettingsPanel().environmentObject(store)
        }
    }

    /// Visibility follows the settings; removing an item by ⌘-dragging it out is ignored.
    private func inserted(_ value: Bool) -> Binding<Bool> {
        Binding(get: { value }, set: { _ in })
    }
}
