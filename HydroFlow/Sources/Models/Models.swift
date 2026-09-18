import Foundation
import SwiftUI

// MARK: - Volume units

/// Units supported across the app.
enum VolumeUnit: String, Codable, CaseIterable, Identifiable {
    case milliliters
    case fluidOunces

    var id: String { rawValue }

    /// Short display suffix ("ml" / "oz").
    var symbol: String { self == .milliliters ? "ml" : "oz" }

    /// Milliliters per fluid ounce.
    static let mlPerOz: Double = 29.5735

    /// Convert a raw milliliter value into this unit's display value.
    func value(fromML ml: Double) -> Double {
        self == .milliliters ? ml : ml / Self.mlPerOz
    }

    /// Convert a value expressed in this unit into milliliters.
    func ml(from value: Double) -> Double {
        self == .milliliters ? value : value * Self.mlPerOz
    }

    /// Human-readable name for pickers.
    var displayName: String { self == .milliliters ? "Milliliters (ml)" : "Fluid Ounces (oz)" }
}

// MARK: - Beverage types

/// Known beverage categories with physiological hydration factors.
/// Research basis: caffeine/alcohol have mild diuretic effects; electrolytes
/// can hydrate slightly better than plain water. See Waterllama / study notes.
enum BeverageType: String, Codable, CaseIterable, Identifiable {
    case water
    case sparklingWater
    case electrolytes
    case tea
    case coffee
    case coconutWater
    case juice
    case milk
    case soda
    case energyDrink
    case alcohol
    case custom

    var id: String { rawValue }

    /// Display name shown in lists.
    var displayName: String {
        switch self {
        case .water: "Pure Water"
        case .sparklingWater: "Sparkling Water"
        case .electrolytes: "Electrolyte Drink"
        case .tea: "Green / Herbal Tea"
        case .coffee: "Iced / Hot Coffee"
        case .coconutWater: "Coconut Water"
        case .juice: "Fruit Juice"
        case .milk: "Milk"
        case .soda: "Soft Drink"
        case .energyDrink: "Energy Drink"
        case .alcohol: "Alcohol"
        case .custom: "Custom Beverage"
        }
    }

    /// Net hydration factor — how much of the volume "counts" toward hydration.
    var hydrationFactor: Double {
        switch self {
        case .water, .sparklingWater: 1.00
        case .electrolytes: 1.10
        case .tea: 0.90
        case .coffee: 0.80
        case .coconutWater: 0.95
        case .juice: 0.90
        case .milk: 0.90
        case .soda: 0.85
        case .energyDrink: 0.75
        case .alcohol: 0.30
        case .custom: 1.00
        }
    }

    /// Default one-tap preset volume, in milliliters.
    var presetML: Double {
        switch self {
        case .water: 240            // 8 oz glass
        case .sparklingWater: 355   // 12 oz can
        case .electrolytes: 473     // 16 oz flask
        case .tea: 240              // 8 oz cup
        case .coffee: 180           // 6 oz cup
        case .coconutWater: 330     // 11 oz
        case .juice: 240
        case .milk: 240
        case .soda: 355
        case .energyDrink: 250
        case .alcohol: 355
        case .custom: 240
        }
    }

    /// SF Symbol representing the drink.
    var symbolName: String {
        switch self {
        case .water: "drop.fill"
        case .sparklingWater: "bubbles.and.sparkles.fill"
        case .electrolytes: "bolt.fill"
        case .tea: "leaf.fill"
        case .coffee: "cup.and.saucer.fill"
        case .coconutWater: "snowflake"
        case .juice: "carrot.fill"
        case .milk: "waterbottle.fill"
        case .soda: "takeoutbag.and.cup.and.straw.fill"
        case .energyDrink: "flame.fill"
        case .alcohol: "wineglass.fill"
        case .custom: "testtube.2"
        }
    }

    /// Accent tint used for the icon tile.
    var tint: String {
        switch self {
        case .water, .sparklingWater, .coconutWater: "azure"
        case .electrolytes, .tea, .milk: "aqua"
        case .coffee, .energyDrink, .soda, .alcohol: "indigo"
        case .juice: "orange"
        case .custom: "violet"
        }
    }

    /// Typical preset volume, formatted in the user's unit.
    func presetText(unit: VolumeUnit) -> String {
        let value = unit.value(fromML: presetML)
        return "\(Int(value.rounded())) \(unit.symbol)"
    }
}

