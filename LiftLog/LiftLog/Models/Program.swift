import Foundation

/// One exercise as prescribed by the program (static reference data).
struct ProgramExercise: Identifiable, Hashable {
    let id: String          // stable id, e.g. "upperA.bench_press"
    let name: String
    let sets: Int
    let repLow: Int
    let repHigh: Int

    var repRange: String { repLow == repHigh ? "\(repLow)" : "\(repLow)-\(repHigh)" }
    var scheme: String { "\(sets) × \(repRange)" }
}

/// One training day in the split.
struct WorkoutDay: Identifiable, Hashable {
    let id: String          // e.g. "upperA"
    let name: String        // "UPPER A"
    let subtitle: String    // muscle groups, English
    let exercises: [ProgramExercise]
}

/// The fixed 4-day Upper/Lower split shipped with the app.
enum Program {

    static let days: [WorkoutDay] = [
        WorkoutDay(
            id: "upperA", name: "UPPER A",
            subtitle: "Chest · Back · Shoulders · Arms",
            exercises: [
                ex("upperA", "Bench Press",      3, 8, 10),
                ex("upperA", "Lat Pulldown",     3, 8, 10),
                ex("upperA", "Shoulder Press",   3, 10, 12),
                ex("upperA", "Seated Cable Row", 3, 10, 12),
                ex("upperA", "Lateral Raise",    3, 12, 15),
                ex("upperA", "Preacher Curl",    3, 10, 12),
                ex("upperA", "Rope Pushdown",    3, 10, 12),
            ]),
        WorkoutDay(
            id: "lowerA", name: "LOWER A",
            subtitle: "Quads · Hamstrings · Glutes · Calves · Abs",
            exercises: [
                ex("lowerA", "Squat",              3, 8, 10),
                ex("lowerA", "Romanian Deadlift",  3, 10, 12),
                ex("lowerA", "Leg Press",          3, 12, 15),
                ex("lowerA", "Leg Curl",           3, 12, 15),
                ex("lowerA", "Standing Calf Raise",4, 15, 20),
                ex("lowerA", "Hanging Leg Raise",  3, 12, 15),
            ]),
        WorkoutDay(
            id: "upperB", name: "UPPER B",
            subtitle: "Chest · Back · Shoulders · Arms",
            exercises: [
                ex("upperB", "Incline Bench Press",   3, 8, 10),
                ex("upperB", "Bent-Over Row",         3, 8, 10),
                ex("upperB", "Close-Grip Bench",      3, 10, 12),
                ex("upperB", "High-to-Low Cable Fly", 3, 12, 15),
                ex("upperB", "Reverse Cable Fly",     3, 15, 15),
                ex("upperB", "Hammer Curl",           3, 10, 12),
                ex("upperB", "Lateral Raise",         3, 12, 15),
            ]),
        WorkoutDay(
            id: "lowerB", name: "LOWER B",
            subtitle: "Glutes · Quads · Calves · Abs",
            exercises: [
                ex("lowerB", "Deadlift",          3, 6, 8),
                ex("lowerB", "Hack Squat",        3, 10, 12),
                ex("lowerB", "Leg Extension",     3, 15, 15),
                ex("lowerB", "Hip Thrust",        3, 12, 15),
                ex("lowerB", "Seated Calf Raise", 4, 15, 20),
                ex("lowerB", "Cable Crunch",      3, 15, 15),
            ]),
    ]

    static func day(id: String) -> WorkoutDay? {
        days.first { $0.id == id }
    }

    static func exercise(id: String) -> ProgramExercise? {
        for day in days {
            if let found = day.exercises.first(where: { $0.id == id }) { return found }
        }
        return nil
    }

    /// Every distinct exercise across the program (for the Progress tab).
    static var allExercises: [ProgramExercise] {
        days.flatMap { $0.exercises }
    }

    // MARK: - Helpers

    private static func ex(_ dayID: String, _ name: String, _ sets: Int, _ low: Int, _ high: Int) -> ProgramExercise {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return ProgramExercise(id: "\(dayID).\(slug)", name: name, sets: sets, repLow: low, repHigh: high)
    }
}
