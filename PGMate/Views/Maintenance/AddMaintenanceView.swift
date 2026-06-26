import SwiftUI

struct AddMaintenanceView: View {
    let viewModel: MaintenanceViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var roomNumber = ""
    @State private var priority = MaintenanceTask.Priority.medium
    @State private var estimatedCost = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Title (required)", text: $title)

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)")
                                .foregroundColor(.secondary)
                                .font(.body)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 72)
                    }

                    TextField("Room Number (optional)", text: $roomNumber)
                        .keyboardType(.numberPad)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(MaintenanceTask.Priority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Estimated Cost") {
                    HStack {
                        Text("₹")
                            .foregroundColor(.secondary)
                        TextField("0", text: $estimatedCost)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Task") { saveTask() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isLoading)
                }
            }
        }
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveTask() {
        guard let propertyId = AuthService.shared.currentPropertyId else { return }
        isLoading = true

        let cost = Double(estimatedCost) ?? 0
        let task = MaintenanceTask(
            id: UUID().uuidString,
            propertyId: propertyId,
            roomNumber: roomNumber.trimmingCharacters(in: .whitespaces),
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            status: .open,
            priority: priority,
            estimatedCost: cost,
            createdAt: Date(),
            resolvedAt: nil
        )

        Task {
            await viewModel.addTask(task, propertyId: propertyId)
            await MainActor.run { dismiss() }
        }
    }
}
