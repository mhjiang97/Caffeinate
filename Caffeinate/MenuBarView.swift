import SwiftUI

struct MenuBarView: View {
    let manager: CaffeineManager
    @State private var showSettings = false
    @AppStorage("showProgressRing") private var showProgressRing = true
    @Namespace private var glass
    @State private var cupHovered = false
    @State private var cupHoverCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Slider position that represents "no time limit".
    private let indefinite = 7500
    private let durationPresets: [Int?] = [900, 1800, 3600, 7200, nil]

    private var activeTint: Color { manager.primaryMode?.tint ?? .accentColor }

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
        .background {
            ModeGlow(
                colors: CaffeineMode.allCases.filter(manager.modes.contains).map(\.tint),
                isActive: manager.isActive
            )
            .ignoresSafeArea()
        }
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
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 6) {
                    if manager.isActive, let r = manager.timeRemaining {
                        Text(compactTime(r))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.default, value: r)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.tint(activeTint.opacity(0.6)).interactive(), in: .capsule)
                            .glassEffectID("countdown", in: glass)
                            .glassEffectTransition(.matchedGeometry)
                    }
                    cupButton
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(
            .clear.tint(manager.isActive ? activeTint.opacity(0.18) : nil).interactive(),
            in: .rect(cornerRadius: 12)
        )
    }

    private var cupButton: some View {
        Button(action: manager.toggle) {
            Image(systemName: manager.isActive ? "cup.and.heat.waves.fill" : "cup.and.saucer")
                .font(.system(size: 15, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .contentTransition(.symbolEffect(.replace))
                // Rising steam while active.
                .symbolEffect(.variableColor.iterative.reversing, isActive: manager.isActive)
                .symbolEffect(.wiggle, value: cupHoverCount)
                .frame(width: 32, height: 32)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular.tint(manager.isActive ? .brown : cupHovered ? .accentColor.opacity(0.6) : nil).interactive(),
            in: .circle
        )
        .glassEffectID("cup", in: glass)
        .accessibilityLabel(manager.isActive ? "Allow Sleep" : "Prevent Sleep")
        .help(manager.isActive ? "Click to allow sleep" : "Click to prevent sleep")
        .overlay { progressRing }
        .scaleEffect(cupHovered && !reduceMotion ? 1.1 : 1)
        .animation(.spring(duration: 0.3, bounce: 0.5), value: cupHovered)
        .onHover { hovering in
            cupHovered = hovering
            if hovering { cupHoverCount += 1 }
        }
        .pointerStyle(.link)
    }

    @ViewBuilder
    private var progressRing: some View {
        if showProgressRing,
           let remaining = manager.timeRemaining,
           let total = manager.timerDuration, total > 0 {
            let elapsed = CGFloat(total - remaining) / CGFloat(total)
            Circle()
                .trim(from: 0, to: elapsed)
                .stroke(activeTint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .shadow(color: activeTint.opacity(0.9), radius: 3)
                .rotationEffect(.degrees(-90))
                .padding(-3)
                .opacity(elapsed > 0 ? 1 : 0)
                .animation(.linear(duration: 1), value: remaining)
                .allowsHitTesting(false)
        }
    }

    private var statusText: String {
        guard manager.isActive else { return "System can sleep normally" }
        guard let r = manager.timeRemaining else { return "Active" }
        let end = Date.now.addingTimeInterval(TimeInterval(r))
        return "Active · until \(end.formatted(date: .omitted, time: .shortened))"
    }

    private func compactTime(_ seconds: Int) -> String {
        let units: Set<Duration.UnitsFormatStyle.Unit> = seconds >= 3600 ? [.hours, .minutes] : [.minutes, .seconds]
        return Duration.seconds(seconds).formatted(
            .units(allowed: units, width: .narrow, fractionalPart: .hide(rounded: .down))
        )
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        // Spacing wider than the gaps lets neighbouring buttons melt together and mix their colours.
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 4) {
                ForEach(CaffeineMode.allCases) { mode in
                    let isSelected = manager.modes.contains(mode)
                    Button {
                        if manager.isActive { manager.stop() }
                        if isSelected {
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
                                Text(mode.title)
                                    .font(.system(size: 11))
                                Text(mode.subtitle)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .tint(isSelected ? mode.tint : nil)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label(for: manager.timerDuration))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(manager.timerDuration != nil ? .primary : .secondary)
            Slider(value: sliderValue, in: 300...Double(indefinite), step: 300) {
                Text("Duration")
            } minimumValueLabel: {
                Text(label(for: 300))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text(label(for: nil))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .labelsHidden()
            .accessibilityValue(label(for: manager.timerDuration))
            GlassEffectContainer(spacing: 4) {
                HStack(spacing: 0) {
                    ForEach(durationPresets, id: \.self) { seconds in
                        let isSelected = manager.timerDuration == seconds
                        Button { setDuration(seconds) } label: {
                            Text(label(for: seconds))
                                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background {
                                    if isSelected {
                                        Color.clear
                                            .glassEffect(.regular.tint(.accentColor).interactive(), in: .capsule)
                                            .glassEffectID("presetSelection", in: glass)
                                    }
                                }
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(2)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
        .animation(.spring(duration: 0.35, bounce: 0.3), value: manager.timerDuration)
    }

    private var sliderValue: Binding<Double> {
        Binding(
            get: { Double(manager.timerDuration ?? indefinite) },
            set: { setDuration($0 < Double(indefinite) ? Int($0) : nil) }
        )
    }

    private func setDuration(_ seconds: Int?) {
        guard seconds != manager.timerDuration else { return }
        if manager.isActive { manager.stop() }
        manager.timerDuration = seconds
    }

    private func label(for seconds: Int?) -> String {
        guard let seconds else { return "∞" }
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Settings", systemImage: "gearshape") { showSettings.toggle() }
                .buttonStyle(.glass)
                .tint(showSettings ? .accentColor : nil)
                .help("Settings")
                .popover(isPresented: $showSettings) { SettingsView() }
            Spacer()
            Button("Quit Caffeinate", systemImage: "power") { NSApp.terminate(nil) }
                .buttonStyle(.glass)
                .help("Quit Caffeinate")
        }
        .labelStyle(.iconOnly)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }
}

// MARK: - Mode Glow

/// A soft, slowly drifting blend of the selected modes' colours for the glass above to bend and mix.
private struct ModeGlow: View {
    var colors: [Color]
    var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * (isActive ? 0.6 : 0.25)
            MeshGradient(width: 3, height: 3, points: points(at: t), colors: meshColors)
        }
        .opacity(isActive ? 0.55 : 0.25)
        .animation(.easeInOut(duration: 0.6), value: isActive)
        .animation(.easeInOut(duration: 0.6), value: colors)
        .allowsHitTesting(false)
    }

    private var meshColors: [Color] {
        let palette = colors.isEmpty ? [Color.accentColor] : colors
        return (0..<9).map { palette[$0 % palette.count].opacity($0.isMultiple(of: 2) ? 1 : 0.35) }
    }

    private func points(at t: Double) -> [SIMD2<Float>] {
        func drift(_ speed: Double, _ amount: Float) -> Float { 0.5 + amount * Float(sin(t * speed)) }
        return [
            [0, 0], [drift(1.0, 0.2), 0], [1, 0],
            [0, drift(0.8, 0.2)], [drift(1.3, 0.25), drift(0.9, 0.25)], [1, drift(1.1, 0.2)],
            [0, 1], [drift(0.7, 0.2), 1], [1, 1],
        ]
    }
}
