import SwiftUI

enum CaffeineMode: String, CaseIterable, Identifiable {
    case idle = "Prevent Idle Sleep"
    case display = "Prevent Display Sleep"
    case system = "Prevent System Sleep"

    var id: Self { self }

    var flag: String {
        switch self {
        case .idle: return "-i"
        case .display: return "-d"
        case .system: return "-s"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "moon.zzz"
        case .display: return "display"
        case .system: return "lock.slash"
        }
    }

    var description: String {
        switch self {
        case .idle: return "Keeps display & CPU awake"
        case .display: return "Keeps display on only"
        case .system: return "Full prevention (AC power)"
        }
    }

    var tint: Color {
        switch self {
        case .idle: return .blue
        case .display: return .orange
        case .system: return .red
        }
    }
}

final class CaffeineManager: ObservableObject {
    @Published var isActive = false
    @Published var modes: Set<CaffeineMode> = [.display, .idle]
    @Published var timerDuration: Int? = nil
    @Published var timeRemaining: Int? = nil

    private var process: Process?
    private var countdown: Timer?

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        stop()

        var args = modes.map(\.flag)
        if args.isEmpty { args = ["-i"] }
        if let duration = timerDuration {
            args += ["-t", "\(duration)"]
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = args
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isActive = false
                self?.timeRemaining = nil
                self?.countdown?.invalidate()
                self?.countdown = nil
            }
        }

        do {
            try p.run()
        } catch {
            return
        }

        process = p
        isActive = true

        if let duration = timerDuration {
            timeRemaining = duration
            countdown = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let r = self.timeRemaining, r > 1 {
                        self.timeRemaining = r - 1
                    } else {
                        self.stop()
                    }
                }
            }
        }
    }

    func stop() {
        countdown?.invalidate()
        countdown = nil
        timeRemaining = nil
        if let p = process, p.isRunning { p.terminate() }
        process = nil
        isActive = false
    }
}
