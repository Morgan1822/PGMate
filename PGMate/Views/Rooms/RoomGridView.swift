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
                .background(Color.bgPrimary)

                Divider()
                    .background(Color.textTertiary.opacity(0.3))

                // MARK: Room grid
                if vm.isLoading {
                    VStack(spacing: 10) {
                        ProgressView().tint(Color.gold)
                        Text("Loading...").foregroundStyle(Color.textSecondary).font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary.ignoresSafeArea())
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
                    .contentMargins(.bottom, 80, for: .scrollContent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgSecondary)
                    .refreshable { await vm.load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgSecondary.ignoresSafeArea())
            .ignoresSafeArea(.all, edges: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle("Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddRoom = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gold)
                    }
                }
            }
            .sheet(item: $selectedRoom) { room in
                RoomDetailView(room: room, viewModel: vm)
            }
            .sheet(isPresented: $showAddRoom) {
                AddRoomView(viewModel: vm)
            }
            .tint(Color.gold)
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
        case .vacant:      return .positive
        case .occupied:    return Color(hex: "#5B8FE8")
        case .maintenance: return .warning
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: room number + status dot
            HStack(alignment: .top) {
                Text(room.roomNumber)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }

            // Room type
            Text(room.type.displayName)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 4)

            Spacer(minLength: 6)

            // Rent amount
            Text(formatINR(room.monthlyRent) + "/mo")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, 5)

            // Status pill
            Text(room.status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12), in: Capsule())
                .lineLimit(1)
        }
        .padding(12)
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusColor.opacity(0.35), lineWidth: 1.5)
        )
        .clipped()
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
                .foregroundStyle(isSelected ? Color.textOnNavy : Color.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.navyPrimary : Color.surface, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.textTertiary.opacity(0.4), lineWidth: 1)
                )
        }
    }
}
