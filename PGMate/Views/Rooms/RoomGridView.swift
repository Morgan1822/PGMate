import SwiftUI

struct RoomGridView: View {
    @State private var vm = RoomViewModel()
    @State private var showAddRoom = false
    @State private var selectedRoom: Room?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(RoomViewModel.RoomFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filterLabel(filter),
                                isSelected: vm.selectedFilter == filter
                            ) {
                                vm.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.surface)

                Divider()

                // MARK: Room grid
                if vm.isLoading {
                    VStack(spacing: 10) {
                        ProgressView().tint(Color.primaryIndigo)
                        Text("Loading...").foregroundStyle(Color.textSecondary).font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.filteredRooms.isEmpty {
                    EmptyStateView(
                        icon: "bed.double.fill",
                        title: vm.selectedFilter == .all
                            ? "No Rooms Added"
                            : "No \(vm.selectedFilter.rawValue) Rooms",
                        subtitle: vm.selectedFilter == .all
                            ? "Add rooms to get started"
                            : "No rooms with this status"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(vm.filteredRooms) { room in
                                RoomCard(room: room)
                                    .onTapGesture { selectedRoom = room }
                            }
                        }
                        .padding(16)
                    }
                    .refreshable { await vm.load() }
                }
            }
            .background(Color.backgroundLight)
            .navigationTitle("Rooms")
            .navigationBarTitleDisplayMode(.large)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddRoom = true }) {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(item: $selectedRoom) { room in
                RoomDetailView(room: room, viewModel: vm)
            }
            .sheet(isPresented: $showAddRoom) {
                AddRoomView(viewModel: vm)
            }
            .task { await vm.load() }
            .onChange(of: AuthService.shared.currentPropertyId) {
                Task { await vm.load() }
            }
        }
    }

    func filterLabel(_ filter: RoomViewModel.RoomFilter) -> String {
        switch filter {
        case .all:         return "All (\(vm.rooms.count))"
        case .vacant:      return "Vacant (\(vm.vacantCount))"
        case .occupied:    return "Occupied (\(vm.occupiedCount))"
        case .maintenance: return "Maintenance (\(vm.maintenanceCount))"
        }
    }
}

// MARK: - RoomCard

struct RoomCard: View {
    let room: Room

    var statusColor: Color {
        switch room.status {
        case .vacant:      return .successGreen
        case .occupied:    return .primaryIndigo
        case .maintenance: return .accentGold
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.roomNumber)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textDark)
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }

            Text(room.type.displayName)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Text(formatINR(room.monthlyRent) + "/mo")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryIndigo)

            Text(room.status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12), in: Capsule())
        }
        .padding(12)
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: statusColor.opacity(0.15), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.textOnPrimary : Color.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryIndigo : Color.surface, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
