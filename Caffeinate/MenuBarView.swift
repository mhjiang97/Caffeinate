import SwiftUI

struct MenuBarView: View {
    @ObservedObject var manager: CaffeineManager
    @State private var durationSeconds: Double = 7500
    @State private var toggleHovered = false
    @State private var showSettings = false
    @AppStorage("showProgressRing") private var showProgressRing = true
    private let indefinite: Double = 7500

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            sectionLabel("Mode")
            modeSection
            sectionLabel("Duration")
            durationSection
            footer
        }
        .padding(12)
        .frame(width: 260)
        .onAppear { durationSeconds = Double(manager.timerDuration ?? Int(indefinite)) }
        .animation(.spring(duration: 0.25), value: manager.isActive)
        .animation(.spring(duration: 0.2), value: manager.modes)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("Caffeinate")
                        .font(.system(size: 13, weight: .semibold))
                    if manager.isActive {
                        HStack(spacing: 3) {
                            ForEach(CaffeineMode.allCases) { mode in
                                if manager.modes.contains(mode) {
                                    Circle()
                                        .fill(mode.tint)
                                        .frame(width: 6, height: 6)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(manager.isActive ? .green : .secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            Button { manager.toggle() } label: {
                Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.system(size: 16, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.glass)
            .tint(manager.isActive ? .brown : toggleHovered ? .accentColor : nil)
            .scaleEffect(toggleHovered ? 1.08 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: toggleHovered)
            .onHover { toggleHovered = $0 }
            .help(manager.isActive ? "Click to allow sleep" : "Click to prevent sleep")
            .overlay {
                if showProgressRing,
                   let remaining = manager.timeRemaining,
                   let total = manager.timerDuration, total > 0 {
                    let elapsed = CGFloat(total - remaining) / CGFloat(total)
                    Circle()
                        .trim(from: 0, to: elapsed)
                        .stroke(
                            manager.modes.first?.tint ?? .accentColor,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(-3)
                        .opacity(elapsed > 0 ? 1 : 0)
                        .animation(.linear(duration: 1), value: remaining)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.clear, in: .rect(cornerRadius: 12))
    }

    private var statusText: String {
        guard manager.isActive else { return "System can sleep normally" }
        if let r = manager.timeRemaining { return "Active · \(formatTime(r)) remaining" }
        return "Active"
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        GlassEffectContainer {
            VStack(spacing: 4) {
                ForEach(CaffeineMode.allCases) { mode in
                    GlassHoverButton(isSelected: manager.modes.contains(mode), color: mode.tint) {
                        if manager.isActive { manager.stop() }
                        if manager.modes.contains(mode) {
                            guard manager.modes.count > 1 else { return }
                            manager.modes.remove(mode)
                        } else {
                            manager.modes.insert(mode)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11))
                                .frame(width: 14)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(mode.rawValue)
                                    .font(.system(size: 11))
                                Text(mode.description)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if manager.modes.contains(mode) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(durationLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(durationSeconds < indefinite ? .primary : .secondary)
            Slider(value: $durationSeconds, in: 300...indefinite, step: 300) {
                EmptyView()
            } minimumValueLabel: {
                Text("5m")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("∞")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .onChange(of: durationSeconds) { _, val in
                if manager.isActive { manager.stop() }
                manager.timerDuration = val < indefinite ? Int(val) : nil
            }
            GlassEffectContainer {
                HStack(spacing: 4) {
                    ForEach(durationPresets, id: \.seconds) { preset in
                        GlassHoverButton(
                            isSelected: Int(durationSeconds) == preset.seconds
                        ) {
                            durationSeconds = Double(preset.seconds)
                        } label: {
                            Text(preset.label)
                                .font(.system(size: 10, weight: .medium))
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.mini)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.clear, in: .rect(cornerRadius: 12))
        .animation(.spring(duration: 0.3), value: durationSeconds)
    }

    private var durationLabel: String {
        guard durationSeconds < indefinite else { return "∞" }
        let total = Int(durationSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            GlassHoverButton(isSelected: showSettings) {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .controlSize(.small)
            }
            .popover(isPresented: $showSettings) {
                SettingsView()
            }
            Spacer()
            GlassHoverButton(isSelected: false, color: .red) {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Data

    private let durationPresets: [(label: String, seconds: Int)] = [
        ("15m", 900), ("30m", 1800), ("1h", 3600), ("2h", 7200), ("∞", 7500),
    ]

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else if seconds >= 60 {
            let m = seconds / 60
            let s = seconds % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Hover-aware Glass Button

struct GlassHoverButton<Label: View>: View {
    var isSelected: Bool
    var color: Color = .accentColor
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var hovered = false

    var body: some View {
        Button(action: action, label: label)
            .buttonStyle(.glass)
            .tint((isSelected || hovered) ? color : nil)
            .scaleEffect(hovered ? 1.04 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: hovered)
            .onHover { hovered = $0 }
    }
}
