import XCTest
@testable import HydroFlow

final class HydroFlowTests: XCTestCase {

    // MARK: - GoalCalculator

    func testGoalForAverageFemale() {
        var p = UserProfile()
        p.sex = .female
        p.weightKg = 65
        p.activity = .moderate
        p.climate = .temperate
        let goal = GoalCalculator.dailyGoalML(profile: p)
        // Sanity window: 1.8 L – 3 L.
        XCTAssertEqual(goal, (goal / 50).rounded() * 50, "Goal should be rounded to 50 ml")
        XCTAssertTrue((1800...3000).contains(goal), "Female goal \(goal) out of range")
    }

    func testGoalForAverageMale() {
        var p = UserProfile()
        p.sex = .male
        p.weightKg = 80
        p.activity = .moderate
        p.climate = .temperate
        let goal = GoalCalculator.dailyGoalML(profile: p)
        XCTAssertTrue((2400...3600).contains(goal), "Male goal \(goal) out of range")
    }

    func testPregnancyAndBreastfeedingIncreaseGoal() {
        var base = UserProfile()
        base.sex = .female
        base.weightKg = 65

        var pregnant = base
        pregnant.isPregnant = true
        var breastfeeding = base
        breastfeeding.isBreastfeeding = true

        let baseGoal = GoalCalculator.dailyGoalML(profile: base)
        XCTAssertGreaterThan(GoalCalculator.dailyGoalML(profile: pregnant), baseGoal)
        XCTAssertGreaterThan(GoalCalculator.dailyGoalML(profile: breastfeeding), baseGoal + 300)
    }

    func testHotClimateAndAthleteIncreaseGoal() {
        var cool = UserProfile()
        cool.climate = .cold
        cool.activity = .sedentary

        var hot = cool
        hot.climate = .hotHumid
        hot.activity = .athlete

        XCTAssertGreaterThan(
            GoalCalculator.dailyGoalML(profile: hot),
            GoalCalculator.dailyGoalML(profile: cool)
        )
    }

    func testGoalClampedToSaneBounds() {
        var tiny = UserProfile()
        tiny.weightKg = 35
        tiny.sex = .female
        XCTAssertGreaterThanOrEqual(GoalCalculator.dailyGoalML(profile: tiny), 1200)

        var huge = UserProfile()
        huge.weightKg = 200
        huge.sex = .male
        huge.isBreastfeeding = true
        huge.activity = .athlete
        huge.climate = .hotHumid
        XCTAssertLessThanOrEqual(GoalCalculator.dailyGoalML(profile: huge), 5000)
    }

    func testWeatherBonusOnlyAboveThreshold() {
        XCTAssertEqual(GoalCalculator.weatherBonusML(temperatureCelsius: 20, enabled: true), 0)
        XCTAssertEqual(GoalCalculator.weatherBonusML(temperatureCelsius: 28, enabled: true), 0, accuracy: 1)
        XCTAssertGreaterThan(GoalCalculator.weatherBonusML(temperatureCelsius: 34, enabled: true), 300)
        XCTAssertEqual(GoalCalculator.weatherBonusML(temperatureCelsius: 34, enabled: false), 0)
    }

    // MARK: - StatsEngine

    private func makeEntry(_ day: Date, hours: Double, ml: Double, factor: Double = 1.0) -> WaterEntry {
        let date = Calendar.current.date(byAdding: .second, value: Int(hours * 3600), to: day)!
        return WaterEntry(date: date, beverage: .water, volumeML: ml, hydrationFactor: factor, containerName: nil)
    }

    func testHydrationFactorApplies() {
        let day = Calendar.current.startOfDay(for: Date())
        let entries = [makeEntry(day, hours: 8, ml: 200, factor: 0.5)]
        XCTAssertEqual(StatsEngine.totalML(on: day, from: entries), 100, accuracy: 0.01)
    }

    func testStreakCountsYesterdayWhenTodayIncomplete() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let goal: Double = 2000

        // Yesterday met, today empty → streak 1.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let entries = [makeEntry(yesterday, hours: 10, ml: 2200)]
        XCTAssertEqual(StatsEngine.currentStreak(goalML: goal, entries: entries), 1)

