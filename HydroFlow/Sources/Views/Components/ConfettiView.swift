import SwiftUI

/// Full-screen confetti burst shown when the daily goal is reached.
///
/// Uses TimelineView + Canvas for GPU-friendly particles (no per-frame SwiftUI
/// state churn). Auto-fades after ~2.6 s.
struct ConfettiView: View {

    struct Particle: Identifiable {
        let id: Int
        let x: Double          // normalized 0...1 start position
        let delay: Double
        let speed: Double
        let spin: Double
        let size: Double
        let color: Color
        let sway: Double
    }

    let particles: [Particle]
    let startedAt: Date

    init(startedAt: Date = Date()) {
        self.startedAt = startedAt
        var rng = SystemRandomNumberGenerator()
        particles = (0..<90).map { i in
            Particle(
                id: i,
                x: Double.random(in: 0.05...0.95, using: &rng),
                delay: Double.random(in: 0...0.5, using: &rng),
                speed: Double.random(in: 1.6...3.0, using: &rng),
                spin: Double.random(in: -4...4, using: &rng),
                size: Double.random(in: 6...11, using: &rng),
                color: [Theme.azure, Theme.aqua, Theme.indigo, Color.yellow, Color.pink, Color.mint].randomElement()!,
                sway: Double.random(in: 18...45, using: &rng)
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startedAt)
                guard elapsed < 2.6 else { return }

                let width = Double(size.width)
                let height = Double(size.height)

                for p in particles {
                    let t = max(0, elapsed - p.delay)
                    guard t > 0 else { continue }

                    let progress = t / p.speed
                    let y = progress * (height + 40) - 30
                    let x = p.x * width + sin(progress * 6) * p.sway

                    // Fade out near the end.
                    let alpha = max(0, 1 - progress * 0.55)
                    guard alpha > 0 else { continue }

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(p.spin * progress))

                    let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size * 0.6)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(p.color.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Modifier

/// Attach to the root: observes the store and triggers confetti + haptics
/// the moment today's goal is crossed.
struct GoalCelebrationModifier: ViewModifier {
    @EnvironmentObject var store: HydrationStore
    @State private var celebrationStart: Date?
    @State private var wasGoalMet = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if let start = celebrationStart {
                    ConfettiView(startedAt: start)
                        .transition(.opacity)
                }
            }
            .onChange(of: store.todayProgress) { _, newValue in
                let met = newValue >= 1.0
                if met && !wasGoalMet {
                    celebrationStart = Date()
                    Feedback.goalReached(enabled: store.reminderSettings.hapticsEnabled)
                    // Keep the layer alive briefly, then drop it.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            celebrationStart = nil
                        }
                    }
                }
                wasGoalMet = met
            }
    }
}
