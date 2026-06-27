import SwiftUI

struct RecordPaymentView: View {
    let record: RentRecord
    let viewModel: RentViewModel
    var tenantPhone: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var paymentMethod = RentRecord.PaymentMethod.upi
    @State private var upiTransactionId = ""
    @State private var paidDate = Date()
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Overdue banner
                if record.status == .overdue {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.gold)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This tenant has overdue rent")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)
                                Button(action: sendWhatsAppReminder) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "message.fill")
                                            .font(.caption)
                                        Text("Send WhatsApp Reminder")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(Color(red: 0.07, green: 0.53, blue: 0.32))
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.gold.opacity(0.08))
                }

                // MARK: Payment Details
                Section("Payment Details") {
                    LabeledContent("Tenant", value: record.tenantName)
                    LabeledContent("Room", value: record.roomNumber)
                    LabeledContent("Amount", value: formatINR(record.amount))
                    LabeledContent("Month", value: record.monthName)
                }

                // MARK: Payment Method
                Section("Payment Method") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach([
                            RentRecord.PaymentMethod.upi,
                            .cash,
                            .bankTransfer
                        ], id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    if paymentMethod == .upi {
                        TextField("UPI Transaction ID", text: $upiTransactionId)
                            .autocapitalization(.none)
                    }

                    DatePicker("Date Paid",
                        selection: $paidDate,
                        displayedComponents: .date)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { savePayment() }
                        .fontWeight(.semibold)
                        .disabled(isLoading)
                }
            }
        }
    }

    func sendWhatsAppReminder() {
        let propertyName = AuthService.shared.propertyName.isEmpty
            ? "Management" : AuthService.shared.propertyName
        let message = "Dear \(record.tenantName), your rent of \(formatINR(record.amount)) for \(record.monthName) is overdue. Please pay at the earliest. - \(propertyName)"
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let cleanPhone = tenantPhone.filter { $0.isNumber }
        let urlString = cleanPhone.isEmpty
            ? "whatsapp://send?text=\(encoded)"
            : "whatsapp://send?phone=91\(cleanPhone)&text=\(encoded)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    func savePayment() {
        isLoading = true
        Task {
            do {
                try await viewModel.recordPayment(
                    record: record,
                    method: paymentMethod,
                    upiTransactionId: upiTransactionId.isEmpty ? nil : upiTransactionId,
                    paidDate: paidDate)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
