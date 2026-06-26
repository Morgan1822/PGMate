import SwiftUI
import UIKit

struct RentReminderView: View {
    let viewModel: RentViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTenants: Set<String> = []

    var unpaidRecords: [RentRecord] {
        viewModel.rentRecords.filter { $0.status != .paid }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if unpaidRecords.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.seal.fill",
                        title: "All Rents Paid!",
                        subtitle: "No pending or overdue rent this month",
                        iconColor: .successGreen)
                } else {
                    // MARK: Select all toggle
                    HStack {
                        Text("Select tenants to remind")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        Button(selectedTenants.count == unpaidRecords.count
                               ? "Deselect All" : "Select All") {
                            if selectedTenants.count == unpaidRecords.count {
                                selectedTenants.removeAll()
                            } else {
                                selectedTenants = Set(unpaidRecords.map { $0.id })
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryIndigo)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    List {
                        ForEach(unpaidRecords) { record in
                            HStack(spacing: 12) {
                                Image(systemName: selectedTenants.contains(record.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedTenants.contains(record.id)
                                                     ? Color.primaryIndigo : Color.textSecondary)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.tenantName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Room \(record.roomNumber) • \(formatINR(record.amount))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                StatusBadge(
                                    text: record.status.displayName,
                                    color: record.status.color)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedTenants.contains(record.id) {
                                    selectedTenants.remove(record.id)
                                } else {
                                    selectedTenants.insert(record.id)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)

                    // MARK: Send button
                    Button(action: sendReminders) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Send via WhatsApp (\(selectedTenants.count))")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedTenants.isEmpty
                                    ? Color.gray.opacity(0.3)
                                    : Color(red: 0.07, green: 0.53, blue: 0.32))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedTenants.isEmpty)
                    .padding(16)
                }
            }
            .navigationTitle("Rent Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                selectedTenants = Set(unpaidRecords.map { $0.id })
            }
        }
    }

    func sendReminders() {
        let selected = unpaidRecords.filter { selectedTenants.contains($0.id) }

        for record in selected {
            let message = """
            Dear \(record.tenantName),

            Your rent of \(formatINR(record.amount)) for \(record.monthName) is due.

            Please make the payment at your earliest convenience.

            Thank you,
            \(viewModel.propertyName) Management
            """

            let encoded = message.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "whatsapp://send?text=\(encoded)") {
                UIApplication.shared.open(url)
            }
        }
        dismiss()
    }
}