        // Yesterday empty too → streak 0.
        XCTAssertEqual(StatsEngine.currentStreak(goalML: goal, entries: []), 0)
    }

    func testStreakCountsMultipleDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var entries: [WaterEntry] = []
        for offset in 1...4 {
            let d = calendar.date(byAdding: .day, value: -offset, to: today)!
            entries.append(makeEntry(d, hours: 9, ml: 2100))
        }
        XCTAssertEqual(StatsEngine.currentStreak(goalML: 2000, entries: entries), 4)
    }

    func testWeekDaysMondayFirst() {
        let calendar = Calendar.current
        // Find a known Wednesday: today + offset.
        var wednesday = Date()
        for _ in 0..<7 where calendar.component(.weekday, from: wednesday) != 4 {
            wednesday = calendar.date(byAdding: .day, value: 1, to: wednesday)!
        }
        let days = StatsEngine.weekDays(reference: wednesday, calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(calendar.component(.weekday, from: days[0]), 2, "Week should start Monday")
        XCTAssertEqual(calendar.component(.weekday, from: days[6]), 1, "Week should end Sunday")
    }

    func testWeekOverWeekChange() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Anchor to last Wednesday so both weeks are fully inside the ranges.
        var lastWednesday = calendar.date(byAdding: .day, value: -7, to: today)!
        while calendar.component(.weekday, from: lastWednesday) != 4 {
            lastWednesday = calendar.date(byAdding: .day, value: -1, to: lastWednesday)!
        }

        var entries: [WaterEntry] = []
        // Last week (Mon–Sun before last Wednesday): 1000 ml every day → avg 1000.
        let lastWeekDays = StatsEngine.weekDays(reference: calendar.date(byAdding: .day, value: -7, to: lastWednesday)!)
        for day in lastWeekDays {
            entries.append(makeEntry(day, hours: 9, ml: 1000))
        }
        // This week (last Wednesday's week): 2000 ml every day → avg 2000 → +100%.
        for day in StatsEngine.weekDays(reference: lastWednesday) {
            entries.append(makeEntry(day, hours: 9, ml: 2000))
        }

        let change = StatsEngine.weekOverWeekChange(reference: lastWednesday, entries: entries)
        XCTAssertNotNil(change)
        XCTAssertEqual(change!, 100, accuracy: 1)
    }

    func testMonthHeatmapRatios() {
        var comps = Calendar.current.dateComponents([.year, .month], from: Date())
        comps.day = 15
        let midMonth = Calendar.current.date(from: comps)!
        let entries = [makeEntry(midMonth, hours: 9, ml: 1000)]
        let heatmap = StatsEngine.monthHeatmap(
            year: comps.year!, month: comps.month!,
            goalML: 2000, entries: entries
        )
        let key = Calendar.current.startOfDay(for: midMonth)
        XCTAssertEqual(heatmap[key]!, 0.5, accuracy: 0.001)
    }

    // MARK: - NotificationScheduler

    func testPlannedRemindersSpanActiveWindow() {
        var s = ReminderSettings()
        s.remindersEnabled = true
        s.bedtimeMode = false
        s.interval = .twoHours
        s.activeStartHour = 8
        s.activeEndHour = 22

        let times = NotificationScheduler.plannedReminderTimes(settings: s)
        XCTAssertEqual(times.first?.hour, 8)
        XCTAssertTrue(times.contains(where: { $0.hour == 20 }))
        XCTAssertFalse(times.contains(where: { $0.hour >= 22 }), "No reminders at/after end hour")
        // 8, 10, 12, 14, 16, 18, 20 → 7 reminders.
        XCTAssertEqual(times.count, 7)
    }

    func testBedtimeModeSuppressesReminders() {
        var s = ReminderSettings()
        s.remindersEnabled = true
        s.bedtimeMode = true
        XCTAssertTrue(NotificationScheduler.plannedReminderTimes(settings: s).isEmpty)
    }

    func testDisabledRemindersSuppressSchedule() {
        var s = ReminderSettings()
        s.remindersEnabled = false
        s.bedtimeMode = false
        XCTAssertTrue(NotificationScheduler.plannedReminderTimes(settings: s).isEmpty)
    }

    // MARK: - VolumeUnit

    func testOzMlRoundTrip() {
        let ml = VolumeUnit.fluidOunces.ml(from: 8)
        let oz = VolumeUnit.fluidOunces.value(fromML: ml)
        XCTAssertEqual(oz, 8, accuracy: 0.001)
    }

    func testEntryHydrationCredit() {
        let entry = WaterEntry(date: Date(), beverage: .coffee, volumeML: 200, hydrationFactor: BeverageType.coffee.hydrationFactor, containerName: nil)
        XCTAssertEqual(entry.hydrationML, 160, accuracy: 0.01)
    }

    // MARK: - Persistence

    func testStoreRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).json")

        let store = HydrationStore(fileURL: url)
        store.completeOnboarding(profile: UserProfile(name: "Test", weightKg: 70, sex: .male,
                                                      isPregnant: false, isBreastfeeding: false,
                                                      activity: .high, climate: .dry, unit: .milliliters))
        store.logDrink(.water, volumeML: 250)

        // Force the debounced save to complete before reloading.
        store.flushSaves()

        let reloaded = HydrationStore(fileURL: url)
        XCTAssertEqual(reloaded.profile.name, "Test")
        XCTAssertTrue(reloaded.hasCompletedOnboarding)
        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries.first?.volumeML, 250)
    }
}
