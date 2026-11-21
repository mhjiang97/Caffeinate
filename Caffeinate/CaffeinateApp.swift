import SwiftUI

@main
struct CaffeinateApp: App {
    @State private var manager = CaffeineManager()
    @AppStorage("showMenuBarCountdown") private var showCountdown = true

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: manager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .symbolEffect(.bounce, value: manager.isActive)
                if showCountdown, let r = manager.timeRemaining {
                    let units: Set<Duration.UnitsFormatStyle.Unit> = r >= 60 ? [.hours, .minutes] : [.seconds]
                    Text(Duration.seconds(r), format: .units(allowed: units, width: .narrow, fractionalPart: .hide(rounded: .down)))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
