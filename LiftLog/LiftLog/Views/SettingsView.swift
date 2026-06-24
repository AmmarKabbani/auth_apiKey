import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(AppStorageKeys.weightUnit) private var unitRaw: String = WeightUnit.kg.rawValue
    @AppStorage(AppStorageKeys.restSeconds) private var restSeconds: Int = 120

    @Environment(\.modelContext) private var ctx
    @Query private var sessions: [WorkoutSession]
    @State private var showClearConfirm = false

    private let restOptions = [60, 90, 120, 150, 180, 240]

    var body: some View {
        NavigationStack {
            List {
                Section("Units") {
                    Picker("Weight unit", selection: $unitRaw) {
                        ForEach(WeightUnit.allCases) { u in
                            Text(u.label.uppercased()).tag(u.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Theme.surface)
                }

                Section("Rest timer") {
                    Picker("Default rest", selection: $restSeconds) {
                        ForEach(restOptions, id: \.self) { s in
                            Text(s % 60 == 0 ? "\(s / 60):00" : "\(s / 60):\(s % 60)").tag(s)
                        }
                    }
                    .listRowBackground(Theme.surface)
                }

                Section("Data") {
                    HStack {
                        Text("Logged sessions")
                        Spacer()
                        Text("\(sessions.count)").foregroundStyle(Theme.textSecond)
                    }
                    .listRowBackground(Theme.surface)

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Delete all history", systemImage: "trash")
                    }
                    .listRowBackground(Theme.surface)
                }

                Section {
                    HStack {
                        Text("Program")
                        Spacer()
                        Text("Upper / Lower · 4 days").foregroundStyle(Theme.textSecond)
                    }
                    .listRowBackground(Theme.surface)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(Theme.textSecond)
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("About")
                } footer: {
                    Text("All data is stored privately on your device.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Settings")
            .confirmationDialog("Delete all logged sessions? This cannot be undone.",
                                isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive, action: clearAll)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func clearAll() {
        for s in sessions { ctx.delete(s) }
        try? ctx.save()
    }
}
