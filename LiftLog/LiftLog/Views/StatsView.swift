import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var sessions: [WorkoutSession]

    /// Exercises that actually have logged history, to keep the list relevant.
    private var trained: Set<String> {
        Set(sessions.flatMap { $0.completedSets }.map { $0.exerciseID })
    }

    var body: some View {
        NavigationStack {
            Group {
                if trained.isEmpty {
                    EmptyState(icon: "chart.line.uptrend.xyaxis",
                               title: "No progress yet",
                               message: "Log a few sessions to see your strength trend per exercise.")
                } else {
                    List {
                        ForEach(Program.days) { day in
                            let exercises = day.exercises.filter { trained.contains($0.id) }
                            if !exercises.isEmpty {
                                Section(day.name) {
                                    ForEach(exercises) { ex in
                                        NavigationLink {
                                            ExerciseProgressView(exercise: ex)
                                        } label: {
                                            Text(ex.name)
                                        }
                                        .listRowBackground(Theme.surface)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bg)
            .navigationTitle("Progress")
        }
    }
}

private struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let topWeightKg: Double
    let repsAtTop: Int
}

struct ExerciseProgressView: View {
    let exercise: ProgramExercise

    @Query(sort: \WorkoutSession.date, order: .forward) private var sessions: [WorkoutSession]
    @AppStorage(AppStorageKeys.weightUnit) private var unitRaw: String = WeightUnit.kg.rawValue
    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    private var points: [DataPoint] {
        sessions.compactMap { session -> DataPoint? in
            let logs = session.completedSets.filter { $0.exerciseID == exercise.id }
            guard let top = logs.max(by: { $0.weight < $1.weight }) else { return nil }
            return DataPoint(date: session.date, topWeightKg: top.weight, repsAtTop: top.reps)
        }
    }

    private var pr: DataPoint? { points.max { $0.topWeightKg < $1.topWeightKg } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let pr {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill").foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Personal Record").font(.caption).foregroundStyle(Theme.textSecond)
                                Text("\(disp(pr.topWeightKg)) \(unit.label) × \(pr.repsAtTop)")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top set over time").font(.subheadline).foregroundStyle(Theme.textSecond)
                        chart
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All sessions").font(.subheadline).foregroundStyle(Theme.textSecond)
                        ForEach(points.reversed()) { p in
                            HStack {
                                Text(p.date.formatted(.dateTime.day().month().year()))
                                    .foregroundStyle(Theme.textSecond)
                                Spacer()
                                Text("\(disp(p.topWeightKg)) \(unit.label) × \(p.repsAtTop)")
                                    .font(.body.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var chart: some View {
        if points.count < 2 {
            Text("Log at least two sessions to see a trend.")
                .font(.caption)
                .foregroundStyle(Theme.textSecond)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            Chart(points) { p in
                LineMark(x: .value("Date", p.date),
                         y: .value("Weight", unit.fromKg(p.topWeightKg)))
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", p.date),
                          y: .value("Weight", unit.fromKg(p.topWeightKg)))
                    .foregroundStyle(Theme.accent)
            }
            .chartYAxisLabel("\(unit.label)")
            .frame(height: 200)
        }
    }

    private func disp(_ kg: Double) -> String {
        unit.fromKg(kg).formatted(.number.precision(.fractionLength(0...1)))
    }
}
