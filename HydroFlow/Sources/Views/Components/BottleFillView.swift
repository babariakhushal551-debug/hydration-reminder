import SwiftUI

/// Water-bottle visualization used on the Today dashboard: a classic,
/// normal-looking bottle (ribbed cap, short neck, smooth shoulder, straight
/// cylinder walls, rounded base) that fills bottom-to-top with layered
/// animated waves, glass shine, base glow, and capacity ticks.
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
                    .frame(width: 150, height: 270)

                readout
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { animateIn = true }
        .onChange(of: progress) { _, _ in
            // Pulse the capacity label whenever a milestone is crossed.
            milestonePulse = true
            withAnimation(.easeOut(duration: 0.6)) { milestonePulse = false }
        }
    }

    // MARK: - Bottle

    private func bottle(t: Double) -> some View {
        let fill = animateIn ? min(max(progress, 0.02), 1) : 0.02

        return ZStack {
            // Glass interior.
            ClassicBottleShape()
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.55)],
                                   startPoint: .top, endPoint: .bottom)
                )

            // Liquid with dual-layer waves, clipped to the bottle.
            ClassicBottleShape()
                .fill(Color.clear)
                .overlay(
                    ZStack {
                        // Back wave (slower, offset phase).
                        LiquidLevelShape(progress: fill, phase: t * 0.7 + 1.3)
                            .fill(Theme.liquidGradient.opacity(0.55))
                            .blendMode(.plusLighter)

                        // Front wave (main body).
                        LiquidLevelShape(progress: fill, phase: t)
                            .fill(Theme.liquidGradient)
                    }
                    .animation(.spring(response: 0.9, dampingFraction: 0.82), value: fill)
                )
                .clipShape(ClassicBottleShape())

            // Caustic glow pooled at the base.
            Ellipse()
                .fill(
                    RadialGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                                   center: .center, startRadius: 2, endRadius: 55)
                )
                .frame(width: 110, height: 30)
                .offset(y: 112)
                .allowsHitTesting(false)

            // Left specular sheen.
            RoundedRectSrip()
                .fill(
                    LinearGradient(colors: [.white.opacity(0.60), .white.opacity(0.04)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(ClassicBottleShape())
                .allowsHitTesting(false)

            // Right thin counter-highlight.
            ClassicBottleShape()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                .blur(radius: 0.6)
                .allowsHitTesting(false)

            // Glass outline.
            ClassicBottleShape()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.40), .white.opacity(0.85)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3.5
                )
                .shadow(color: Theme.azure.opacity(0.25), radius: 8, y: 4)

            // Capacity ticks along the straight body.
            ForEach([0.25, 0.5, 0.75], id: \.self) { fraction in
                tickMark(fraction: fraction)
            }
        }
    }

    private func tickMark(fraction: Double) -> some View {
        let bottleHeight: CGFloat = 270
        // Straight wall spans ~0.30–0.96 of the shape height.
        let y = bottleHeight * (0.96 - 0.66 * fraction)
        return HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Theme.azure.opacity(0.35))
                .frame(width: 12, height: 2)
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Theme.azure.opacity(0.55))
        }
        .position(x: 28, y: y)
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

