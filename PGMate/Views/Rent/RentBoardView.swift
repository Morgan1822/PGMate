import SwiftUI

struct RentBoardView: View {
    @State private var vm = RentViewModel()
    @State private var selectedRecord: RentRecord?
    @State private var showRentReminder = false
    @State private var showOverdueSheet = false
    @State private var tenantPhones: [String: String] = [:]
    @State private var showNoPhoneAlert = false
    @State private var noPhoneAlertName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Month navigator
                HStack {
                    Button(action: { vm.navigateMonth(forward: false) }) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gold)
                    }
                    Spacer()
                    Text(vm.monthYearString)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button(action: { vm.navigateMonth(forward: true) }) {
                        Image(systemName: "chevron.right")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.bgPrimary)

                // MARK: Summary row
                HStack(spacing: 12) {
                    SmallMetricCard(
                        label: "Collected",
                        value: formatINR(vm.totalCollected),
                        color: .positive)
                    SmallMetricCard(
                        label: "Pending",
                        value: formatINR(vm.totalPending),
                        color: .pending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.bgPrimary)

                // MARK: Overdue banner
                if vm.overdueCount > 0 {
                    Button(action: { showOverdueSheet = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(vm.overdueCount) tenant(s) overdue")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)
                                Text("Tap to send WhatsApp reminders")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gold.opacity(0.10))
                        .overlay(
                            Rectangle().frame(height: 1).foregroundStyle(Color.gold.opacity(0.25)),
                            alignment: .bottom
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .background(Color.textTertiary.opacity(0.3))

                // MARK: Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(RentViewModel.RentFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filterLabel(filter),
                                isSelected: vm.selectedFilter == filter
                            ) {
                                vm.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.bgPrimary)

                // MARK: Records list
                if vm.isLoading {
                    VStack(spacing: 10) {
                        ProgressView().tint(Color.gold)
                        Text("Loading...").foregroundStyle(Color.textSecondary).font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary)
                } else if vm.filteredRecords.isEmpty {
                    EmptyStateView(
                        icon: "indianrupeesign.circle",
                        title: "No Rent Records",
                        subtitle: "Records appear when tenants are added")
                } else {
                    List {
                        ForEach(vm.filteredRecords) { record in
                            RentRecordRow(
                                record: record,
                                whatsAppAction: record.status == .overdue
                                    ? { sendWhatsApp(for: record) }
                                    : nil
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if record.status != .paid { selectedRecord = record }
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.bgSecondary.ignoresSafeArea())
                    .scrollContentBackground(.hidden)
                    .contentMargins(.bottom, 80, for: .scrollContent)
                    .refreshable { await vm.load() }
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Rent Board")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showRentReminder = true }) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Color.gold)
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordPaymentView(
                    record: record,
                    viewModel: vm,
                    tenantPhone: tenantPhones[record.tenantId] ?? "")
            }
            .sheet(isPresented: $showRentReminder) {
                RentReminderView(viewModel: vm)
            }
            .confirmationDialog(
                "\(vm.overdueCount) Overdue Tenant(s)",
                isPresented: $showOverdueSheet,
                titleVisibility: .visible
            ) {
                ForEach(vm.rentRecords.filter { $0.status == .overdue }) { record in
                    Button("\(record.tenantName) — \(formatINR(record.amount))") {
                        sendWhatsApp(for: record)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select a tenant to send a WhatsApp reminder")
            }
            .alert("No Phone Number", isPresented: $showNoPhoneAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No phone number for \(noPhoneAlertName). Add it in the tenant profile.")
            }
            .task {
                await vm.load()
                await loadTenantPhones()
            }
            .onChange(of: AuthService.shared.currentPropertyId) {
                Task {
                    await vm.load()
                    await loadTenantPhones()
                }
            }
        }
    }

    private func loadTenantPhones() async {
        guard let propertyId = AuthService.shared.currentPropertyId else { return }
        if let tenants = try? await FirestoreService.shared.fetchTenants(propertyId: propertyId) {
            tenantPhones = Dictionary(uniqueKeysWithValues: tenants.map { ($0.id, $0.phone) })
        }
    }

    private func sendWhatsApp(for record: RentRecord) {
        let phone = tenantPhones[record.tenantId] ?? ""
        let propertyName = AuthService.shared.propertyName.isEmpty
            ? "Management" : AuthService.shared.propertyName
        let message = "Dear \(record.tenantName), your rent of \(formatINR(record.amount)) for \(record.monthName) is overdue. Please pay at the earliest. - \(propertyName)"
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let cleanPhone = phone.filter { $0.isNumber }

        if cleanPhone.isEmpty {
            noPhoneAlertName = record.tenantName
            showNoPhoneAlert = true
            return
        }

        if let url = URL(string: "whatsapp://send?phone=91\(cleanPhone)&text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    func filterLabel(_ filter: RentViewModel.RentFilter) -> String {
        switch filter {
        case .all:     return "All (\(vm.rentRecords.count))"
        case .paid:    return "Paid (\(vm.paidCount))"
        case .pending: return "Pending (\(vm.pendingCount))"
        case .overdue: return "Overdue (\(vm.overdueCount))"
        }
    }
}

// MARK: - RentRecordRow

struct RentRecordRow: View {
    let record: RentRecord
    var whatsAppAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.tenantName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text("Room \(record.roomNumber)")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                if record.status == .paid, let paidDate = record.paidDate {
                    Text("Paid \(paidDate.formatted(.dateTime.day().month().year()))")
                        .font(.caption2)
                        .foregroundStyle(Color.positive)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatINR(record.amount))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                StatusBadge(
                    text: record.status.displayName,
                    color: record.status.color)
            }

            if let action = whatsAppAction {
                Button(action: action) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(red: 0.07, green: 0.53, blue: 0.32))
                }
                .buttonStyle(.plain)
            } else if record.status != .paid {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(14)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - SmallMetricCard

struct SmallMetricCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}
