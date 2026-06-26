import SwiftUI
import Charts
import PDFKit

struct ReportsView: View {
    @State private var viewModel = ReportsViewModel()
    private let auth = AuthService.shared

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading reports…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let errorMessage = viewModel.errorMessage {
                                errorBanner(errorMessage)
                            }
                            PLCard(
                                viewModel: viewModel,
                                propertyName: auth.propertyName
                            )
                            TrendChartSection(viewModel: viewModel)
                            MonthTableSection(viewModel: viewModel)
                            ExportSection(
                                viewModel: viewModel,
                                propertyName: auth.propertyName
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Reports")
            .navyNavBar()
            .task {
                if let pid = auth.currentPropertyId {
                    await viewModel.fetchReports(propertyId: pid)
                }
            }
            .refreshable {
                if let pid = auth.currentPropertyId {
                    await viewModel.fetchReports(propertyId: pid)
                }
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - P&L Card

private struct PLCard: View {
    @Bindable var viewModel: ReportsViewModel
    let propertyName: String

    private var calendar: Calendar { .current }
    private var canGoForward: Bool {
        !calendar.isDate(viewModel.selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation header
            HStack {
                Button {
                    if let prev = calendar.date(byAdding: .month, value: -1, to: viewModel.selectedMonth) {
                        viewModel.selectedMonth = prev
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text(viewModel.selectedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)

                Spacer()

                Button {
                    if let next = calendar.date(byAdding: .month, value: 1, to: viewModel.selectedMonth) {
                        viewModel.selectedMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(canGoForward ? .primary : .tertiary)
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            if let report = viewModel.currentMonthReport {
                VStack(spacing: 12) {
                    PLRow(label: "Gross Collected",
                          amount: report.grossCollected,
                          color: .successGreen)
                    PLRow(label: "Maintenance Cost",
                          amount: report.maintenanceCost,
                          color: .red)

                    Divider()

                    // Net profit — large and bold
                    HStack {
                        Text("Net Profit")
                            .font(.title3).fontWeight(.bold)
                        Spacer()
                        Text(formatINR(report.netProfit))
                            .font(.title3).fontWeight(.bold)
                            .foregroundStyle(report.netProfit >= 0 ? Color.successGreen : Color.red)
                    }

                    // Month-over-month delta
                    deltaView(for: report)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(16)
            } else {
                Text("No records for this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    @ViewBuilder
    private func deltaView(for report: MonthlyReport) -> some View {
        let sorted = viewModel.monthlyData.sorted { $0.month < $1.month }
        if let idx = sorted.firstIndex(where: { $0.id == report.id }), idx > 0 {
            let prev = sorted[idx - 1]
            let diff = report.netProfit - prev.netProfit
            if diff > 0 {
                Label("↑ \(formatINR(diff)) vs last month", systemImage: "")
                    .font(.caption)
                    .foregroundStyle(Color.successGreen)
                    .labelStyle(.titleOnly)
            } else if diff < 0 {
                Label("↓ \(formatINR(abs(diff))) vs last month", systemImage: "")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .labelStyle(.titleOnly)
            } else {
                Text("— same as last month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PLRow: View {
    let label: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatINR(amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Trend Chart

private struct TrendChartSection: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend")
                .font(.headline)

            if viewModel.monthlyData.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                Chart(viewModel.monthlyData.sorted { $0.month < $1.month }) { report in
                    BarMark(
                        x: .value("Month", shortMonthName(report.month)),
                        y: .value("Net Profit", report.netProfit)
                    )
                    .foregroundStyle(barColor(for: report))
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(preset: .extended) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(abbreviatedINR(v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                if let month: String = proxy.value(atX: location.x) {
                                    selectMonth(matching: month)
                                }
                            }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func barColor(for report: MonthlyReport) -> Color {
        let isSelected = Calendar.current.isDate(
            report.month, equalTo: viewModel.selectedMonth, toGranularity: .month)
        let base: Color = report.netProfit >= 0 ? .successGreen : .red
        return isSelected ? base : base.opacity(0.55)
    }

    private func shortMonthName(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    private func selectMonth(matching abbrev: String) {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        if let match = viewModel.monthlyData.first(where: {
            f.string(from: $0.month) == abbrev
        }) {
            viewModel.selectedMonth = match.month
        }
    }
}

private func abbreviatedINR(_ value: Double) -> String {
    let abs = Swift.abs(value)
    let sign = value < 0 ? "-" : ""
    if abs >= 1_000_000 {
        return "\(sign)₹\(String(format: "%.1f", abs / 1_000_000))L"
    } else if abs >= 1_000 {
        return "\(sign)₹\(String(format: "%.0f", abs / 1_000))K"
    }
    return "\(sign)₹\(Int(abs))"
}

// MARK: - Month Table

private struct MonthTableSection: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Month by Month")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider()

            let sorted = viewModel.monthlyData.sorted { $0.month > $1.month }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, report in
                Button {
                    viewModel.selectedMonth = report.month
                } label: {
                    HStack {
                        Text(report.month.formatted(.dateTime.month(.wide).year()))
                            .font(.subheadline)
                            .foregroundStyle(
                                Calendar.current.isDate(report.month,
                                    equalTo: viewModel.selectedMonth,
                                    toGranularity: .month)
                                ? Color.accentColor : Color.primary
                            )

                        Spacer()

                        Text(formatINR(report.netProfit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(report.netProfit >= 0 ? Color.successGreen : Color.red)

                        // Delta vs previous month
                        let sortedAsc = viewModel.monthlyData.sorted { $0.month < $1.month }
                        if let thisIdx = sortedAsc.firstIndex(where: { $0.id == report.id }),
                           thisIdx > 0 {
                            let diff = report.netProfit - sortedAsc[thisIdx - 1].netProfit
                            Text(diff >= 0 ? "↑ \(abbreviatedINR(diff))" : "↓ \(abbreviatedINR(abs(diff)))")
                                .font(.caption)
                                .foregroundStyle(diff >= 0 ? Color.successGreen : Color.red)
                                .frame(width: 64, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Calendar.current.isDate(report.month,
                            equalTo: viewModel.selectedMonth,
                            toGranularity: .month)
                        ? Color.accentColor.opacity(0.07) : Color.clear
                    )
                }
                .buttonStyle(.plain)

                if idx < sorted.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }

            if viewModel.monthlyData.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            }

            Divider()
            // Totals row
            if !viewModel.monthlyData.isEmpty {
                let totalProfit = viewModel.monthlyData.reduce(0) { $0 + $1.netProfit }
                HStack {
                    Text("6-Month Total")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatINR(totalProfit))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(totalProfit >= 0 ? Color.successGreen : Color.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Export Section

private struct ExportSection: View {
    let viewModel: ReportsViewModel
    let propertyName: String

    @State private var pdfData: Data?
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 12) {
            Button {
                if let report = viewModel.currentMonthReport {
                    pdfData = buildSingleMonthPDF(report: report, propertyName: propertyName)
                    showShareSheet = true
                }
            } label: {
                Label("Export This Month → PDF", systemImage: "arrow.down.doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.currentMonthReport == nil)

            Button {
                pdfData = buildSixMonthPDF(
                    reports: viewModel.monthlyData.sorted { $0.month < $1.month },
                    propertyName: propertyName
                )
                showShareSheet = true
            } label: {
                Label("Export 6 Months → PDF", systemImage: "doc.richtext.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.monthlyData.isEmpty)
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheetView(items: [data])
            }
        }
    }
}

// MARK: - ShareSheetView

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Builders

private func buildSingleMonthPDF(report: MonthlyReport, propertyName: String) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    return renderer.pdfData { ctx in
        ctx.beginPage()
        let title = "PGMate Report — \(report.month.formatted(.dateTime.month(.wide).year()))"
        drawPDFHeader(title: title, subtitle: propertyName, pageRect: pageRect)
        var y: CGFloat = 120

        let rows: [(String, String, UIColor)] = [
            ("Gross Collected", formatINR(report.grossCollected), UIColor.systemGreen),
            ("Maintenance Cost", formatINR(report.maintenanceCost), UIColor.systemRed),
            ("Pending Rent", formatINR(report.pendingRent), UIColor.systemOrange),
            ("Net Profit", formatINR(report.netProfit),
             report.netProfit >= 0 ? UIColor.systemGreen : UIColor.systemRed)
        ]

        for (label, value, color) in rows {
            drawPDFRow(label: label, value: value, color: color, y: y, pageRect: pageRect)
            y += 44
        }

        drawPDFFooter(pageRect: pageRect)
    }
}

private func buildSixMonthPDF(reports: [MonthlyReport], propertyName: String) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    return renderer.pdfData { ctx in
        ctx.beginPage()
        drawPDFHeader(title: "PGMate 6-Month Report", subtitle: propertyName, pageRect: pageRect)
        var y: CGFloat = 130

        // Column headers
        drawPDFTableHeader(y: y, pageRect: pageRect)
        y += 32

        for report in reports {
            let monthStr = report.month.formatted(.dateTime.month(.wide).year())
            let netColor: UIColor = report.netProfit >= 0 ? .systemGreen : .systemRed
            drawPDFTableRow(
                col1: monthStr,
                col2: formatINR(report.grossCollected),
                col3: formatINR(report.maintenanceCost),
                col4: formatINR(report.netProfit),
                col4Color: netColor,
                y: y,
                pageRect: pageRect
            )
            y += 34
        }

        // Totals row
        let totalCollected = reports.reduce(0) { $0 + $1.grossCollected }
        let totalMaint = reports.reduce(0) { $0 + $1.maintenanceCost }
        let totalProfit = reports.reduce(0) { $0 + $1.netProfit }

        UIColor.systemGray5.setFill()
        UIRectFill(CGRect(x: 40, y: y, width: pageRect.width - 80, height: 34))

        drawPDFTableRow(
            col1: "TOTAL",
            col2: formatINR(totalCollected),
            col3: formatINR(totalMaint),
            col4: formatINR(totalProfit),
            col4Color: totalProfit >= 0 ? .systemGreen : .systemRed,
            y: y,
            pageRect: pageRect,
            bold: true
        )

        drawPDFFooter(pageRect: pageRect)
    }
}

private func drawPDFHeader(title: String, subtitle: String, pageRect: CGRect) {
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 20),
        .foregroundColor: UIColor.label
    ]
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 13),
        .foregroundColor: UIColor.secondaryLabel
    ]
    title.draw(at: CGPoint(x: 40, y: 36), withAttributes: titleAttrs)
    subtitle.draw(at: CGPoint(x: 40, y: 64), withAttributes: subAttrs)

    UIColor.systemGray4.setStroke()
    let line = UIBezierPath()
    line.move(to: CGPoint(x: 40, y: 90))
    line.addLine(to: CGPoint(x: pageRect.width - 40, y: 90))
    line.lineWidth = 0.5
    line.stroke()
}

private func drawPDFRow(label: String, value: String, color: UIColor, y: CGFloat, pageRect: CGRect) {
    let labelAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.secondaryLabel
    ]
    let valueAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 14),
        .foregroundColor: color
    ]

    label.draw(at: CGPoint(x: 48, y: y + 12), withAttributes: labelAttrs)
    let valueStr = value as NSString
    let valueSize = valueStr.size(withAttributes: valueAttrs)
    valueStr.draw(at: CGPoint(x: pageRect.width - 48 - valueSize.width, y: y + 12),
                  withAttributes: valueAttrs)

    UIColor.systemGray5.setFill()
    UIRectFill(CGRect(x: 40, y: y + 38, width: pageRect.width - 80, height: 0.5))
}

private func drawPDFTableHeader(y: CGFloat, pageRect: CGRect) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 11),
        .foregroundColor: UIColor.secondaryLabel
    ]
    let colW = (pageRect.width - 80) / 4
    let labels = ["Month", "Collected", "Maintenance", "Net Profit"]
    for (i, label) in labels.enumerated() {
        label.draw(at: CGPoint(x: 40 + CGFloat(i) * colW, y: y), withAttributes: attrs)
    }
    UIColor.systemGray3.setStroke()
    let line = UIBezierPath()
    line.move(to: CGPoint(x: 40, y: y + 20))
    line.addLine(to: CGPoint(x: pageRect.width - 40, y: y + 20))
    line.lineWidth = 0.5
    line.stroke()
}

private func drawPDFTableRow(col1: String, col2: String, col3: String, col4: String,
                              col4Color: UIColor, y: CGFloat, pageRect: CGRect, bold: Bool = false) {
    let font: UIFont = bold ? .boldSystemFont(ofSize: 12) : .systemFont(ofSize: 12)
    let defaultAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
    let col4Attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: col4Color]

    let colW = (pageRect.width - 80) / 4
    col1.draw(at: CGPoint(x: 40, y: y + 8), withAttributes: defaultAttrs)
    col2.draw(at: CGPoint(x: 40 + colW, y: y + 8), withAttributes: defaultAttrs)
    col3.draw(at: CGPoint(x: 40 + colW * 2, y: y + 8), withAttributes: defaultAttrs)
    col4.draw(at: CGPoint(x: 40 + colW * 3, y: y + 8), withAttributes: col4Attrs)
}

private func drawPDFFooter(pageRect: CGRect) {
    let dateStr = Date().formatted(.dateTime.day().month().year())
    let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10),
        .foregroundColor: UIColor.tertiaryLabel
    ]
    let text = "Generated by PGMate on \(dateStr)"
    let size = (text as NSString).size(withAttributes: attrs)
    (text as NSString).draw(
        at: CGPoint(x: (pageRect.width - size.width) / 2, y: pageRect.height - 40),
        withAttributes: attrs
    )
}
