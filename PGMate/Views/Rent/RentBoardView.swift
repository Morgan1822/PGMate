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
                            RentRecordRow(record: record)
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

            if record.status != .paid {
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
