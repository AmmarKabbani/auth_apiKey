import Foundation
import SwiftData

/// A completed (or in-progress) training session, persisted on-device.
@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var dayID: String
    var durationSeconds: Int

    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var setLogs: [SetLog]

    init(id: UUID = UUID(), date: Date = .now, dayID: String, durationSeconds: Int = 0) {
        self.id = id
        self.date = date
        self.dayID = dayID
        self.durationSeconds = durationSeconds
        self.setLogs = []
    }

    var day: WorkoutDay? { Program.day(id: dayID) }

    /// Sets the user actually completed (ticked off).
    var completedSets: [SetLog] { setLogs.filter { $0.isDone } }

    var hasAnyCompleted: Bool { setLogs.contains { $0.isDone } }

    /// Distinct exercises that had at least one completed set.
    var workedExerciseCount: Int {
        Set(completedSets.map { $0.exerciseID }).count
    }
}

/// A single logged set within a session.
@Model
final class SetLog {
    var id: UUID
    var exerciseID: String
    var setNumber: Int
    /// Always stored in kilograms; converted for display via `WeightUnit`.
    var weight: Double
    var reps: Int
    var isDone: Bool

    var session: WorkoutSession?

    init(id: UUID = UUID(), exerciseID: String, setNumber: Int,
         weight: Double = 0, reps: Int = 0, isDone: Bool = false) {
        self.id = id
        self.exerciseID = exerciseID
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isDone = isDone
    }
}
