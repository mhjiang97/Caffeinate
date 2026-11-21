import SwiftUI

enum CaffeineMode: String, CaseIterable, Identifiable {
    case idle
    case display
    case system

    var id: Self { self }

    var title: String {
        switch self {
        case .idle: return "Prevent Idle Sleep"
        case .display: return "Prevent Display Sleep"
        case .system: return "Prevent System Sleep"
        }
    }

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

    var subtitle: String {
        switch self {
        case .idle: return "Keeps the Mac awake; display may sleep"
        case .display: return "Keeps the display on"
        case .system: return "Prevents system sleep (AC power only)"
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

@MainActor
@Observable
final class CaffeineManager {
    private(set) var isActive = false
    private(set) var timeRemaining: Int?

    var modes: Set<CaffeineMode> {
        didSet { UserDefaults.standard.set(modes.map(\.rawValue), forKey: "modes") }
    }

    var timerDuration: Int? {
        didSet { UserDefaults.standard.set(timerDuration ?? 0, forKey: "timerDuration") }
    }

    /// The highest-priority selected mode, in declaration order.
    var primaryMode: CaffeineMode? {
        CaffeineMode.allCases.first(where: modes.contains)
    }

    @ObservationIgnored private var process: Process?
    @ObservationIgnored private var countdown: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        let storedModes = (defaults.stringArray(forKey: "modes") ?? []).compactMap(CaffeineMode.init(rawValue:))
        modes = storedModes.isEmpty ? [.idle, .display] : Set(storedModes)
        let storedDuration = defaults.integer(forKey: "timerDuration")
        timerDuration = storedDuration > 0 ? storedDuration : nil

        if defaults.bool(forKey: "activateOnLaunch") {
            start()
        }
    }

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        stop()

        var args = CaffeineMode.allCases.filter(modes.contains).map(\.flag)
        if args.isEmpty { args = ["-i"] }
        // Tie caffeinate's lifetime to ours so it never outlives a quit or crash.
        args += ["-w", "\(ProcessInfo.processInfo.processIdentifier)"]
        if let timerDuration {
            args += ["-t", "\(timerDuration)"]
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = args
        let id = ObjectIdentifier(p)
        p.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                // Ignore late notifications from a process that was already replaced or stopped.
                guard let self, let current = self.process, ObjectIdentifier(current) == id else { return }
                self.stop()
            }
        }

        do {
            try p.run()
        } catch {
            return
        }

        process = p
        isActive = true

        if let timerDuration {
            let end = Date.now.addingTimeInterval(TimeInterval(timerDuration))
            timeRemaining = timerDuration
            countdown = Task { [weak self] in
                while true {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled, let self else { return }
                    // Derive from the end date so the countdown doesn't drift.
                    let remaining = Int(end.timeIntervalSinceNow.rounded(.up))
                    if remaining > 0 {
                        self.timeRemaining = remaining
                    } else {
                        self.stop()
                        return
                    }
                }
            }
        }
    }

    func stop() {
        countdown?.cancel()
        countdown = nil
        timeRemaining = nil
        if let process, process.isRunning { process.terminate() }
        process = nil
        isActive = false
    }
}
