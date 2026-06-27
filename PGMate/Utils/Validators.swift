import Foundation

struct Validators {
    static func validateEmail(_ email: String) -> ValidationError? {
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            return .emptyEmail
        }
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        if regex?.firstMatch(in: email, range: range) == nil {
            return .invalidEmail
        }
        return nil
    }

    static func validatePassword(_ password: String) -> ValidationError? {
        if password.isEmpty { return .emptyPassword }
        if password.count < 8 { return .passwordTooShort }
        return nil
    }

    static func validateName(_ name: String) -> ValidationError? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return .emptyName }
        return nil
    }

    static func validatePhoneNumber(_ phone: String) -> ValidationError? {
        let cleaned = phone.filter { $0.isNumber }
        if cleaned.isEmpty { return .emptyPhoneNumber }
        if cleaned.count < 10 { return .phoneNumberTooShort }
        return nil
    }

    static func validateRentAmount(_ amount: String) -> ValidationError? {
        if amount.trimmingCharacters(in: .whitespaces).isEmpty { return .emptyRent }
        guard let value = Double(amount), value > 0 else { return .invalidRent }
        return nil
    }

    static func validatePasswordMatch(_ password: String, _ confirmPassword: String) -> ValidationError? {
        if password != confirmPassword { return .passwordMismatch }
        return nil
    }
}
