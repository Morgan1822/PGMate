import SwiftUI

struct TenantListView: View {
    @State private var vm = TenantViewModel()
    @State private var showAddTenant = false
    @State private var selectedTenant: Tenant?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textSecondary)
                    TextField("Search tenants...", text: $vm.searchText)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(12)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.textTertiary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.bgPrimary)

                Divider()
                    .background(Color.textTertiary.opacity(0.3))

                if vm.isLoading {
                    VStack(spacing: 10) {
                        ProgressView().tint(Color.gold)
                        Text("Loading...").foregroundStyle(Color.textSecondary).font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary)
                } else if vm.filteredTenants.isEmpty {
                    EmptyStateView(
                        icon: "person.2.slash.fill",
                        title: vm.searchText.isEmpty ? "No Tenants Yet" : "No Results",
                        subtitle: vm.searchText.isEmpty
                            ? "Add your first tenant using the + button"
                            : "Try a different search term"
                    )
                } else {
                    List {
                        ForEach(vm.filteredTenants) { tenant in
                            TenantRow(tenant: tenant)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedTenant = tenant }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.bgSecondary.ignoresSafeArea())
                    .scrollContentBackground(.hidden)
                    .refreshable { await vm.load() }
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Tenants")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddTenant = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gold)
                    }
                }
            }
            .sheet(item: $selectedTenant) { tenant in
                TenantDetailView(tenant: tenant, viewModel: vm)
            }
            .sheet(isPresented: $showAddTenant) {
                AddTenantView(viewModel: vm)
            }
            .task { await vm.load() }
            .onChange(of: AuthService.shared.currentPropertyId) {
                Task { await vm.load() }
            }
        }
    }
}

// MARK: - TenantRow

struct TenantRow: View {
    let tenant: Tenant

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.navyLight)
                    .frame(width: 48, height: 48)
                if let data = UserDefaults.standard.data(forKey: "tenant_photo_\(tenant.id)"),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Text(tenant.initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(tenant.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text("Room \(tenant.roomNumber) • \(tenant.phone)")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                StatusBadge(text: "Active", color: .positive)
                Text("\(tenant.monthsStayed)mo")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(14)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
