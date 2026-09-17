import SwiftUI

/// Interactive bottle volume picker for the Log sheet: the user drags the
/// water level up/down inside a realistic bottle silhouette to choose the
/// amount. Fine-tune steppers and preset chips stay available alongside.
struct PourBottlePicker: View {

    /// Selected volume in milliliters (binding into the sheet state).
    @Binding var volumeML: Double

    /// The largest volume the bottle represents.
    var maxML: Double = 1000

    let tint: Color
    let unit: VolumeUnit
    let hapticsEnabled: Bool

    @State private var dragProgress: Double?

    private let bottleSize = CGSize(width: 132, height: 240)

    /// Progress 0...1 computed from the volume (drag overrides while active).
    private var progress: Double {
        min(max((dragProgress ?? (volumeML / maxML)), 0), 1)
    }

    var body: some View {
        ZStack {
            bottleBody

            // Gesture layer over the bottle.
            GeometryReader { geo in
                let height = geo.size.height

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Invert: top of bottle = full.
                                let y = value.location.y
                                let raw = min(max(1 - (y / height), 0), 1)
                                dragProgress = raw
                                if let ml = mlFor(progress: raw) {
                                    volumeML = ml
                                }
                                Feedback.tick(enabled: hapticsEnabled)
                            }
                            .onEnded { _ in
                                dragProgress = nil
                                Feedback.sipLogged(enabled: hapticsEnabled)
                            }
                    )
            }
        }
        .frame(width: bottleSize.width, height: bottleSize.height)
        .accessibilityElement()
        .accessibilityLabel("Water amount")
        .accessibilityValue("\(Int(unit.value(fromML: volumeML).rounded())) \(unit.symbol)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: volumeML = min(volumeML + step, 2000)
            case .decrement: volumeML = max(volumeML - step, 30)
            @unknown default: break
            }
        }
    }

    private var step: Double {
        unit == .fluidOunces ? VolumeUnit.mlPerOz : 50
    }

    // MARK: - Bottle rendering

    private var bottleBody: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Glass interior.
                RealisticBottleShape()
                    .fill(
                        LinearGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.55)],
                                       startPoint: .top, endPoint: .bottom)
                    )

                // Liquid level (dual wave), clipped to the bottle.
                RealisticBottleShape()
                    .fill(Color.clear)
                    .overlay(
                        ZStack {
                            LiquidLevelShape(progress: progress, phase: t * 0.7 + 1.3)
                                .fill(LinearGradient(colors: [tint.opacity(0.45), Theme.azure.opacity(0.55)],
                                                     startPoint: .top, endPoint: .bottom))
                                .blendMode(.plusLighter)
                            LiquidLevelShape(progress: progress, phase: t)
                                .fill(LinearGradient(colors: [tint.opacity(0.9), Theme.azure],
                                                     startPoint: .top, endPoint: .bottom))
                        }
                        .animation(dragProgress == nil ? .spring(response: 0.5, dampingFraction: 0.8) : nil,
                                   value: progress)
                    )
                    .clipShape(RealisticBottleShape())

                // Base glow.
                Ellipse()
                    .fill(RadialGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.0)],
                                         center: .center, startRadius: 2, endRadius: 48))
                    .frame(width: 92, height: 24)
                    .offset(y: 100)
                    .allowsHitTesting(false)

                // Left sheen.
                RoundedRectSrip()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                         startPoint: .leading, endPoint: .trailing))
                    .clipShape(RealisticBottleShape())
                    .allowsHitTesting(false)

                // Glass outline.
                RealisticBottleShape()
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.4)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .shadow(color: Theme.azure.opacity(0.2), radius: 6, y: 3)

                // Center volume readout bubble.
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(unit.value(fromML: volumeML).rounded()))")
                            .font(FlowFont.stat(30))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(unit.symbol)
                            .font(FlowFont.bodyBold())
                            .foregroundStyle(Theme.labelSecondary)
                    }
                    Text("\(Int(volumeML.rounded())) ml")
                        .font(FlowFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.brandPrimary)
                    Text("Drag to pour")
                        .font(FlowFont.caption(9))
                        .foregroundStyle(Theme.labelTertiary)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Mapping

    /// Convert a drag progress (0...1 of the bottle) to milliliters,
    /// snapping to the unit's natural step.
    private func mlFor(progress: Double) -> Double? {
        let rawML = progress * maxML
        let snapped = (rawML / step).rounded() * step
        let clamped = min(max(snapped, 30), 2000)
        return abs(clamped - volumeML) > 1 ? clamped : nil
    }
}

#Preview {
    PourBottlePicker(volumeML: .constant(355), tint: Theme.aqua, unit: .fluidOunces, hapticsEnabled: true)
        .padding()
        .background(Theme.canvas)
}
