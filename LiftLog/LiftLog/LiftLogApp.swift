import SwiftUI
import SwiftData

@main
struct LiftLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(for: [WorkoutSession.self, SetLog.self])
    }
}
