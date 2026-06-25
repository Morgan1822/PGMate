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
                        .foregroundColor(.secondary)
                    TextField("Search tenants...", text: $vm.searchText)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)

                Divider()

                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
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
                    .refreshable { await vm.load() }
                }
            }
            .background(Color.backgroundLight)
            .navigationTitle("Tenants")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddTenant = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
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
                    .fill(Color.primaryIndigo.opacity(0.12))
                    .frame(width: 48, height: 48)
                if let photoURL = tenant.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Text(tenant.initials)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryIndigo)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                } else {
                    Text(tenant.initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryIndigo)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(tenant.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textDark)
                Text("Room \(tenant.roomNumber) • \(tenant.phone)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                StatusBadge(text: "Active", color: .successGreen)
                Text("\(tenant.monthsStayed)mo")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
