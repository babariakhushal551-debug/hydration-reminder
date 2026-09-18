import SwiftUI

@main
struct HydroFlowApp: App {
    @StateObject private var store = HydrationStore()
    @StateObject private var notificationScheduler = NotificationScheduler.shared
    @StateObject private var soundManager = SoundManager.shared

    init() {
        if #available(iOS 26.0, *) {
            // iOS 26 Liquid Glass: the system now renders WhatsApp/Apple-Health
            // style translucent glass chrome for navigation and tab bars
            // automatically — floating glass pills that morph on push, tint
            // from the content behind them, and blur at the scroll edge.
            // Setting ANY custom UITabBarAppearance/UINavigationBarAppearance
            // here would opt the bars OUT of the system material (custom
            // backgrounds are drawn over the glass), so we deliberately
            // configure nothing on this path.
        } else {
            // Pre-iOS 26: simulate the same liquid-glass look with the
            // system blur material so older devices keep a consistent,
            // translucent chrome (WhatsApp-style tab bar).
            let tabAppearance = UITabBarAppearance()
            tabAppearance.configureWithDefaultBackground()
            tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            tabAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
            tabAppearance.shadowColor = .clear
            UITabBar.appearance().standardAppearance = tabAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance

            // Navigation bars: same translucent glass treatment, transparent
            // at the scroll edge.
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

    /// Single source of truth for the visible tab (String ids drive both the
    /// floating glass bar and, via `appTabBinding`, the TabView).
    @State private var tabSelection: String = "today"

    /// Items for the floating glass tab bar.
    static let tabItems: [FloatingTabItem] = [
        FloatingTabItem(id: "today", symbol: "drop.fill", label: "Today"),
        FloatingTabItem(id: "add", symbol: "plus.circle.fill", label: "Add"),
        FloatingTabItem(id: "analytics", symbol: "chart.xyaxis.line", label: "Analytics"),
        FloatingTabItem(id: "history", symbol: "clock.arrow.circlepath", label: "History"),
        FloatingTabItem(id: "settings", symbol: "gearshape.fill", label: "Settings")
    ]

    var body: some View {
        ZStack {
            TabView(selection: appTabBinding) {
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
            // The system tab bar is hidden; the floating glass capsule below
            // is the visible chrome (Dribbble-style detached Liquid Glass).
            .toolbar(.hidden, for: .tabBar)

            VStack(spacing: 0) {
                Spacer()
                FloatingGlassTabBar(
                    items: Self.tabItems,
                    selection: $tabSelection,
                    onAdd: { showingLogSheet = true }
                )
            }
            // Stay pinned above the home indicator; never dodge the keyboard.
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .sheet(isPresented: $showingLogSheet) {
            LogDrinkSheet()
        }
        .modifier(GoalCelebrationModifier())
    }

    /// Single source of truth: the floating bar's String selection drives the
    /// TabView. "add" never becomes a selection — it presents the log sheet.
    private var appTabBinding: Binding<AppTab> {
        Binding(
            get: { Self.tab(for: tabSelection) ?? .today },
            set: { newTab in
                if newTab == .add {
                    showingLogSheet = true
                } else {
                    tabSelection = Self.string(for: newTab)
                }
            }
        )
    }

    private static func string(for tab: AppTab) -> String {
        switch tab {
        case .today: return "today"
        case .add: return "add"
        case .analytics: return "analytics"
        case .history: return "history"
        case .settings: return "settings"
        }
    }

    private static func tab(for id: String) -> AppTab? {
        switch id {
        case "today": return .today
        case "analytics": return .analytics
        case "history": return .history
        case "settings": return .settings
        default: return nil
        }
    }
}
