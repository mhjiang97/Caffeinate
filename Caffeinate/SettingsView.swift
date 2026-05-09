import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("showMenuBarCountdown") private var showCountdown = true
    @AppStorage("showProgressRing") private var showProgressRing = true
    @AppStorage("activateOnLaunch") private var activateOnLaunch = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 2) {
                glassToggleRow(
                icon: "timer",
                title: "Menu Bar Countdown",
                subtitle: "Show remaining time next to icon",
                isOn: $showCountdown
            )
            glassToggleRow(
                icon: "circle.dotted",
                title: "Progress Ring",
                subtitle: "Show elapsed ring on toggle button",
                isOn: $showProgressRing
            )
            glassToggleRow(
                icon: "play.circle",
                title: "Activate on Launch",
                subtitle: "Start caffeinate when app opens",
                isOn: $activateOnLaunch
            )
            glassToggleRow(
                icon: "person.crop.circle",
                title: "Launch at Login",
                subtitle: "Open automatically on startup",
                isOn: $launchAtLogin
            )
            .onChange(of: launchAtLogin) { _, enabled in
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchAtLogin = !enabled
                }
            }
            }
        }
        .padding(8)
    }

    private func glassToggleRow(
        icon: String, title: String, subtitle: String, isOn: Binding<Bool>
    ) -> some View {
        GlassHoverButton(isSelected: isOn.wrappedValue) {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .frame(width: 14)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11))
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isOn.wrappedValue ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
        }
    }
}