// MARK: - User profile

/// Activity multipliers applied on top of the weight-based baseline.
enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case moderate
    case high
    case athlete

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: "Sedentary"
        case .moderate: "Moderate"
        case .high: "High"
        case .athlete: "Athlete"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: "Desk routine"
        case .moderate: "Active walks"
        case .high: "Intense training"
        case .athlete: "Competitive"
        }
    }

    var symbolName: String {
        switch self {
        case .sedentary: "sofa.fill"
        case .moderate: "figure.walk"
        case .high: "dumbbell.fill"
        case .athlete: "bolt.fill"
        }
    }

    /// Extra water factor relative to baseline.
    var factor: Double {
        switch self {
        case .sedentary: 1.00
        case .moderate: 1.05
        case .high: 1.12
        case .athlete: 1.20
        }
    }
}

/// Regional climate adjustments.
enum Climate: String, Codable, CaseIterable, Identifiable {
    case temperate
    case hotHumid
    case dry
    case cold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .temperate: "Temperate"
        case .hotHumid: "Hot/Humid"
        case .dry: "Dry"
        case .cold: "Cold"
        }
    }

    var factor: Double {
        switch self {
        case .temperate: 1.00
        case .hotHumid: 1.12
        case .dry: 1.08
        case .cold: 0.97
        }
    }
}

/// Biological sex used for goal calculation (per National Academies baselines).
enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        }
    }
}

/// The user's profile captured during onboarding; drives goal calculation.
struct UserProfile: Codable, Equatable {
    var name: String = ""
    var weightKg: Double = 70
    var sex: BiologicalSex = .female
    var isPregnant: Bool = false
    var isBreastfeeding: Bool = false
    var activity: ActivityLevel = .moderate
    var climate: Climate = .temperate
    var unit: VolumeUnit = .fluidOunces
    var customGoalML: Double?

    /// Body weight in the user's preferred display unit (lbs or kg).
    var displayWeight: Double {
        unit == .fluidOunces ? weightKg * 2.20462 : weightKg
    }
}

// MARK: - Water entries

/// One logged drink.
struct WaterEntry: Codable, Identifiable, Equatable {
    /// Stable identifier, persisted across saves.
    var id: UUID = UUID()
    /// Absolute time of logging.
    var date: Date
    /// Beverage category.
    var beverage: BeverageType
    /// Volume in milliliters (canonical storage unit).
    var volumeML: Double
    /// Hydration factor at time of logging (custom drinks may override).
    var hydrationFactor: Double
    /// Optional container label, e.g. "Office Mug".
    var containerName: String?

    /// Hydration credit in milliliters (volume × factor).
    var hydrationML: Double { volumeML * hydrationFactor }
}

extension Double {
    /// Sane clamp for the Log-sheet bottle capacity (150 ml sip cup … 3.8 L jug).
    var clampedBottleCapacity: Double { min(max(self, 150), 3800) }
}

// MARK: - Appearance

/// User-selected color scheme. `.system` follows the iOS setting.
enum AppearancePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }    /// nil = follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Cycle order for the quick-toggle button: System → Light → Dark → System.
    var next: AppearancePreference {
        switch self {
        case .system: .light
        case .light: .dark
        case .dark: .system
        }
    }
}

// MARK: - Reminder settings

/// Reminder cadence presets (hours between nudges). A fully custom
/// minute value lives in `ReminderSettings.customIntervalMinutes`.
enum ReminderInterval: Double, Codable, CaseIterable, Identifiable {
    case thirtyMinutes = 0.5
    case fortyFiveMinutes = 0.75
    case oneHour = 1
    case ninetyMinutes = 1.5
    case twoHours = 2
    case twoHalfHours = 2.5
    case threeHours = 3

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .thirtyMinutes: "Every 30 Minutes"
        case .fortyFiveMinutes: "Every 45 Minutes"
        case .oneHour: "Every Hour"
        case .ninetyMinutes: "Every 1.5 Hours"
        case .twoHours: "Every 2 Hours"
        case .twoHalfHours: "Every 2.5 Hours"
        case .threeHours: "Every 3 Hours"
        }
    }
}

