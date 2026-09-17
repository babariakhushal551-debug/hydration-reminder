import Foundation
import Combine

/// Central persistence + state store.
///
/// All mutation flows through this object; heavy JSON I/O is dispatched to a
/// background queue while the UI keeps reading in-memory snapshots (@Published).
final class HydrationStore: ObservableObject {

    // MARK: - Published state

    @Published private(set) var entries: [WaterEntry] = []
    @Published var profile: UserProfile { didSet { scheduleSave() } }
    @Published var reminderSettings: ReminderSettings { didSet { scheduleSave() } }
    @Published var hasCompletedOnboarding: Bool { didSet { scheduleSave() } }

    /// Daily goal in milliliters, plus any weather bonus applied today.
    @Published private(set) var weatherBonusML: Double = 0

    // MARK: - Persistence

    private let queue = DispatchQueue(label: "com.hydroflow.store", qos: .utility)
    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private struct PersistedState: Codable {
        var entries: [WaterEntry]
        var profile: UserProfile
        var reminderSettings: ReminderSettings
        var hasCompletedOnboarding: Bool
        var schemaVersion: Int = 1
    }

    // MARK: - Init

    init(fileURL: URL? = nil, now: @escaping () -> Date = { Date() }) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? docs.appendingPathComponent("hydroflow_state.json")

        // Try to load synchronously so the first frame has data.
        if let data = try? Data(contentsOf: self.fileURL),
           let state = try? decoder.decode(PersistedState.self, from: data) {
            entries = state.entries
            profile = state.profile
            reminderSettings = state.reminderSettings
            hasCompletedOnboarding = state.hasCompletedOnboarding
        } else {
            profile = UserProfile()
            reminderSettings = ReminderSettings()
            hasCompletedOnboarding = false
        }

        refreshWeatherBonus(now: now())
    }

    // MARK: - Derived values

    /// Today's daily goal (profile goal + dynamic weather bonus if enabled).
    var dailyGoalML: Double {
        GoalCalculator.dailyGoalML(profile: profile) + weatherBonusML
    }

    /// Hydration credit logged so far today, in milliliters.
    var todayTotalML: Double {
        StatsEngine.totalML(on: Date(), from: entries)
    }

    /// Progress toward today's goal (0.0 – 1.0+).
    var todayProgress: Double {
        StatsEngine.progress(goalML: dailyGoalML, totalML: todayTotalML)
    }

    /// Current goal streak in days.
    var currentStreak: Int {
        StatsEngine.currentStreak(goalML: dailyGoalML, entries: entries)
    }

    /// Most recent entry, if any.
    var lastEntry: WaterEntry? {
        entries.max { $0.date < $1.date }
    }

    /// Today's entries sorted newest first.
    var todayEntriesNewestFirst: [WaterEntry] {
        StatsEngine.entries(on: Date(), from: entries).sorted { $0.date > $1.date }
    }

    // MARK: - Mutations

    /// Log a drink immediately. Returns the created entry.
    @discardableResult
    func logDrink(_ beverage: BeverageType, volumeML: Double, containerName: String? = nil, at date: Date = Date()) -> WaterEntry {
        let entry = WaterEntry(
            date: date,
            beverage: beverage,
            volumeML: volumeML,
            hydrationFactor: beverage.hydrationFactor,
            containerName: containerName
        )
        entries.append(entry)
        scheduleSave()
        objectWillChange.send()
        return entry
    }

    /// Delete an entry (swipe-to-delete in history).
    func deleteEntry(_ entry: WaterEntry) {
        entries.removeAll { $0.id == entry.id }
        scheduleSave()
    }

    /// Update an existing entry's volume (stepper edit).
    func updateEntry(_ entry: WaterEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        scheduleSave()
    }

    /// Complete onboarding with a filled profile.
    func completeOnboarding(profile: UserProfile) {
        self.profile = profile
        hasCompletedOnboarding = true
    }

    /// Clear all logged data but keep profile/settings.
    func resetHistory() {
        entries.removeAll()
        scheduleSave()
    }

    // MARK: - Weather adjustment

    /// Recompute the dynamic weather bonus for today (no-ops if disabled).
    /// Temperature is looked up by `WeatherProviding` when available.
    func refreshWeatherBonus(now: Date = Date(), temperatureCelsius: Double? = nil) {
        let temp = temperatureCelsius ?? WeatherProviding.cachedHighTemperature(now: now)
        guard reminderSettings.dynamicWeather else {
            weatherBonusML = 0
            return
        }
        weatherBonusML = GoalCalculator.weatherBonusML(temperatureCelsius: temp ?? 0, enabled: true)
    }

    // MARK: - Saving

    /// Cancels any pending debounced save and writes state synchronously.
    /// Used by tests and app background/lifecycle handlers.
    func flushSaves() {
        saveWorkItem?.cancel()
        performSave()
    }

    /// Debounced background save; coalesces rapid mutations (e.g. stepper spins).
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.performSave() }
        saveWorkItem = item
        queue.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    private func performSave() {
        let state = PersistedState(
            entries: entries,
            profile: profile,
            reminderSettings: reminderSettings,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
        guard let data = try? encoder.encode(state) else { return }
        // Atomic write prevents corruption if the app is killed mid-save.
        try? data.write(to: fileURL, options: .atomic)
    }
}
