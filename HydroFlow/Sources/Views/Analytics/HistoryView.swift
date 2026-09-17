import SwiftUI

/// Full history list: every logged entry, grouped by calendar day with
/// per-day totals, swipe-to-delete, and a summary header.
struct HistoryView: View {
    @EnvironmentObject var store: HydrationStore

    var body: some View {
        Group {
            if store.entries.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Theme.canvas)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }

    private var list: some View {
        List {
            ForEach(groupedDays, id: \.key) { day in
                Section {
                    ForEach(day.entries.sorted { $0.date > $1.date }) { entry in
                        EditableEntryRow(entry: entry, unit: store.profile.unit) {
                            store.deleteEntry(entry)
                            HealthKitManager.shared.deleteEntry(entry)
                        }
                    }
                } header: {
                    HStack {
                        Text("\(day.key, formatter: Self.dayFormatter)")
                        Spacer()
                        Text("\(Int(store.profile.unit.value(fromML: day.total).rounded())) \(store.profile.unit.symbol)")
                            .foregroundStyle(Theme.brandPrimary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.azure.opacity(0.4))
            Text("No Hydration History Yet")
                .font(FlowFont.headline)
            Text("Every sip you log will appear here so you can spot patterns and keep your streak alive.")
                .font(FlowFont.subhead)
                .foregroundStyle(Theme.labelSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Entries bucketed by calendar day, newest first, with per-day totals.
    private var groupedDays: [(key: Date, entries: [WaterEntry], total: Double)] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: store.entries) { calendar.startOfDay(for: $0.date) }
        return dict
            .map { (key: $0.key, entries: $0.value, total: $0.value.reduce(0) { $0 + $1.hydrationML }) }
            .sorted { $0.key > $1.key }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}

/// Entry row with swipe/menu delete wired to store + HealthKit cleanup.
private struct EditableEntryRow: View {
    let entry: WaterEntry
    let unit: VolumeUnit
    let onDelete: () -> Void

    var body: some View {
        EntryRow(entry: entry, unit: unit, onDelete: onDelete)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Theme.card)
            .listRowSeparator(.hidden)
    }
}
