import SwiftUI

struct RentBoardView: View {
    @State private var vm = RentViewModel()
    @State private var selectedRecord: RentRecord?
    @State private var showRentReminder = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Month navigator
                HStack {
                    Button(action: { vm.navigateMonth(forward: false) }) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryIndigo)
                    }
                    Spacer()
                    Text(vm.monthYearString)
                        .font(.headline)
                        .foregroundColor(.textDark)
                    Spacer()
                    Button(action: { vm.navigateMonth(forward: true) }) {
                        Image(systemName: "chevron.right")
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryIndigo)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)

                // MARK: Summary row
                HStack(spacing: 12) {
                    SmallMetricCard(
                        label: "Collected",
                        value: formatINR(vm.totalCollected),
                        color: .successGreen)
                    SmallMetricCard(
                        label: "Pending",
                        value: formatINR(vm.totalPending),
                        color: .accentGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)

                Divider()

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
                .background(Color.backgroundLight)

                // MARK: Records list
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if vm.filteredRecords.isEmpty {
                    EmptyStateView(
                        icon: "indianrupeesign.circle",
                        title: "No Rent Records",
                        subtitle: "Records appear when tenants are added")
                } else {
                    List {
                        ForEach(vm.filteredRecords) { record in
                            RentRecordRow(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if record.status != .paid {
                                        selectedRecord = record
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.load() }
                }
            }
            .background(Color.backgroundLight)
            .navigationTitle("Rent Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showRentReminder = true }) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.primaryIndigo)
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordPaymentView(record: record, viewModel: vm)
            }
            .sheet(isPresented: $showRentReminder) {
                RentReminderView(viewModel: vm)
            }
            .task { await vm.load() }
            .onChange(of: AuthService.shared.currentPropertyId) {
                Task { await vm.load() }
            }
        }
    }

    func filterLabel(_ filter: RentViewModel.RentFilter) -> String {
        switch filter {
        case .all: return "All (\(vm.rentRecords.count))"
        case .paid: return "Paid (\(vm.paidCount))"
        case .pending: return "Pending (\(vm.pendingCount))"
        case .overdue: return "Overdue (\(vm.overdueCount))"
        }
    }
}

// MARK: - RentRecordRow

struct RentRecordRow: View {
    let record: RentRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.tenantName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textDark)
                Text("Room \(record.roomNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if record.status == .paid, let paidDate = record.paidDate {
                    Text("Paid \(paidDate.formatted(.dateTime.day().month().year()))")
                        .font(.caption2)
                        .foregroundColor(.successGreen)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatINR(record.amount))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.textDark)
                StatusBadge(
                    text: record.status.displayName,
                    color: record.status.color)
            }

            if record.status != .paid {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