/// Classic water bottle: ribbed cap with rim, short tapered neck, smooth
/// shoulder into straight cylinder walls, rounded base. No grip waist and no
/// thread ridges — the normal bottle everyone pictures. Drawn in normalized
/// space (x: 0–1 across width, y: 0–1 down height).
struct ClassicBottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX

        // Key vertical stations (fractions of height).
        let capTop: CGFloat = 0.0
        let capBottom: CGFloat = 0.075       // ribbed cap block
        let neckTop: CGFloat = 0.075
        let neckBottom: CGFloat = 0.16       // short neck
        let shoulderBottom: CGFloat = 0.28   // shoulder curve out to body
        let wallBottom: CGFloat = 0.94       // straight cylinder wall

        let capHalf: CGFloat = w * 0.20
        let neckHalf: CGFloat = w * 0.22
        let bodyHalf: CGFloat = w * 0.48     // near-full-width straight body

        // ---- Cap: rounded-top block with rib hints ----
        let capRect = CGRect(x: cx - capHalf, y: h * capTop,
                             width: capHalf * 2, height: h * (capBottom - capTop))
        p.addRoundedRect(in: capRect, cornerSize: CGSize(width: capHalf * 0.3, height: capHalf * 0.3))
        for i in 1...3 {
            let ribY = h * capTop + h * (capBottom - capTop) * CGFloat(i) / 4
            p.move(to: CGPoint(x: cx - capHalf * 0.85, y: ribY))
            p.addLine(to: CGPoint(x: cx + capHalf * 0.85, y: ribY))
        }

        // ---- Neck under the cap with a slight outward rim ----
        p.move(to: CGPoint(x: cx + capHalf * 0.95, y: h * neckTop))
        p.addLine(to: CGPoint(x: cx + neckHalf, y: h * (neckTop + (neckBottom - neckTop) * 0.45)))
        p.addLine(to: CGPoint(x: cx + neckHalf, y: h * (neckTop + (neckBottom - neckTop) * 0.75)))

        // ---- Shoulder: smooth curve out to full body width ----
        p.addCurve(
            to: CGPoint(x: cx + bodyHalf, y: h * shoulderBottom),
            control1: CGPoint(x: cx + neckHalf + (bodyHalf - neckHalf) * 0.35, y: h * neckBottom),
            control2: CGPoint(x: cx + bodyHalf, y: h * (neckBottom + (shoulderBottom - neckBottom) * 0.5))
        )

        // ---- Straight cylinder walls ----
        p.addLine(to: CGPoint(x: cx + bodyHalf, y: h * wallBottom))

        // ---- Rounded base corners ----
        p.addQuadCurve(to: CGPoint(x: cx + bodyHalf * 0.72, y: h * 0.995),
                       control: CGPoint(x: cx + bodyHalf, y: h))
        p.addLine(to: CGPoint(x: cx - bodyHalf * 0.72, y: h * 0.995))
        p.addQuadCurve(to: CGPoint(x: cx - bodyHalf, y: h * wallBottom),
                       control: CGPoint(x: cx - bodyHalf, y: h))

        // ---- Left wall back up to the shoulder ----
        p.addLine(to: CGPoint(x: cx - bodyHalf, y: h * shoulderBottom))

        // ---- Left shoulder up to neck ----
        p.addCurve(
            to: CGPoint(x: cx - neckHalf, y: h * (neckTop + (neckBottom - neckTop) * 0.75)),
            control1: CGPoint(x: cx - bodyHalf, y: h * (neckBottom + (shoulderBottom - neckBottom) * 0.5)),
            control2: CGPoint(x: cx - neckHalf + (bodyHalf - neckHalf) * 0.35, y: h * neckBottom)
        )
        p.addLine(to: CGPoint(x: cx - capHalf * 0.95, y: h * neckTop))
        p.closeSubpath()
        return p
    }
}

/// Liquid fill inside the bottle: a wave-topped rectangle whose height maps
/// to progress, with the wave surface living in the straight body section.
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

        // Fill range mapped to the straight body (0.30 → 0.97 of height).
        let topFrac: CGFloat = 0.30
        let bottomFrac: CGFloat = 0.97
        let bodyTop = h * topFrac
        let bodyBottom = h * bottomFrac
        let level = bodyBottom - (bodyBottom - bodyTop) * CGFloat(min(max(progress, 0), 1))

        // Gentle dual-frequency wave.
        let amplitude = min((bodyBottom - bodyTop) * 0.045, 6)
        p.move(to: CGPoint(x: 0, y: level))
        var x: CGFloat = 0
        while x <= w {
            let rel = Double(x / w)
            let y = Double(level)
                + sin(rel * .pi * 2.2 + phase * 1.6) * amplitude
                + sin(rel * .pi * 4.6 - phase * 0.9) * amplitude * 0.35
            p.addLine(to: CGPoint(x: x, y: CGFloat(y)))
            x += 4
        }
        p.addLine(to: CGPoint(x: w, y: level))
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
                           y: rect.minY + rect.height * 0.30,
                           width: rect.width * 0.09,
                           height: rect.height * 0.56)
        p.addRoundedRect(in: strip, cornerSize: CGSize(width: strip.width / 2, height: strip.width / 2))
        return p
    }
}

#Preview {
    BottleFillView(progress: 0.45, currentML: 1200, goalML: 2660, unit: .fluidOunces)
        .padding()
        .background(Theme.canvas)
}
