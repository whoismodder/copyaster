import SwiftUI
import Carbon.HIToolbox

// MARK: - Hotkey Presets

enum HotkeyOption: String, CaseIterable, Identifiable {
    case cmdShiftV = "⌘⇧V"
    case ctrlShiftV = "⌃⇧V"
    case cmdShiftC = "⌘⇧C"
    case cmdShiftX = "⌘⇧X"

    var id: String { rawValue }

    var carbonKeyCode: UInt32 {
        switch self {
        case .cmdShiftV, .ctrlShiftV: return UInt32(kVK_ANSI_V)
        case .cmdShiftC: return UInt32(kVK_ANSI_C)
        case .cmdShiftX: return UInt32(kVK_ANSI_X)
        }
    }

    var carbonModifiers: UInt32 {
        switch self {
        case .cmdShiftV: return UInt32(cmdKey | shiftKey)
        case .ctrlShiftV: return UInt32(controlKey | shiftKey)
        case .cmdShiftC: return UInt32(cmdKey | shiftKey)
        case .cmdShiftX: return UInt32(cmdKey | shiftKey)
        }
    }

    static func load() -> HotkeyOption {
        let raw = UserDefaults.standard.string(forKey: "copyaster_hotkey") ?? "⌘⇧V"
        return HotkeyOption(rawValue: raw) ?? .cmdShiftV
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: "copyaster_hotkey")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var launchAtLogin = LaunchManager.isEnabled
    @State private var selectedHotkey = HotkeyOption.load()
    var onHotkeyChanged: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Text("Ajustes")
                .font(.callout.weight(.medium))
                .padding(.vertical, 10)

            Divider().opacity(0.4)

            VStack(spacing: 16) {
                // Launch at login
                Toggle(isOn: $launchAtLogin) {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text("Abrir al iniciar Mac")
                            .font(.callout)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: launchAtLogin) { _, newVal in
                    if newVal { LaunchManager.enable() }
                    else { LaunchManager.disable() }
                }

                Divider().opacity(0.2)

                // Hotkey picker
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Atajo global")
                        .font(.callout)
                    Spacer()
                    Picker("", selection: $selectedHotkey) {
                        ForEach(HotkeyOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)
                    .onChange(of: selectedHotkey) { _, newVal in
                        newVal.save()
                        onHotkeyChanged?()
                    }
                }

                Divider().opacity(0.2)

                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Últimos 20 clips · auto-eliminación")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(16)

            Spacer()

            Text("Copyaster v0.1.0")
                .font(.caption2)
                .foregroundStyle(.quaternary)
                .padding(.bottom, 8)
        }
        .frame(width: 300, height: 240)
        .background(.ultraThinMaterial)
    }
}
