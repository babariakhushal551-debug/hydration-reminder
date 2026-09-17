import SwiftUI

/// Water-bottle visualization used on the Today dashboard: a bottle-shaped
/// vessel that fills from bottom to top with animated waves as the user
/// drinks, replacing the previous orb-and-bubbles centerpiece.
struct BottleFillView: View {

    /// 0.0 – 1.0+ daily progress (clamped to 1 for the fill level).
    let progress: Double
    let currentML: Double
    let goalML: Double
    let unit: VolumeUnit

    @State private var animateIn = false
    @State private var milestonePulse = false

    // Wave phase driven by TimelineView for smooth 60 fps motion.
    private let waveStart = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSince(waveStart)

            HStack(spacing: 18) {
                bottle(t: t)
                    .frame(width: 150, height: 260)

                readout
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { animateIn = true }
        .onChange(of: progress) { _, newValue in
            // Pulse the capacity label whenever a quarter milestone is crossed.
            milestonePulse = true
            withAnimation(.easeOut(duration: 0.6)) { milestonePulse = false }
        }
    }

    // MARK: - Bottle

    private func bottle(t: Double) -> some View {
        ZStack {
            // Bottle outline (glass wall).
            BottleShape()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.35), .white.opacity(0.85)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 4
                )
                .shadow(color: Theme.azure.opacity(0.25), radius: 8, y: 4)

            // Glass interior.
            BottleShape()
                .fill(Color.white.opacity(0.55))

            // Liquid, clipped to the bottle interior.
            BottleShape()
                .fill(Color.white.opacity(0.001))
                .overlay(
                    LiquidLevelShape(progress: animateIn ? min(progress, 1) : 0, phase: t)
                        .fill(Theme.liquidGradient)
                        .animation(.spring(response: 1.0, dampingFraction: 0.82), value: animateIn)
                        .animation(.spring(response: 1.0, dampingFraction: 0.82), value: progress)
                )
                .clipShape(BottleShape())

            // Caustic glow at the liquid base.
            BottleShape()
                .fill(
                    LinearGradient(colors: [.clear, .white.opacity(0.22)],
                                   startPoint: .center, endPoint: .bottom)
                )
                .clipShape(BottleShape())
                .allowsHitTesting(false)

            // Specular highlight strip (left glass sheen).
            RoundedRectSrip()
                .fill(
                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(BottleShape())
                .allowsHitTesting(false)

            // Capacity tick marks (25% / 50% / 75%).
            ForEach([0.25, 0.5, 0.75], id: \.self) { frac in
                tickMark(fraction: frac)
            }
        }
    }

    private func tickMark(fraction: CGFloat) -> some View {
        let bottleHeight: CGFloat = 260
        // The straight wall section spans ~0.08–0.92 of the shape height.
        let y = bottleHeight * (0.92 - 0.84 * fraction)
        return HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Theme.azure.opacity(0.30))
                .frame(width: 12, height: 2)
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.azure.opacity(0.5))
        }
        .position(x: 26, y: y)
        .allowsHitTesting(false)
    }

    // MARK: - Readout

    private var readout: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(unit.value(fromML: currentML), specifier: "%.0f")")
                        .font(FlowFont.display(40))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(Theme.labelPrimary)
                    Text(unit.symbol)
                        .font(FlowFont.headline(17))
                        .foregroundStyle(Theme.labelSecondary)
                }
                Text("of \(unit.value(fromML: goalML), specifier: "%.0f") \(unit.symbol) goal")
                    .font(FlowFont.subhead())
                    .foregroundStyle(Theme.labelSecondary)
            }

            // Progress bar mirroring the bottle level.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.azure.opacity(0.12))
                    Capsule()
                        .fill(Theme.flowGradient)
                        .frame(width: geo.size.width * min(CGFloat(progress), 1))
                        .animation(.spring(response: 0.9, dampingFraction: 0.85), value: progress)
                }
            }
            .frame(width: 130, height: 8)

            HStack(spacing: 6) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(FlowFont.caption(12))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.azure))
                    .scaleEffect(milestonePulse ? 1.15 : 1)

                Image(systemName: progress >= 1 ? "checkmark.seal.fill" : "drop.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(progress >= 1 ? Theme.success : Theme.azure)
            }
        }
    }
}

// MARK: - Shapes

