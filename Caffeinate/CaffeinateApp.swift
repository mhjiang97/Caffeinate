import SwiftUI

@main
struct CaffeinateApp: App {
    @StateObject private var manager = CaffeineManager()
    @AppStorage("showMenuBarCountdown") private var showCountdown = true
    @AppStorage("activateOnLaunch") private var activateOnLaunch = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(manager: manager)
                .onAppear {
                    if activateOnLaunch, !manager.isActive {
                        manager.start()
                    }
                }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .symbolEffect(.bounce, value: manager.isActive)
                if showCountdown, let r = manager.timeRemaining {
                    Text(menuBarTime(r))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func menuBarTime(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            return m > 0 ? "\(h)h\(m)m" : "\(h)h"
        }
        return "\(seconds / 60)m"
    }
}
