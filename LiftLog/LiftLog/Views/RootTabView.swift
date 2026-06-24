import SwiftUI

struct RootTabView: View {
    init() {
        // Make the tab bar blend into the dark theme.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.bg)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }

            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [WorkoutSession.self, SetLog.self], inMemory: true)
        .preferredColorScheme(.dark)
}
