import SwiftUI

struct WorkoutDetailView: View {
    let day: WorkoutDay
    @State private var startSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(day.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecond)
                    .padding(.bottom, 4)

                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { index, ex in
                    Card(padding: 14) {
                        HStack(spacing: 14) {
                            Text("\(index + 1)")
                                .font(.headline.weight(.bold).monospacedDigit())
                                .foregroundStyle(Theme.accent)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Target \(ex.scheme)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecond)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .background(Theme.bg)
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            Button {
                startSession = true
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(Color.black)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $startSession) {
            LoggingView(day: day)
        }
    }
}
