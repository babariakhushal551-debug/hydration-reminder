import WidgetKit
import SwiftUI

// MARK: - Timeline provider

/// Loads the latest snapshot written by the main app into the App Group.
struct HydroFlowProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydroFlowEntry {
        .demo
    }

    func getSnapshot(in context: Context, completion: @escaping (HydroFlowEntry) -> Void) {
        completion(entryFromDisk() ?? .demo)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydroFlowEntry>) -> Void) {
        // Current state now, plus a refresh nudged hourly (the app also
        // triggers WidgetCenter reloads on every log).
        let entry = entryFromDisk() ?? .demo
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func entryFromDisk() -> HydroFlowEntry? {
        WidgetPublisher.read().map { HydroFlowEntry(snapshot: $0) }
    }
}

struct HydroFlowEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot

    init(snapshot: WidgetSnapshot, date: Date = Date()) {
        self.date = date
        self.snapshot = snapshot
    }

    static let demo = HydroFlowEntry(
        snapshot: WidgetSnapshot(currentML: 1200, goalML: 2660,
                                 unitSymbol: "oz", streak: 6, updated: Date())
    )
}

// MARK: - Widget declaration

struct HydroFlowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HydroFlowBottleWidget", provider: HydroFlowProvider()) { entry in
            HydroFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("HydroFlow Bottle")
        .description("Your daily water fill — live from the HydroFlow app.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Entry view (family router)

struct HydroFlowWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HydroFlowEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumBottleView(snapshot: entry.snapshot)
        case .accessoryCircular:
            AccessoryRingView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            AccessoryRowView(snapshot: entry.snapshot)
        default:
            SmallBottleView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Small: mini bottle + percent

private struct SmallBottleView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                if snapshot.streak > 0 {
                    Text("🔥\(snapshot.streak)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(red: 0, green: 0.48, blue: 1)))

            WidgetBottle(progress: snapshot.progress)
                .frame(width: 46, height: 92)

            VStack(spacing: 0) {
                Text(snapshot.displayText())
                    .font(.system(size: 14, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                Text("of \(snapshot.goalText())")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetBackground()
    }
}

// MARK: - Medium: bottle + stats + progress bar

private struct MediumBottleView: View {
    let snapshot: WidgetSnapshot

    private var pct: Int { Int((snapshot.progress * 100).rounded()) }

    var body: some View {
        HStack(spacing: 14) {
            WidgetBottle(progress: snapshot.progress)
                .frame(width: 52, height: 104)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0, green: 0.48, blue: 1))
                    Text("HydroFlow")
                        .font(.system(size: 12, weight: .heavy))
                    if snapshot.streak > 0 {
                        Text("🔥 \(snapshot.streak)d")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                            .foregroundStyle(.orange)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(snapshot.displayText())
                        .font(.system(size: 26, weight: .heavy))
                        .monospacedDigit()
                    Text("/ \(snapshot.goalText())")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(red: 0, green: 0.48, blue: 1).opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 0, green: 0.48, blue: 1),
                                                          Color(red: 0, green: 0.78, blue: 0.75)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * snapshot.progress)
                    }
                }
                .frame(height: 8)

                Text(pct >= 100 ? "Goal complete! 🎉" : "\(pct)% — keep sipping 💧")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(pct >= 100 ? Color(red: 0.1, green: 0.68, blue: 0.35) : .secondary)
            }
        }
        .padding(4)
        .widgetBackground()
    }
}

// MARK: - Lock screen: ring

private struct AccessoryRingView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 5)
            Circle()
                .trim(from: 0, to: snapshot.progress)
                .stroke(
                    LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("\(Int((snapshot.progress * 100).rounded()))%")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
        }
        .padding(4)
        .widgetBackground()
    }
}

// MARK: - Lock screen: row

private struct AccessoryRowView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("HydroFlow")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.cyan)

            Text("\(snapshot.displayText()) / \(snapshot.goalText())")
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()

            if snapshot.streak > 0 {
                Text("🔥 \(snapshot.streak)-day streak")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetBackground()
    }
}

// MARK: - The mini bottle

/// Bottle silhouette + fill clipped inside, drawn entirely with SwiftUI
/// shapes so the widget needs no asset catalog.
struct WidgetBottle: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Cap.
                RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.93, blue: 1),
                                                  Color(red: 0.72, green: 0.85, blue: 1)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.44, height: h * 0.085)
                    .position(x: w / 2, y: h * 0.045)

                // Body outline (neck flows into straight walls).
                WidgetBottleShape()
                    .fill(Color.white.opacity(0.55))

                // Liquid fill, clipped.
                WidgetBottleShape()
                    .fill(Color.clear)
                    .overlay(
                        Rectangle()
                            .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.74, blue: 0.97),
                                                          Color(red: 0.01, green: 0.52, blue: 0.78),
                                                          Color(red: 0.11, green: 0.31, blue: 0.85)],
                                                 startPoint: .top, endPoint: .bottom))
                            .mask(
                                GeometryReader { _ in
                                    // Fill rises from the bottom.
                                    Rectangle()
                                        .frame(height: max(0, h * 0.915 * progress))
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                }
                            )
                    )
                    .clipShape(WidgetBottleShape())

                // Shine.
                WidgetBottleShape()
                    .stroke(LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.45)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: w * 0.055)
            }
        }
        .accessibilityLabel("Hydration bottle, \(Int(progress * 100)) percent full")
    }
}

/// Simple bottle path: narrow neck at top, shoulder curve, straight body,
/// rounded base. Normalized to the given rect.
struct WidgetBottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let neckHalf: CGFloat = w * 0.21
        let cx = rect.midX

        p.move(to: CGPoint(x: cx - neckHalf, y: h * 0.09))
        // Right side.
        p.addLine(to: CGPoint(x: cx + neckHalf, y: h * 0.09))
        p.addCurve(to: CGPoint(x: rect.maxX, y: h * 0.26),
                   control1: CGPoint(x: cx + neckHalf + (rect.maxX - cx - neckHalf) * 0.35, y: h * 0.10),
                   control2: CGPoint(x: rect.maxX, y: h * 0.16))
        p.addLine(to: CGPoint(x: rect.maxX, y: h * 0.92))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.16, y: h),
                       control: CGPoint(x: rect.maxX, y: h))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.16, y: h))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: h * 0.92),
                       control: CGPoint(x: rect.minX, y: h))
        p.addLine(to: CGPoint(x: rect.minX, y: h * 0.26))
        p.addCurve(to: CGPoint(x: cx - neckHalf, y: h * 0.09),
                   control1: CGPoint(x: rect.minX, y: h * 0.16),
                   control2: CGPoint(x: cx - neckHalf - (cx - neckHalf - rect.minX) * 0.35, y: h * 0.10))
        p.closeSubpath()
        return p
    }
}

// MARK: - Background (iOS 17 content margins safe)

extension View {
    /// iOS 17 requires widgets to use their container background; this keeps
    /// compatibility with both APIs.
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                Color(red: 0.98, green: 0.98, blue: 1.0)
            }
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    HydroFlowWidget()
} timeline: {
    HydroFlowEntry.demo
}
