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

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            RoomGridView()
                .tabItem {
                    Label("Rooms", systemImage: "bed.double.fill")
                }
            TenantListView()
                .tabItem {
                    Label("Tenants", systemImage: "person.2.fill")
                }
            RentBoardView()
                .tabItem {
                    Label("Rent", systemImage: "indianrupeesign.circle.fill")
                }
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(.primaryIndigo)
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: MaintenanceBoardView()) {
                    Label("Maintenance", systemImage: "wrench.and.screwdriver.fill")
                }
                NavigationLink(destination: ReportsView()) {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("More")
        }
    }
}