/// Bottle silhouette: neck at top, shoulders, straight body, rounded base.
/// Designed in a normalized 0...1 space and scaled to the given rect.
struct BottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // Proportions of the bottle (fractions of height).
        let capTop: CGFloat = 0.0
        let neckBottom: CGFloat = 0.14
        let shoulderTop: CGFloat = 0.14
        let shoulderBottom: CGFloat = 0.26

        let neckWidth: CGFloat = w * 0.42
        let bodyLeft = rect.minX
        let bodyRight = rect.maxX

        // Start at top-left of cap.
        p.move(to: CGPoint(x: w / 2 - neckWidth / 2, y: h * capTop))
        // Cap lip.
        p.addLine(to: CGPoint(x: w / 2 + neckWidth / 2, y: h * capTop))
        // Neck down to shoulder.
        p.addLine(to: CGPoint(x: w / 2 + neckWidth / 2, y: h * shoulderTop))
        // Shoulder curve out to body right.
        p.addCurve(
            to: CGPoint(x: bodyRight, y: h * shoulderBottom),
            control1: CGPoint(x: w / 2 + neckWidth / 2 + (bodyRight - w / 2 - neckWidth / 2) * 0.15, y: h * shoulderTop),
            control2: CGPoint(x: bodyRight, y: h * shoulderBottom - (h * (shoulderBottom - shoulderTop)) * 0.45)
        )
        // Right wall down to rounded base.
        p.addLine(to: CGPoint(x: bodyRight, y: h * 0.90))
        p.addQuadCurve(
            to: CGPoint(x: bodyRight - w * 0.18, y: h),
            control: CGPoint(x: bodyRight, y: h)
        )
        p.addLine(to: CGPoint(x: bodyLeft + w * 0.18, y: h))
        p.addQuadCurve(
            to: CGPoint(x: bodyLeft, y: h * 0.90),
            control: CGPoint(x: bodyLeft, y: h)
        )
        // Left wall up to left shoulder.
        p.addLine(to: CGPoint(x: bodyLeft, y: h * shoulderBottom))
        // Shoulder curve in to neck.
        p.addCurve(
            to: CGPoint(x: w / 2 - neckWidth / 2, y: h * shoulderTop),
            control1: CGPoint(x: bodyLeft, y: h * shoulderBottom - (h * (shoulderBottom - shoulderTop)) * 0.45),
            control2: CGPoint(x: w / 2 - neckWidth / 2 - (w / 2 - neckWidth / 2 - bodyLeft) * 0.15, y: h * shoulderTop)
        )
        // Neck up to cap.
        p.addLine(to: CGPoint(x: w / 2 - neckWidth / 2, y: h * capTop))
        p.closeSubpath()
        return p
    }
}

/// Liquid fill inside the bottle: a wave-topped rectangle whose height maps
/// to progress, with the wave surface inside the straight body section.
struct LiquidLevelShape: Shape {
    var progress: Double   // 0...1
    let phase: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // Fill range mapped to the straight body (0.26 → 0.98 of height),
        // so the wave lives on the straight walls, not the curved shoulder.
        let topFrac: CGFloat = 0.26
        let bottomFrac: CGFloat = 0.98
        let bodyTop = h * topFrac
        let bodyBottom = h * bottomFrac
        let level = bodyBottom - (bodyBottom - bodyTop) * CGFloat(min(max(progress, 0), 1))

        // Wave surface.
        let amplitude = min((bodyBottom - bodyTop) * 0.05, 6)
        p.move(to: CGPoint(x: 0, y: level))
        var x: CGFloat = 0
        while x <= w {
            let rel = Double(x / w)
            let y = Double(level) + sin(rel * .pi * 2.4 + phase * 1.5) * amplitude
            p.addLine(to: CGPoint(x: x, y: CGFloat(y)))
            x += 4
        }
        p.addLine(to: CGPoint(x: w, y: level))
        // Close down to the bottom (a bit beyond base rounding is fine —
        // the parent clips to the bottle shape).
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

/// Thin vertical strip used as the glass specular highlight.
struct RoundedRectSrip: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let strip = CGRect(x: rect.minX + rect.width * 0.10,
                           y: rect.minY + rect.height * 0.28,
                           width: rect.width * 0.10,
                           height: rect.height * 0.55)
        p.addRoundedRect(in: strip, cornerSize: CGSize(width: strip.width / 2, height: strip.width / 2))
        return p
    }
}

#Preview {
    BottleFillView(progress: 0.45, currentML: 1200, goalML: 2660, unit: .fluidOunces)
        .padding()
        .background(Theme.canvas)
}
