import Foundation

enum ValidationError: LocalizedError {
    case emptyEmail
    case invalidEmail
    case emptyPassword
    case passwordTooShort
    case emptyName
    case emptyPropertyName
    case emptyPhoneNumber
    case invalidPhoneNumber
    case emptyRoomNumber
    case emptyRent
    case invalidRent
    case phoneNumberTooShort
    case passwordMismatch
    case userAlreadyExists
    case invalidCredentials
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .emptyEmail:         return "Email address is required"
        case .invalidEmail:       return "Please enter a valid email address"
        case .emptyPassword:      return "Password is required"
        case .passwordTooShort:   return "Password must be at least 8 characters"
        case .emptyName:          return "Full name is required"
        case .emptyPropertyName:  return "Property name is required"
        case .emptyPhoneNumber:   return "Phone number is required"
        case .invalidPhoneNumber: return "Please enter a valid phone number"
        case .phoneNumberTooShort:return "Phone number must be at least 10 digits"
        case .emptyRoomNumber:    return "Room number is required"
        case .emptyRent:          return "Rent amount is required"
        case .invalidRent:        return "Please enter a valid rent amount"
        case .passwordMismatch:   return "Passwords do not match"
        case .userAlreadyExists:  return "Email already registered. Please sign in instead"
        case .invalidCredentials: return "Email or password is incorrect"
        case .networkError:       return "Network error. Please check your connection"
        case .unknown(let msg):   return msg
        }
    }

    // Maps Firebase Auth NSError codes to user-friendly ValidationError
    static func fromAuthError(_ error: Error) -> ValidationError {
        let code = (error as NSError).code
        switch code {
        case 17004, 17009, 17011: // invalidCredential, wrongPassword, userNotFound
            return .invalidCredentials
        case 17007: // emailAlreadyInUse
            return .userAlreadyExists
        case 17020: // networkError
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
