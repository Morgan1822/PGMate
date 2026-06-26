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
                        .foregroundStyle(Color.textPrimary)

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)")
                                .foregroundStyle(Color.textSecondary)
                                .font(.body)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .foregroundStyle(Color.textPrimary)
                            .frame(minHeight: 72)
                    }

                    TextField("Room Number (optional)", text: $roomNumber)
                        .foregroundStyle(Color.textPrimary)
                        .keyboardType(.numberPad)
                }
                .listRowBackground(Color.surface)

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(MaintenanceTask.Priority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.gold)
                }
                .listRowBackground(Color.surface)

                Section("Estimated Cost") {
                    HStack {
                        Text("₹")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gold)
                        TextField("0", text: $estimatedCost)
                            .foregroundStyle(Color.textPrimary)
                            .keyboardType(.numberPad)
                    }
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgSecondary.ignoresSafeArea())
            .tint(Color.gold)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Task") { saveTask() }
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave && !isLoading ? Color.gold : Color.textSecondary)
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
