import SwiftUI

@main
struct HydroFlowApp: App {
    @StateObject private var store = HydrationStore()
    @StateObject private var notificationScheduler = NotificationScheduler.shared

    init() {
        // Tab appearance tuned to the HydroFlow glass aesthetic.
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notificationScheduler)
                .tint(Theme.azure)
                .task {
                    // Refresh weather bonus daily; reschedule nudges for today.
                    store.refreshWeatherBonus()
                    await notificationScheduler.refreshAuthorizationStatus()
                    notificationScheduler.reschedule(settings: store.reminderSettings)
                }
        }
    }
}

// MARK: - Root

/// Switches between onboarding and the main tab experience,
/// and hosts the global goal-celebration overlay.
struct RootView: View {
    @EnvironmentObject var store: HydrationStore
    @State private var showingLogSheet = false

    var body: some View {
        if store.hasCompletedOnboarding {
            MainTabView(showingLogSheet: $showingLogSheet)
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Main tabs

/// Tab destinations matching the mockups. "Add" presents the log sheet
/// instead of switching tabs.
enum AppTab: Hashable {
    case today, add, analytics, history, settings
}

struct MainTabView: View {
    @EnvironmentObject var store: HydrationStore
    @Binding var showingLogSheet: Bool

    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                TodayView(showingLogSheet: $showingLogSheet)
            }
            .tabItem { Label("Today", systemImage: "drop.fill") }
            .tag(AppTab.today)

            Color.clear
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
            .tag(AppTab.analytics)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(AppTab.history)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(AppTab.settings)
        }
        .onChange(of: selection) { _, newTab in
            if newTab == .add {
                // The "+" tab opens the Log Hydration sheet, then snaps back.
                showingLogSheet = true
                selection = .today
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogDrinkSheet()
        }
        .modifier(GoalCelebrationModifier())
    }
}
