import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var ctx

    private var completed: [WorkoutSession] { sessions.filter { $0.hasAnyCompleted } }

    var body: some View {
        NavigationStack {
            Group {
                if completed.isEmpty {
                    EmptyState(icon: "calendar",
                               title: "No sessions yet",
                               message: "Finish a workout and it will show up here.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(completed) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    SessionRow(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bg)
            .navigationTitle("History")
        }
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        Card(padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.day?.name ?? session.dayID)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(session.date.formatted(.dateTime.weekday().day().month().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecond)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.workedExerciseCount) exercises")
                    if session.durationSeconds > 0 {
                        Text("\(session.durationSeconds / 60) min")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecond)
            }
        }
    }
}

struct SessionDetailView: View {
    let session: WorkoutSession
    @AppStorage(AppStorageKeys.weightUnit) private var unitRaw: String = WeightUnit.kg.rawValue
    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    private var grouped: [(exercise: ProgramExercise, sets: [SetLog])] {
        let done = session.completedSets
        let ids = Array(Set(done.map(\.exerciseID)))
        return ids.compactMap { id -> (ProgramExercise, [SetLog])? in
            guard let ex = Program.exercise(id: id) else { return nil }
            let sets = done.filter { $0.exerciseID == id }.sorted { $0.setNumber < $1.setNumber }
            return (ex, sets)
        }
        .sorted { ($0.0.id) < ($1.0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(grouped, id: \.exercise.id) { item in
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.exercise.name)
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            ForEach(item.sets) { s in
                                HStack {
                                    Text("Set \(s.setNumber)")
                                        .foregroundStyle(Theme.textSecond)
                                    Spacer()
                                    Text("\(unit.fromKg(s.weight).formatted(.number.precision(.fractionLength(0...1)))) \(unit.label) × \(s.reps)")
                                        .font(.body.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .navigationTitle(session.day?.name ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecond)
            Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecond)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
