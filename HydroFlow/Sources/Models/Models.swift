import Foundation

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
        case .milk: "carton.fill"
        case .soda: "takeoutbag.and.cup.and.straw.fill"
        case .energyDrink: "flame.fill"
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

    /// Body weight in the user's preferred display unit (lbs or kg).
    var displayWeight: Double {
        unit == .fluidOunces ? weightKg * 2.20462 : weightKg
    }
}

// MARK: - Water entries

/// One logged drink.
struct WaterEntry: Codable, Identifiable, Equatable {
    /// Stable identifier, persisted for HealthKit de-duplication.
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

// MARK: - Reminder settings

/// Reminder cadence options (hours between nudges).
enum ReminderInterval: Double, Codable, CaseIterable, Identifiable {
    case oneHour = 1
    case ninetyMinutes = 1.5
    case twoHours = 2
    case threeHours = 3

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: "Every Hour"
        case .ninetyMinutes: "Every 1.5 Hours"
        case .twoHours: "Every 2 Hours"
        case .threeHours: "Every 3 Hours"
        }
    }
}

/// All notification-related preferences.
struct ReminderSettings: Codable, Equatable {
    /// Master switch for drink reminders.
    var remindersEnabled: Bool = true
    /// Hours between nudges during active hours.
    var interval: ReminderInterval = .ninetyMinutes
    /// Active window start hour (0–23), e.g. 8 for 8 AM.
    var activeStartHour: Int = 8
    /// Active window end hour (0–23), e.g. 22 for 10 PM.
    var activeEndHour: Int = 22
    /// Bedtime mode mutes everything overnight regardless of window.
    var bedtimeMode: Bool = true
    /// Dynamic weather adds bonus goal on hot days.
    var dynamicWeather: Bool = true
    /// Haptic feedback on logging.
    var hapticsEnabled: Bool = true

    /// Active window start as clock time.
    var activeStart: Date {
        Calendar.current.date(bySettingHour: activeStartHour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    /// Active window end as clock time.
    var activeEnd: Date {
        Calendar.current.date(bySettingHour: activeEndHour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    /// Time-of-day formatter for active hours row.
    static let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
}
