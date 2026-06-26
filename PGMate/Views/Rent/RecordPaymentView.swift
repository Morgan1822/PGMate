import SwiftUI

struct RecordPaymentView: View {
    let record: RentRecord
    let viewModel: RentViewModel
    @Environment(\.dismiss) var dismiss
    @State private var paymentMethod = RentRecord.PaymentMethod.upi
    @State private var upiTransactionId = ""
    @State private var paidDate = Date()
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    LabeledContent("Tenant", value: record.tenantName)
                    LabeledContent("Room", value: record.roomNumber)
                    LabeledContent("Amount", value: formatINR(record.amount))
                    LabeledContent("Month", value: record.monthName)
                }

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
