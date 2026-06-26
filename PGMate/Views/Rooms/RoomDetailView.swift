import SwiftUI

struct RoomDetailView: View {
    let room: Room
    let viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedStatus: Room.RoomStatus

    init(room: Room, viewModel: RoomViewModel) {
        self.room = room
        self.viewModel = viewModel
        self._selectedStatus = State(initialValue: room.status)
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Room info
                Section("Room Details") {
                    LabeledContent("Room Number", value: room.roomNumber)
                    LabeledContent("Type", value: room.type.displayName)
                    LabeledContent("Floor", value: "Floor \(room.floor)")
                    LabeledContent("Monthly Rent", value: formatINR(room.monthlyRent))
                }

                // MARK: Status
                Section("Status") {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(Room.RoomStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: Amenities
                if !room.amenities.isEmpty {
                    Section("Amenities") {
                        FlowLayout(items: room.amenities) { amenity in
                            Text(amenity)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.primaryIndigo.opacity(0.1))
                                .foregroundStyle(Color.primaryIndigo)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .navigationTitle("Room \(room.roomNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.updateStatus(room: room, status: selectedStatus)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedStatus == room.status)
                }
            }
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout<T: Hashable, Content: View>: View {
    let items: [T]
    let content: (T) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    content(item)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
