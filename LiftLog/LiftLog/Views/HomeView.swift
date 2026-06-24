import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    ForEach(Program.days) { day in
                        NavigationLink(value: day) {
                            DayCard(day: day,
                                    lastDate: lastDate(for: day.id),
                                    isDue: day.id == suggestedDayID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("LiftLog")
            .navigationDestination(for: WorkoutDay.self) { day in
                WorkoutDetailView(day: day)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecond)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default:      return "Good evening 👋"
        }
    }

    private func lastDate(for dayID: String) -> Date? {
        sessions.first { $0.dayID == dayID && $0.hasAnyCompleted }?.date
    }

    /// Suggest the day that hasn't been trained for the longest (simple rotation hint).
    private var suggestedDayID: String? {
        Program.days
            .min { (lastDate(for: $0.id) ?? .distantPast) < (lastDate(for: $1.id) ?? .distantPast) }?
            .id
    }
}

private struct DayCard: View {
    let day: WorkoutDay
    let lastDate: Date?
    let isDue: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(day.name)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(isDue ? Theme.accent : Theme.textPrimary)
                    Spacer()
                    if isDue {
                        Text("DUE")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(Theme.accent)
                    }
                }

                Text(day.subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecond)

                HStack(spacing: 8) {
                    Label("\(day.exercises.count) exercises", systemImage: "list.bullet")
                    Text("·")
                    Text(lastDateText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecond)
            }
        }
    }

    private var lastDateText: String {
        guard let lastDate else { return "Never done" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last " + formatter.localizedString(for: lastDate, relativeTo: .now)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, SetLog.self], inMemory: true)
        .preferredColorScheme(.dark)
}
