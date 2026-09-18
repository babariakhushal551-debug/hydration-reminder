import SwiftUI

/// Modal "Log Hydration" sheet: custom volume stepper with an animated liquid
/// gauge, preset chips, and the grouped beverage list with hydration indexes.
struct LogDrinkSheet: View {
    @EnvironmentObject var store: HydrationStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBeverage: BeverageType = .water
    @State private var volumeML: Double = 240
    @State private var justLogged = false

    /// Preset volumes (ml) matching the mockup chips: 4/8/12/16/24/32 oz.
    private static let presetsML: [Double] = [120, 240, 355, 473, 710, 950]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    volumeCard
                    beverageSection
                }
                .padding(.horizontal, .margin)
                .padding(.bottom, 110)
            }
            .background(Theme.canvas)
            .safeAreaInset(edge: .bottom) {
                logButton
            }
            .navigationTitle("Log Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.brandPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.brandPrimary)
                }
            }
            .onAppear {
                // Preset the sheet to the last beverage for fast repeat logging.
                // Volume is clamped to the current bottle capacity so a huge
                // previous drink can't overflow the (possibly smaller) bottle.
                if let last = store.lastEntry {
                    selectedBeverage = last.beverage
                    volumeML = min(last.volumeML, store.pourBottleMaxML)
                }
            }
        }
    }

    // MARK: - Volume card

    private var volumeCard: some View {
        FlowCard {
            VStack(spacing: 12) {
                HStack {
                    Text("TARGET INTAKE")
                        .font(FlowFont.subhead(12))
                        .fontWeight(.semibold)
                        .tracking(0.6)
                        .foregroundStyle(Theme.labelSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                        Text("Real-time Fluid")
                            .font(FlowFont.caption())
                    }
                    .foregroundStyle(Theme.brandPrimary)
                }

                // Bottle-capacity row: tap −/+ to resize the bottle. Kept on
                // its own line so small phones never overflow horizontally.
                HStack {
                    Text("Bottle size")
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelTertiary)
                    Spacer()
                    HStack(spacing: 6) {
                        Button {
                            Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                store.pourBottleMaxML = min(max((store.pourBottleMaxML - 100).rounded(), 150), 3800)
                                if volumeML > store.pourBottleMaxML { volumeML = store.pourBottleMaxML }
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.labelSecondary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Theme.azure.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Decrease bottle capacity")

                        Text("\(Int(store.pourBottleMaxML.rounded())) ml")
                            .font(FlowFont.caption())
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.brandPrimary)
                            .monospacedDigit()

                        Button {
                            Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                store.pourBottleMaxML = min(max((store.pourBottleMaxML + 100).rounded(), 150), 3800)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.brandPrimary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Theme.azure.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Increase bottle capacity")
                    }
                }

                HStack(spacing: 14) {
                    // Interactive bottle: slide the water level to set the amount.
                    // Capacity is user-configurable (bottle-size stepper above).
                    PourBottlePicker(
                        volumeML: $volumeML,
                        maxML: store.pourBottleMaxML,
                        tint: color(for: selectedBeverage.tint),
                        unit: unit,
                        hapticsEnabled: store.reminderSettings.hapticsEnabled
                    )

                    // Fine-tune steppers stacked beside the bottle.
                    VStack(spacing: 14) {
                        stepperButton(systemName: "plus") {
                            changeVolume(by: unitStep)
                        }
                        VStack(spacing: 2) {
                            Text("\(Int(volumeDisplayValue.rounded()))")
                                .font(.system(size: 30, weight: .bold, ))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                            Text(unit.symbol)
                                .font(FlowFont.bodyBold())
                                .foregroundStyle(Theme.labelSecondary)
                            Text(mlCaption)
                                .font(FlowFont.caption())
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.brandPrimary)
                        }
                        .frame(minWidth: 64)
                        stepperButton(systemName: "minus") {
                            changeVolume(by: -unitStep)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)

                // Preset chips row (4/8/12/16/24/32 oz).
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.presetsML, id: \.self) { preset in
                            let display = Int(unit.value(fromML: preset).rounded())
                            Button {
                                Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    volumeML = preset
                                }
                            } label: {
                                Text("\(display) \(unit.symbol)")
                                    .font(FlowFont.subhead())
                                    .fontWeight(isPresetChipSelected && abs(volumeML - preset) < 1 ? .bold : .medium)
                                    .foregroundStyle(isPresetChipSelected && abs(volumeML - preset) < 1 ? .white : Theme.labelSecondary)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(isPresetChipSelected && abs(volumeML - preset) < 1 ? AnyShapeStyle(Theme.azure) : AnyShapeStyle(Theme.azure.opacity(0.06)))
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(
                                            isPresetChipSelected && abs(volumeML - preset) < 1 ? AnyShapeStyle(Theme.azure.opacity(0.25)) : AnyShapeStyle(Theme.azure.opacity(0.16)),
                                            lineWidth: 0.5
                                        )
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Beverage list

    private var beverageSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("BEVERAGE TYPE")
                    .font(FlowFont.subhead(12))
                    .fontWeight(.semibold)
                    .tracking(0.6)
                    .foregroundStyle(Theme.labelSecondary)
                Spacer()
                Text("Hydration Index")
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.brandPrimary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(BeverageType.allCases.enumerated()), id: \.element) { index, beverage in
                    Button {
                        Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedBeverage = beverage
                            volumeML = beverage.presetML
                            justLogged = false
                        }
                    } label: {
                        beverageRow(beverage)
                    }
                    .buttonStyle(.plain)

                    if index < BeverageType.allCases.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: .cardRadius, style: .continuous).fill(Theme.card))
            .overlay(
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                    .strokeBorder(Theme.hairline.opacity(0.5), lineWidth: 0.5)
            )
        }
    }

    private func beverageRow(_ beverage: BeverageType) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: beverage.symbolName, tint: color(for: beverage.tint), size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(beverage.displayName)
                    .font(FlowFont.bodyBold())
                    .foregroundStyle(Theme.labelPrimary)
                HStack(spacing: 6) {
                    Text("\(Int(beverage.hydrationFactor * 100))% hydration")
                        .font(FlowFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(color(for: beverage.tint))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(color(for: beverage.tint).opacity(0.10)))
                    if beverage == .custom {
                        Text("Manual oz & factor")
                            .font(FlowFont.caption())
                            .foregroundStyle(Theme.labelTertiary)
                    } else {
                        Text("\(beverage.presetText(unit: unit)) preset")
                            .font(FlowFont.caption())
                            .foregroundStyle(Theme.labelTertiary)
                    }
                }
            }

            Spacer()

            if selectedBeverage == beverage {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.azure)
            } else {
                Image(systemName: beverage == .custom ? "plus.circle" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.labelTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(selectedBeverage == beverage ? Theme.azure.opacity(0.06) : .clear)
        .contentShape(Rectangle())
    }

    // MARK: - CTA

    private var logButton: some View {
        VStack(spacing: 10) {
            Button {
                log()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: justLogged ? "checkmark" : "drop.fill")
                        .font(.system(size: 17, weight: .bold))
                    Text(justLogged ? "Logged!" : "Log \(volumeButtonText)")
                        .font(FlowFont.headlineSmall())
                        .fixedSize(horizontal: true, vertical: false)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(justLogged ? AnyShapeStyle(Theme.success) : AnyShapeStyle(Theme.flowGradient)))
                .shadow(color: Theme.azure.opacity(0.35), radius: 14, y: 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .scaleEffect(justLogged ? 0.97 : 1)

            // Home-indicator style handle.
            Capsule()
                .fill(Theme.labelTertiary.opacity(0.5))
                .frame(width: 120, height: 4)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, .margin)
        .padding(.top, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Logic

    private var unit: VolumeUnit { store.profile.unit }

    private var unitStep: Double {
        unit == .fluidOunces ? VolumeUnit.mlPerOz : 50
    }

    private var volumeDisplayValue: Double {
        unit.value(fromML: volumeML)
    }

    private var mlCaption: String { "\(Int(volumeML.rounded())) ml" }

    /// True when the selected beverage matches the last logged one and the
    /// current volume equals its preset — used to keep the chip highlight stable.
    private var isPresetChipSelected: Bool {
        Self.presetsML.contains { abs($0 - volumeML) < 1 }
    }

    private var volumeButtonText: String {
        "\(Int(volumeDisplayValue.rounded())) \(unit.symbol) \(selectedBeverage.displayName)"
    }



    private func changeVolume(by deltaML: Double) {
        Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
        let clamped = min(max(volumeML + deltaML, 30), max(2000, store.pourBottleMaxML))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            volumeML = clamped
        }
    }

    /// Circular −/+ stepper button flanking the gauge.
    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.azure)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(Theme.azure.opacity(0.25), lineWidth: 0.5))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func log() {
        _ = store.logDrink(selectedBeverage, volumeML: volumeML, containerName: nil)
        Feedback.sipLogged(enabled: store.reminderSettings.hapticsEnabled)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            justLogged = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            dismiss()
        }
    }
}

// MARK: - Helpers

private func color(for tint: String) -> Color {
    switch tint {
    case "azure": Theme.azure
    case "aqua": Theme.aqua
    case "indigo": Theme.indigo
    case "orange": .orange
    case "violet": .purple
    default: Theme.azure
    }
}
