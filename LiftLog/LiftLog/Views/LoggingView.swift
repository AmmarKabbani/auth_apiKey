import SwiftUI
import SwiftData

/// Immersive session screen: swipe through the day's exercises, log each set,
/// and a rest timer auto-starts when you tick a set off.
struct LoggingView: View {
    let day: WorkoutDay

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.restSeconds) private var restSeconds: Int = 120

    @State private var session: WorkoutSession?
    @State private var previous: [String: [Int: SetValue]] = [:]
    @State private var current = 0
    @State private var startTime = Date()

    // Rest timer state
    @State private var restRemaining = 0
    @State private var restRunning = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let session {
                content(session)
            } else {
                Color.black
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .task { setupSession() }
        .onReceive(ticker) { _ in
            guard restRunning, restRemaining > 0 else { return }
            restRemaining -= 1
            if restRemaining == 0 { restRunning = false }
        }
    }

    @ViewBuilder
    private func content(_ session: WorkoutSession) -> some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $current) {
                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { idx, ex in
                    ExerciseLogPage(
                        session: session,
                        exercise: ex,
                        index: idx,
                        total: day.exercises.count,
                        previous: previous[ex.id] ?? [:],
                        onComplete: startRest
                    )
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.default, value: current)

            bottomBar
        }
    }

    // MARK: - Bars

    private var topBar: some View {
        HStack {
            Button(role: .cancel) { cancel() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecond)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(day.name).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Text("\(current + 1) / \(day.exercises.count)")
                    .font(.caption2).foregroundStyle(Theme.textSecond)
            }
            Spacer()
            Button { finish() } label: {
                Text("Finish").font(.headline.weight(.semibold)).foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Rest timer
            HStack(spacing: 14) {
                Image(systemName: "timer").foregroundStyle(Theme.accent)
                Text(timeString(restRemaining))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(restRunning ? Theme.accent : Theme.textPrimary)
                Spacer()
                Button { restRunning ? pauseRest() : resumeRest() } label: {
                    Image(systemName: restRunning ? "pause.fill" : "play.fill")
                }
                Button { resetRest() } label: { Image(systemName: "arrow.counterclockwise") }
            }
            .font(.headline)
            .foregroundStyle(Theme.textSecond)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Prev / Next
            HStack {
                Button { withAnimation { current = max(0, current - 1) } } label: {
                    Label("Prev", systemImage: "chevron.left")
                }
                .disabled(current == 0)
                Spacer()
                if current < day.exercises.count - 1 {
                    Button { withAnimation { current += 1 } } label: {
                        Label("Next", systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                    }
                } else {
                    Button { finish() } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Rest timer control

    private func startRest() {
        restRemaining = restSeconds
        restRunning = true
    }
    private func pauseRest() { restRunning = false }
    private func resumeRest() {
        if restRemaining == 0 { restRemaining = restSeconds }
        restRunning = true
    }
    private func resetRest() {
        restRemaining = restSeconds
        restRunning = false
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - Session lifecycle

    private func setupSession() {
        guard session == nil else { return }
        startTime = Date()
        restRemaining = restSeconds

        let s = WorkoutSession(date: .now, dayID: day.id)
        ctx.insert(s)

        // Pre-fill each set with the most recent completed values for that exercise.
        for ex in day.exercises {
            let prev = previousValues(for: ex.id, excluding: s.id)
            previous[ex.id] = prev
            for n in 1...ex.sets {
                let p = prev[n]
                let log = SetLog(exerciseID: ex.id, setNumber: n,
                                 weight: p?.weight ?? 0,
                                 reps: p?.reps ?? ex.repLow,
                                 isDone: false)
                log.session = s
                ctx.insert(log)
            }
        }
        session = s
    }

    /// Most recent completed set values for an exercise, keyed by set number.
    private func previousValues(for exerciseID: String, excluding currentID: UUID) -> [Int: SetValue] {
        let desc = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let all = (try? ctx.fetch(desc)) ?? []
        for s in all where s.id != currentID {
            let logs = s.setLogs.filter { $0.exerciseID == exerciseID && $0.isDone }
            if !logs.isEmpty {
                var map: [Int: SetValue] = [:]
                for l in logs { map[l.setNumber] = SetValue(weight: l.weight, reps: l.reps) }
                return map
            }
        }
        return [:]
    }

    private func finish() {
        guard let session else { dismiss(); return }
        // Drop untouched placeholder sets so history stays clean.
        let placeholders = session.setLogs.filter { !$0.isDone }
        for log in placeholders {
            ctx.delete(log)
        }
        if session.setLogs.isEmpty {
            ctx.delete(session)
        } else {
            session.durationSeconds = Int(Date().timeIntervalSince(startTime))
        }
        try? ctx.save()
        dismiss()
    }

    private func cancel() {
        if let session { ctx.delete(session) }
        try? ctx.save()
        dismiss()
    }
}

/// Lightweight value type for pre-fill ghosts.
struct SetValue { let weight: Double; let reps: Int }

// MARK: - Per-exercise page

private struct ExerciseLogPage: View {
    @Bindable var session: WorkoutSession
    let exercise: ProgramExercise
    let index: Int
    let total: Int
    let previous: [Int: SetValue]
    let onComplete: () -> Void

    @Environment(\.modelContext) private var ctx
    @AppStorage(AppStorageKeys.weightUnit) private var unitRaw: String = WeightUnit.kg.rawValue
    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    private var sets: [SetLog] {
        session.setLogs
            .filter { $0.exerciseID == exercise.id }
            .sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Target \(exercise.scheme)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecond)
                }

                // Column headers
                HStack {
                    Text("SET").frame(width: 40, alignment: .leading)
                    Text("WEIGHT (\(unit.label))").frame(maxWidth: .infinity, alignment: .leading)
                    Text("REPS").frame(width: 70, alignment: .leading)
                    Text("").frame(width: 44)
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.textSecond)

                ForEach(sets) { log in
                    SetRow(log: log,
                           unit: unit,
                           ghost: previous[log.setNumber],
                           onToggle: { if log.isDone { onComplete() } },
                           onDelete: { delete(log) })
                }

                Button(action: addSet) {
                    Label("Add Set", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surfaceHi, in: RoundedRectangle(cornerRadius: Theme.rowRadius, style: .continuous))
                        .foregroundStyle(Theme.textPrimary)
                }

                if index < total - 1 {
                    let next = Program.day(id: exercise.id.components(separatedBy: ".").first ?? "")?
                        .exercises[safe: index + 1]
                    if let next {
                        Text("Up next: \(next.name)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecond)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func addSet() {
        let nextNumber = (sets.map(\.setNumber).max() ?? 0) + 1
        let template = sets.last
        let log = SetLog(exerciseID: exercise.id,
                         setNumber: nextNumber,
                         weight: template?.weight ?? 0,
                         reps: template?.reps ?? exercise.repLow,
                         isDone: false)
        log.session = session
        ctx.insert(log)
    }

    private func delete(_ log: SetLog) {
        ctx.delete(log)
    }
}

// MARK: - Set row

private struct SetRow: View {
    @Bindable var log: SetLog
    let unit: WeightUnit
    let ghost: SetValue?
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var weightBinding: Binding<Double> {
        Binding(get: { unit.fromKg(log.weight) },
                set: { log.weight = unit.toKg($0) })
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(log.setNumber)")
                .font(.body.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.accent)
                .frame(width: 40, alignment: .leading)

            field(value: weightBinding, format: .number.precision(.fractionLength(0...1)),
                  keyboard: .decimalPad, ghost: ghost.map { unit.fromKg($0.weight).formatted(.number.precision(.fractionLength(0...1))) })
                .frame(maxWidth: .infinity)

            field(value: Binding(get: { Double(log.reps) }, set: { log.reps = Int($0) }),
                  format: .number, keyboard: .numberPad,
                  ghost: ghost.map { "\($0.reps)" })
                .frame(width: 70)

            Button {
                log.isDone.toggle()
                onToggle()
            } label: {
                Image(systemName: log.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(log.isDone ? Theme.accent : Theme.textSecond)
            }
            .frame(width: 44)
        }
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(
            (log.isDone ? Theme.accent.opacity(0.08) : Theme.surface),
            in: RoundedRectangle(cornerRadius: Theme.rowRadius, style: .continuous)
        )
        .swipeActions { Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") } }
    }

    @ViewBuilder
    private func field(value: Binding<Double>, format: FloatingPointFormatStyle<Double>,
                       keyboard: UIKeyboardType, ghost: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            TextField("0", value: value, format: format)
                .keyboardType(keyboard)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            if let ghost {
                Text("last \(ghost)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecond.opacity(0.7))
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
