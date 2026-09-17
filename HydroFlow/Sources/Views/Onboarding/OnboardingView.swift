import SwiftUI

/// Onboarding: name, weight, sex, physiological modifiers, activity, climate —
/// with a live-computed goal preview and the signature gradient CTA.
struct OnboardingView: View {
    @EnvironmentObject var store: HydrationStore

    @State private var name = ""
    @State private var weightKg: Double = 70
    @State private var sex: BiologicalSex = .female
    @State private var isPregnant = false
    @State private var isBreastfeeding = false
    @State private var activity: ActivityLevel = .moderate
    @State private var climate: Climate = .temperate
    @State private var unit: VolumeUnit = .fluidOunces
    @State private var showCelebration = false

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    nameCard
                    weightCard
                    sexCard
                    activityCard
                    climateCard
                    baselinePill
                }
                .padding(.horizontal, .margin)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }

            // Floating CTA dock.
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    Button {
                        finish()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Calculate Daily Goal")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Theme.flowGradient))
                        .shadow(color: Theme.azure.opacity(0.4), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("Stored locally & synced seamlessly with Apple Health")
                    }
                    .font(FlowFont.caption)
                    .foregroundStyle(Theme.labelTertiary)

                    Capsule()
                        .fill(Theme.labelTertiary.opacity(0.5))
                        .frame(width: 120, height: 4)
                }
                .padding(.horizontal, .margin)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas],
                                   startPoint: .top, endPoint: .bottom)
                )
            }
            .ignoresSafeArea(edges: .bottom)

            if showCelebration {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .statusBarHidden(false)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            // App icon built in-code (gradient droplet).
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.94, green: 0.98, blue: 1.0))
                    .frame(width: 80, height: 80)
                    .shadow(color: Theme.azure.opacity(0.25), radius: 16, y: 6)

                DropShape()
                    .fill(Theme.liquidGradient)
                    .frame(width: 44, height: 54)
            }
            .padding(.bottom, 4)

            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("SETUP JOURNEY")
                    .font(FlowFont.caption)
                    .fontWeight(.bold)
                    .tracking(0.8)
            }
            .foregroundStyle(Theme.brandPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Theme.azure.opacity(0.08)))

            Text("Welcome to HydroFlow")
                .font(FlowFont.headlineLarge)
            Text("Let's personalize your daily hydration target for optimal health & energy.")
                .font(FlowFont.body)
                .foregroundStyle(Theme.labelSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Form cards

    private var nameCard: some View {
        FlowCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("YOUR NAME")
                    .font(FlowFont.subhead(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.labelSecondary)
                TextField("Your Name", text: $name)
                    .font(FlowFont.bodyBold)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.canvas))
            }
        }
    }

    private var weightCard: some View {
        FlowCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CURRENT BODY WEIGHT")
                        .font(FlowFont.subhead(12))
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.labelSecondary)
                    Spacer()
                    // lbs / kg segmented picker.
                    HStack(spacing: 2) {
                        ForEach(VolumeUnit.allCases) { u in
                            Button {
                                Feedback.tick(enabled: true)
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    unit = u
                                }
                            } label: {
                                Text(u == .fluidOunces ? "lbs" : "kg")
                                    .font(FlowFont.caption(12))
                                    .fontWeight(.bold)
                                    .foregroundStyle(unit == u ? Theme.brandPrimary : Theme.labelSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(unit == u ? Theme.card : .clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.azure.opacity(0.07)))
                }

                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(displayWeight.rounded()))")
                            .font(FlowFont.stat(34))
                            .monospacedDigit()
                        Text(unit == .fluidOunces ? "lbs" : "kg")
                            .font(FlowFont.bodyBold)
                            .foregroundStyle(Theme.labelSecondary)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        stepperCircle("minus") { adjustWeight(-1) }
                        stepperCircle("plus") { adjustWeight(1) }
                    }
                }
            }
        }
    }

    private var sexCard: some View {
        FlowCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("BIOLOGICAL SEX")
                    .font(FlowFont.subhead(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.labelSecondary)

                // 3-way segmented selector.
                HStack(spacing: 6) {
                    ForEach(BiologicalSex.allCases) { s in
                        Button {
                            Feedback.tick(enabled: true)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { sex = s }
                        } label: {
                            Text(s.displayName)
                                .font(FlowFont.bodyBold)
                                .foregroundStyle(sex == s ? Theme.brandPrimary : Theme.labelSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(sex == s ? Theme.card : .clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(sex == s ? Color.black.opacity(0.04) : .clear, lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.azure.opacity(0.07)))

                // Physiological modifier pills.
                VStack(alignment: .leading, spacing: 8) {
                    Text("SPECIFIC PHYSIOLOGICAL MODIFIERS")
                        .font(FlowFont.caption(10))
                        .fontWeight(.semibold)
                        .tracking(0.6)
                        .foregroundStyle(Theme.labelTertiary)

                    HStack(spacing: 8) {
                        modifierPill(title: "Pregnant", systemImage: "figure.pregnant", isOn: $isPregnant)
                        modifierPill(title: "Breastfeeding (+700ml)", systemImage: "figure.and.child.holdinghands", isOn: $isBreastfeeding)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var activityCard: some View {
        FlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("DAILY ACTIVITY LEVEL")
                        .font(FlowFont.subhead(12))
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.labelSecondary)
                    Spacer()
                    Text(activitySubtitle)
                        .font(FlowFont.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.brandPrimary)
                }

                // 2×2 grid of level tiles.
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(ActivityLevel.allCases) { level in
                        Button {
                            Feedback.tick(enabled: true)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { activity = level }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(activity == level ? AnyShapeStyle(Theme.flowGradient) : AnyShapeStyle(Theme.azure.opacity(0.08)))
                                    Image(systemName: level.symbolName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(activity == level ? .white : Theme.labelSecondary)
                                }
                                .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(level.displayName)
                                        .font(FlowFont.bodyBold(14))
                                        .foregroundStyle(activity == level ? Theme.brandPrimary : Theme.labelPrimary)
                                    Text(level.subtitle)
                                        .font(FlowFont.caption(11))
                                        .foregroundStyle(activity == level ? Theme.azure.opacity(0.8) : Theme.labelTertiary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(activity == level ? Theme.azure.opacity(0.07) : Theme.canvas.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(activity == level ? Theme.azure : Theme.azure.opacity(0.12),
                                                  lineWidth: activity == level ? 1.6 : 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var climateCard: some View {
        FlowCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("REGIONAL CLIMATE")
                    .font(FlowFont.subhead(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.labelSecondary)

                // 4-way segmented picker.
                HStack(spacing: 4) {
                    ForEach(Climate.allCases) { c in
                        Button {
                            Feedback.tick(enabled: true)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { climate = c }
                        } label: {
                            Text(c.displayName)
                                .font(FlowFont.caption(12))
                                .fontWeight(climate == c ? .bold : .medium)
                                .foregroundStyle(climate == c ? Theme.brandPrimary : Theme.labelSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(climate == c ? Theme.card : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.azure.opacity(0.07)))
            }
        }
    }

    // MARK: - Baseline preview

    private var baselinePill: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.aqua)
            Text(baselineText)
                .font(FlowFont.subhead)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.aqua.opacity(0.12)))
        .overlay(Capsule().strokeBorder(Theme.aqua.opacity(0.3), lineWidth: 0.5))
    }

    // MARK: - Helpers

    /// Toggleable pill used for pregnancy / breastfeeding modifiers.
    private func modifierPill(title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Button {
            Feedback.tick(enabled: true)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { isOn.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : systemImage)
                    .font(.system(size: 14))
                Text(title)
                    .font(FlowFont.subhead)
                    .fontWeight(isOn.wrappedValue ? .bold : .medium)
            }
            .foregroundStyle(isOn.wrappedValue ? Theme.aqua : Theme.labelSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isOn.wrappedValue ? AnyShapeStyle(Theme.aqua.opacity(0.18)) : AnyShapeStyle(Theme.azure.opacity(0.06)))
            )
            .overlay(
                Capsule().strokeBorder(isOn.wrappedValue ? Theme.aqua : Theme.azure.opacity(0.15), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    /// The weight stepper adjusts in the display unit; storage stays metric.
    private var displayWeight: Double {
        unit == .fluidOunces ? weightKg * 2.20462 : weightKg
    }

    private func adjustWeight(_ direction: Double) {
        Feedback.tick(enabled: true)
        let stepKg = unit == .fluidOunces ? 0.4536 : 1.0
        weightKg = min(max(weightKg + direction * stepKg, 35), 200)
    }

    private var activitySubtitle: String {
        switch activity {
        case .sedentary: "~15 min/day"
        case .moderate: "~45 min/day"
        case .high: "~75 min/day"
        case .athlete: "2+ hrs/day"
        }
    }

    private var baselineText: String {
        let draft = UserProfile(
            name: name, weightKg: weightKg, sex: sex,
            isPregnant: isPregnant, isBreastfeeding: isBreastfeeding,
            activity: activity, climate: climate, unit: unit
        )
        return GoalCalculator.baselineText(profile: draft)
    }

    private func finish() {
        let profile = UserProfile(
            name: name, weightKg: weightKg, sex: sex,
            isPregnant: isPregnant, isBreastfeeding: isBreastfeeding,
            activity: activity, climate: climate, unit: unit
        )
        store.completeOnboarding(profile: profile)

        showCelebration = true
        Feedback.goalReached(enabled: true)

        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run { showCelebration = false }
        }
    }
}

// MARK: - Drop shape

/// Simple teardrop path used for the in-code app icon.
struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addCurve(
            to: CGPoint(x: 0, y: h * 0.62),
            control1: CGPoint(x: w / 2, y: 0),
            control2: CGPoint(x: 0, y: h * 0.3)
        )
        p.addArc(center: CGPoint(x: w / 2, y: h * 0.62), radius: w / 2,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.closeSubpath()
        return p
    }
}

#Preview {
    OnboardingView()
        .environmentObject(HydrationStore())
}
