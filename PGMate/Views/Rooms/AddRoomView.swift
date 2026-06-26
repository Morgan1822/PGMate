import SwiftUI

struct AddRoomView: View {
    let viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    @State private var roomNumber = ""
    @State private var floor = 1
    @State private var type = Room.RoomType.single
    @State private var monthlyRent = ""
    @State private var status = Room.RoomStatus.vacant
    @State private var amenities: Set<String> = []
    @State private var isLoading = false

    let amenityOptions = ["WiFi", "AC", "Fan", "Attached Bathroom", "Geyser", "TV"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Room Info") {
                    TextField("Room Number (e.g. 101)", text: $roomNumber)
                    Stepper("Floor: \(floor)", value: $floor, in: 1...20)
                    Picker("Type", selection: $type) {
                        ForEach(Room.RoomType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    TextField("Monthly Rent (₹)", text: $monthlyRent)
                        .keyboardType(.numberPad)
                    Picker("Status", selection: $status) {
                        ForEach(Room.RoomStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }

                Section("Amenities") {
                    ForEach(amenityOptions, id: \.self) { amenity in
                        HStack {
                            Text(amenity)
                            Spacer()
                            if amenities.contains(amenity) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.primaryIndigo)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if amenities.contains(amenity) {
                                amenities.remove(amenity)
                            } else {
                                amenities.insert(amenity)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveRoom() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isLoading)
                }
            }
        }
    }

    var canSave: Bool {
        !roomNumber.isEmpty && !monthlyRent.isEmpty && Double(monthlyRent) != nil
    }

    func saveRoom() {
        guard let rent = Double(monthlyRent),
              let propertyId = AuthService.shared.currentPropertyId
        else { return }

        isLoading = true
        let room = Room(
            id: UUID().uuidString,
            propertyId: propertyId,
            roomNumber: roomNumber,
            floor: floor,
            type: type,
            monthlyRent: rent,
            status: status,
            amenities: Array(amenities)
        )

        Task {
            do {
                try await FirestoreService.shared.saveRoom(room, propertyId: propertyId)
                await viewModel.load()
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
