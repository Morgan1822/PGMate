import Foundation

func formatINR(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "₹"
    formatter.currencyGroupingSeparator = ","
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 0
    formatter.locale = Locale(identifier: "en_IN")
    return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
}
