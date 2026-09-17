import Foundation

/// Computes personalized daily hydration goals.
///
/// Research basis (see plan):
/// - National Academies: ~3.7 L/day men, ~2.7 L/day women — includes food moisture (~20%),
///   so drinkable targets are roughly 80% of that.
/// - Weight-based heuristic used by leading apps: ~30–35 ml per kg.
/// - Adjustments for pregnancy (+300 ml), breastfeeding (+700 ml), activity, and climate.
enum GoalCalculator {

    /// Baseline drinking-water target in milliliters for a profile.
    static func dailyGoalML(profile: UserProfile) -> Double {
        // Sex-based adult baseline of drinkable water (food moisture excluded).
        var goal: Double
        switch profile.sex {
        case .male: goal = 3000
        case .female: goal = 2200
        case .other: goal = 2600
        }

        // Blend with weight heuristic (~33 ml/kg for a 70 kg adult ≈ 2.3 L),
        // weighting sex baseline 60/40 so light/heavy bodies adjust sensibly.
        let weightComponent = profile.weightKg * 33
        goal = goal * 0.6 + weightComponent * 0.4

        // Physiological modifiers.
        if profile.isPregnant { goal += 300 }
        if profile.isBreastfeeding { goal += 700 }

        // Lifestyle and environment.
        goal *= profile.activity.factor
        goal *= profile.climate.factor

        // Round to a friendly 50 ml step, clamped to sane bounds.
        let rounded = (goal / 50).rounded() * 50
        return min(max(rounded, 1200), 5000)
    }

    /// Bonus milliliters to add on hot days when dynamic weather is on.
    static func weatherBonusML(temperatureCelsius: Double, enabled: Bool) -> Double {
        guard enabled, temperatureCelsius >= 28 else { return 0 }
        // Roughly +355 ml (12 oz) starting at 28 °C, scaling up to ~+710 ml at 40 °C.
        let t = min(temperatureCelsius, 40)
        return (355.0 * (t - 28) / 6).rounded()
    }

    /// Estimated baseline text for the onboarding preview pill, e.g. "~88 fl oz / day (2,600 ml)".
    static func baselineText(profile: UserProfile) -> String {
        let goalML = dailyGoalML(profile: profile)
        let oz = goalML / VolumeUnit.mlPerOz
        let ozInt = Int(oz.rounded())
        return "Estimated baseline: ~\(ozInt) fl oz / day (\(Int(goalML)) ml)"
    }

    /// Suggested number of glasses to reach the goal given a unit preset.
    static func glassesPerDay(goalML: Double, presetML: Double = 240) -> Double {
        goalML / presetML
    }
}
