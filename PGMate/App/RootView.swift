import SwiftUI

struct RootView: View {
    @State private var auth = AuthService.shared

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}

// MARK: - Navy nav bar modifier
// Applied on each NavigationStack in addition to the global UINavigationBarAppearance,
// ensuring SwiftUI toolbars also pick up the navy theme.

struct NavyNavBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(Color.navyPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func navyNavBar() -> some View {
        modifier(NavyNavBar())
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            RoomGridView()
                .tabItem { Label("Rooms", systemImage: "bed.double.fill") }
            TenantListView()
                .tabItem { Label("Tenants", systemImage: "person.2.fill") }
            RentBoardView()
                .tabItem { Label("Rent", systemImage: "indianrupeesign.circle.fill") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .tint(Color.gold)
    }
}

// MARK: - MoreView

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: MaintenanceBoardView()) {
                        Label {
                            Text("Maintenance")
                                .foregroundStyle(Color.textPrimary)
                        } icon: {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundStyle(Color.gold)
                        }
                    }

                    NavigationLink(destination: ReportsView()) {
                        Label {
                            Text("Reports")
                                .foregroundStyle(Color.textPrimary)
                        } icon: {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(Color.gold)
                        }
                    }

                    NavigationLink(destination: SettingsView()) {
                        Label {
                            Text("Settings")
                                .foregroundStyle(Color.textPrimary)
                        } icon: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color.gold)
                        }
                    }
                }
                .listRowBackground(Color.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.bgSecondary.ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
        }
    }
}
