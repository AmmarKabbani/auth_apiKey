import Foundation

/// Weights are always stored internally in kilograms. This enum converts
/// to/from the unit the user has chosen in Settings, so existing logs stay
/// correct even if the user switches units later.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }

    var label: String { self == .kg ? "kg" : "lb" }

    private static let lbPerKg = 2.2046226218

    /// Convert a stored kilogram value into the display unit.
    func fromKg(_ kg: Double) -> Double {
        self == .kg ? kg : kg * Self.lbPerKg
    }

    /// Convert a value typed in the display unit back into kilograms for storage.
    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value / Self.lbPerKg
    }

    /// Plate-friendly rounding step in the display unit.
    var step: Double { self == .kg ? 2.5 : 5 }
}

enum AppStorageKeys {
    static let weightUnit = "weightUnit"
    static let restSeconds = "restSeconds"
}
