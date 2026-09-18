import SwiftUI

@main
struct HydroFlowApp: App {
    @StateObject private var store = HydrationStore()
    @StateObject private var notificationScheduler = NotificationScheduler.shared
    @StateObject private var soundManager = SoundManager.shared

    init() {
        // Tab bar: translucent liquid-glass chrome over scrolling content
        // (WhatsApp-style. `configureWithDefaultBackground` keeps the system
        // blur material; scrollEdgeAppearance keeps it glassy at the top).
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
        tabAppearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation bars: same liquid-glass treatment (systemUltraThinMaterial
        // with a translucent tint), transparent at the scroll edge.
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.60)
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        navAppearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notificationScheduler)
                .environmentObject(soundManager)
                .tint(Theme.azure)
                // Light/Dark/System switch — user-selectable in Settings and
                // via the quick toggle on the Today screen.
                .preferredColorScheme(store.appearance.colorScheme)
                .task {
                    // Refresh weather bonus daily; reschedule nudges for today
                    // (re-resolve the configured sound after install/install-permission).
                    store.refreshWeatherBonus()
                    await notificationScheduler.refreshAuthorizationStatus()
                    notificationScheduler.reschedule(settings: store.reminderSettings, soundManager: soundManager)
                    // Publish the latest snapshot so the Home Screen widget
                    // shows fresh data immediately after launch.
                    WidgetPublisher.publish(
                        currentML: store.todayTotalML,
                        goalML: store.dailyGoalML,
                        unitSymbol: store.profile.unit.symbol,
                        streak: store.currentStreak
                    )
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