/// A named drinking vessel the user can one-tap log with. Editable in
/// Settings → Container Presets; surfaced on the Today quick-log shelf.
struct ContainerPreset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var volumeML: Double
    var symbolName: String
    var beverage: BeverageType = .water

    /// Curated SF Symbols that are known-valid on iOS 17.
    static let availableSymbols = [
        "cup.and.saucer.fill", "water.glass.fill", "mug.fill",
        "waterbottle.fill", "takeoutbag.and.cup.and.straw.fill",
        "testtube.fill", "drop.fill"
    ]

    static let defaults: [ContainerPreset] = [
        .init(name: "Cup", volumeML: 240, symbolName: "cup.and.saucer.fill"),
        .init(name: "Glass", volumeML: 355, symbolName: "water.glass.fill"),
        .init(name: "Mug", volumeML: 473, symbolName: "mug.fill"),
        .init(name: "Bottle", volumeML: 710, symbolName: "waterbottle.fill"),
        .init(name: "Jug", volumeML: 950, symbolName: "takeoutbag.and.cup.and.straw.fill")
    ]

    /// Volume formatted in the given unit (e.g. "12 oz").
    func volumeText(unit: VolumeUnit) -> String {
        "\(Int(unit.value(fromML: volumeML).rounded())) \(unit.symbol)"
    }
}

/// All notification-related preferences.
struct ReminderSettings: Codable, Equatable {
    /// Master switch for drink reminders.
    var remindersEnabled: Bool = true
    /// Hours between nudges during active hours (preset).
    var interval: ReminderInterval = .ninetyMinutes
    /// Fully custom cadence in minutes; wins over `interval` when set.
    var customIntervalMinutes: Double?
    /// Active window start hour (0–23), e.g. 8 for 8 AM.
    var activeStartHour: Int = 8
    /// Active window end hour (0–23), e.g. 22 for 10 PM. May wrap past midnight.
    var activeEndHour: Int = 22
    /// Bedtime mode mutes everything overnight regardless of window.
    /// Default OFF — starting ON silently suppressed the whole schedule.
    var bedtimeMode: Bool = false
    /// Dynamic weather adds bonus goal on hot days.
    var dynamicWeather: Bool = true
    /// Haptic feedback on logging.
    var hapticsEnabled: Bool = true
    /// Selected notification sound (SoundManager option id, "default" = system).
    var soundName: String = "default"
    /// Preview/alert volume preference 0...1 (used for in-app preview).
    var soundVolume: Double = 0.8

    /// Minutes between reminders: custom value if set, else the preset.
    var effectiveIntervalMinutes: Double {
        customIntervalMinutes ?? interval.rawValue * 60
    }

    /// Whether the active window crosses midnight (start ≥ end, non-equal).
    var wrapsMidnight: Bool {
        activeStartHour >= activeEndHour
    }

    /// Active window start as clock time.
    var activeStart: Date {
        Calendar.current.date(bySettingHour: activeStartHour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    /// Active window end as clock time.
    var activeEnd: Date {
        Calendar.current.date(bySettingHour: activeEndHour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    /// Human text for the interval row ("Every 90 min").
    var intervalDisplayText: String {
        if let custom = customIntervalMinutes {
            let mins = Int(custom.rounded())
            return mins % 60 == 0 ? "Every \(mins / 60) h" : "Every \(mins) min"
        }
        return interval.displayName
    }

    /// Time-of-day formatter for active hours row.
    static let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    // Backward-compatible decoding: new fields default when absent, so
    // state files written by earlier versions keep loading.
    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true
        interval = try c.decodeIfPresent(ReminderInterval.self, forKey: .interval) ?? .ninetyMinutes
        customIntervalMinutes = try c.decodeIfPresent(Double.self, forKey: .customIntervalMinutes)
        activeStartHour = try c.decodeIfPresent(Int.self, forKey: .activeStartHour) ?? 8
        activeEndHour = try c.decodeIfPresent(Int.self, forKey: .activeEndHour) ?? 22
        bedtimeMode = try c.decodeIfPresent(Bool.self, forKey: .bedtimeMode) ?? false
        dynamicWeather = try c.decodeIfPresent(Bool.self, forKey: .dynamicWeather) ?? true
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        soundName = try c.decodeIfPresent(String.self, forKey: .soundName) ?? "default"
        soundVolume = try c.decodeIfPresent(Double.self, forKey: .soundVolume) ?? 0.8
    }
}
