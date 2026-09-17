import SwiftUI

/// The dashboard centerpiece: a liquid-filled glass orb whose fill level
/// mirrors daily progress, with animated waves, rising bubbles, and a
/// specular highlight — recreating the "Apple Liquid Glass" mockup.
struct HydrationOrbView: View {

    /// 0.0 – 1.0+ daily progress.
    let progress: Double
    let currentML: Double
    let goalML: Double
    let unit: VolumeUnit

    @State private var animateIn = false

    // Wave phase driven by TimelineView for buttery 60 fps.
    private let waveDateStart = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSince(waveDateStart)

            ZStack {
                // Outer progress ring (thin, gradient, rounded caps).
                Circle()
                    .stroke(Theme.azure.opacity(0.12), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 240, height: 240)
                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(
                        AngularGradient(
                            colors: [Theme.azure, Theme.aqua],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.9, dampingFraction: 0.85), value: progress)
                    .shadow(color: Theme.azure.opacity(0.4), radius: 6)

                // Glass orb body.
                ZStack {
                    Circle().fill(Color.white.opacity(0.75))

                    // Liquid clipped to the sphere.
                    LiquidShape(phase: t, progress: animateIn ? min(progress, 1) : 0)
                        .fill(Theme.liquidGradient)
                        .animation(.spring(response: 1.1, dampingFraction: 0.8), value: animateIn)
                        .animation(.spring(response: 1.1, dampingFraction: 0.8), value: progress)

                    // Caustic glow at the liquid base.
                    RadialGradient(
                        colors: [Color.white.opacity(0.35), .clear],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 110
                    )
                    .opacity(0.5)

                    // Rising bubbles.
                    BubblesView(phase: t)

                    // Specular dome highlight (top-left glass sheen).
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.85), .white.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: 150, height: 70)
                        .rotationEffect(.degrees(-18))
                        .offset(x: -32, y: -74)

                    // Rim sheen.
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.95), .white.opacity(0.15), .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                }
                .frame(width: 214, height: 214)
                .shadow(color: Theme.azure.opacity(0.35), radius: 22, y: 12)
                .overlay(
                    // Soft ambient glow behind the orb.
                    Circle()
                        .fill(RadialGradient(colors: [Theme.aqua.opacity(0.28), .clear],
                                             center: .center, startRadius: 60, endRadius: 130))
                        .frame(width: 280, height: 280)
                        .offset(y: 8)
                        .allowsHitTesting(false)
                )

                // Center readout.
                VStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.azure)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.ultraThinMaterial))

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(unit.value(fromML: currentML), specifier: "%.0f")")
                            .font(FlowFont.display(42))
                            .contentTransition(.numericText())
                            .monospacedDigit()
                        Text(unit.symbol)
                            .font(FlowFont.headline(18))
                            .foregroundStyle(Theme.labelSecondary)
                    }

                    HStack(spacing: 6) {
                        Text("Goal: \(unit.value(fromML: goalML), specifier: "%.0f") \(unit.symbol)")
                            .font(FlowFont.subhead)
                            .fontWeight(.semibold)
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(FlowFont.caption(12))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.azure))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                }
            }
            .onAppear {
                animateIn = true
            }
        }
    }
}

// MARK: - Liquid shape

/// Wave-topped liquid rectangle. `progress` sets the surface height;
/// `phase` animates two overlapping sine waves moving in opposite directions.
struct LiquidShape: Shape {
    let phase: Double
    let progress: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let maxY = Double(rect.maxY)
        let maxX = Double(rect.maxX)
        let height = Double(rect.height)
        let level = maxY - height * progress

        p.move(to: CGPoint(x: 0, y: level))

        // Front wave (slower, bigger amplitude).
        let step = 6.0
        var x = 0.0
        while x <= maxX {
            let rel = x / maxX
            let y = level + sin(rel * .pi * 2.2 + phase * 1.4) * 5.5
            p.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        p.addLine(to: CGPoint(x: maxX, y: maxY))
        p.addLine(to: CGPoint(x: 0, y: maxY))
        p.closeSubpath()
        return p
    }

    // Animate the fill-level smoothly when progress changes.
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
}

// MARK: - Bubbles

/// Three staggered bubbles rising inside the orb, phase-driven.
struct BubblesView: View {
    let phase: Double

    var body: some View {
        GeometryReader { geo in
            let w = Double(geo.size.width)
            let h = Double(geo.size.height)
            ForEach(0..<3, id: \.self) { i in
                let cycle = 4.0 + Double(i) * 0.9
                let t = (phase.truncatingRemainder(dividingBy: cycle)) / cycle
                let rise = (1 - t) * h * 0.55
                let x = w * (0.32 + 0.18 * Double(i)) + sin(t * 7 + Double(i)) * 6
                let scale = 0.55 + t * 0.5
                let opacity = sin(t * .pi) * 0.85

                Circle()
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 5 + CGFloat(i) * 2.5)
                    .scaleEffect(scale)
                    .position(x: CGFloat(x), y: CGFloat(h * 0.82 - rise))
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    HydrationOrbView(progress: 0.4, currentML: 1064, goalML: 2660, unit: .fluidOunces)
        .padding()
        .background(Theme.canvas)
}
