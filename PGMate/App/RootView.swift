import SwiftUI

struct RootView: View {
    @State private var auth = AuthService.shared
    @State private var showSplash = true

    var body: some View {
        if showSplash {
            SplashScreenView()
                .task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
        } else {
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
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // All tabs kept alive — only the active one receives input
            ZStack {
                DashboardView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)
                RoomGridView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)
                TenantListView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)
                RentBoardView()
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)
                MoreView()
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 4)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 49)
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
        .tint(Color.gold)
    }
}

// MARK: - CustomTabBar

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let items: [(icon: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("bed.double.fill", "Rooms"),
        ("person.2.fill", "Tenants"),
        ("indianrupeesign.circle.fill", "Rent"),
        ("ellipsis.circle.fill", "More")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                Button {
                    selectedTab = i
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: items[i].icon)
                            .font(.system(size: 22, weight: .medium))
                        Text(items[i].label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == i ? Color.gold : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color.navyPrimary.ignoresSafeArea(edges: .bottom))
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
