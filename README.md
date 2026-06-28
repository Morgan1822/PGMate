# PGMate 🏘️

A comprehensive **hostel and PG (paying guest) management app** for property owners in India. Built with SwiftUI, Firebase, and a focus on simplifying tenant lifecycle and financial management.

**Status:** App Store submission in progress (v1.0.0)  
**Support:** [Support Portal](https://morgan1822.github.io/PGMate/support.html)

---

## ✨ Features

### Phase 1 (Current Release)

**Dashboard**
- Occupancy ring chart with real-time vacancy tracking
- Financial summary with current period calculations
- Alert notifications for important events
- Quick action buttons for common tasks
- Recent activity timeline

**Room Management**
- Color-coded room status grid
- Filter chips for quick navigation (All, Occupied, Vacant, Maintenance)
- Room details with tenant assignment

**Tenant Management**
- Comprehensive tenant list with quick details
- Add new tenants with:
  - Camera photo capture & Contacts integration
  - Profile management
  - Document tracking
- Tenant detail view with contact options

**Rent Board**
- Track rent status: Paid, Pending, Overdue
- WhatsApp integration for payment reminders (deep link support)
- Indian currency (₹) formatting
- Payment history and due date tracking

**Maintenance & Complaints**
- Kanban board for maintenance tasks (To Do, In Progress, Completed)
- Filter chips and metric cards
- Complaint logging and tracking

**Financial Reports**
- Profit & Loss statement with detailed tracking
- 6-month financial trend chart
- Period-based revenue and expense analysis

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM + Clean Architecture |
| **Reactive** | @Observable (iOS 17+) |
| **Backend** | Firebase (Auth + Firestore + Crashlytics) |
| **Deployment** | iOS 17+ |
| **Theme** | Custom design system (Indigo/Gold/Green) |

### Color Palette
- **Primary:** Indigo `#3D5A99`
- **Accent:** Gold `#E8A33D`
- **Success:** Green `#4A9B6E`

---

## 📋 Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+** deployment target
- **CocoaPods** (for Firebase SPM)
- Apple Developer Program membership (for App Store submission)

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/Morgan1822/PGMate.git
cd PGMate
```

### 2. Open in Xcode
```bash
open PGMate.xcodeproj
```

### 3. Firebase Configuration
- Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
- Download `GoogleService-Info.plist` for both **Dev** and **Prod** environments
- Place configuration files in the Xcode project
- Enable:
  - Email/Password Authentication
  - Sign in with Apple
  - Firestore Database (Test mode for development)
  - Crashlytics

### 4. Configure Build Schemes
PGMate uses **dual Firebase environments**:

**Development Scheme:**
- Bundle ID: `com.vinothv.PGMate.dev`
- GoogleService-Info: Dev configuration

**Production Scheme:**
- Bundle ID: `com.vinothv.PGMate`
- GoogleService-Info: Production configuration

Switch schemes via Product → Scheme in Xcode.

### 5. Build & Run
```bash
# Ensure all SPM packages are resolved
# Product → Build (⌘B)
# Product → Run (⌘R)
```

---

## 📁 Project Structure

```
PGMate/
├── PGMate/
│   ├── App/
│   │   ├── PGMateApp.swift          # SwiftUI app entry point
│   │   └── AppDelegate.swift        # Firebase initialization
│   ├── Features/
│   │   ├── Dashboard/
│   │   ├── Rooms/
│   │   ├── Tenants/
│   │   ├── RentBoard/
│   │   ├── Maintenance/
│   │   ├── Complaints/
│   │   └── Reports/
│   ├── Services/
│   │   ├── FirebaseService.swift
│   │   ├── FirestoreManager.swift
│   │   └── AuthService.swift
│   ├── Models/
│   │   ├── Room.swift
│   │   ├── Tenant.swift
│   │   ├── Rent.swift
│   │   └── Maintenance.swift
│   ├── Utilities/
│   │   ├── CurrencyFormatter.swift
│   │   └── DateFormatter.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Localizable.strings
├── PGMate.xcodeproj
└── README.md
```

---

## 🔐 Authentication

PGMate supports two authentication methods:

### Email & Password
- Secure password storage via Firebase
- Email verification flow
- Password reset capability

### Sign in with Apple
- Native iOS integration
- Privacy-focused (email relay supported)
- Automatic account linking

---

## 🗄️ Database Schema (Firestore)

### Collections

**users/**
```
{
  uid: String,
  email: String,
  displayName: String,
  role: "owner" | "clinician" (Phase 2),
  createdAt: Timestamp
}
```

**properties/{propertyId}/rooms/**
```
{
  roomId: String,
  roomNumber: String,
  status: "occupied" | "vacant" | "maintenance",
  capacity: Int,
  currentTenant: String (tenantId) | null,
  monthlyRent: Double
}
```

**properties/{propertyId}/tenants/**
```
{
  tenantId: String,
  name: String,
  phone: String,
  email: String,
  photo: URL,
  roomId: String,
  checkInDate: Timestamp,
  checkOutDate: Timestamp | null,
  status: "active" | "inactive"
}
```

**properties/{propertyId}/rent_records/**
```
{
  recordId: String,
  tenantId: String,
  month: Timestamp,
  amount: Double,
  status: "paid" | "pending" | "overdue",
  dueDate: Timestamp,
  paidDate: Timestamp | null
}
```

---

## 📱 Integrations

### WhatsApp
- Deep link support for rent payment reminders
- Tenant notification system
- Message templates (Phase 2)

### Contacts Framework
- Import tenant contact details
- Phone number extraction
- Photo sync

### iOS 17+ Features
- `@Observable` macro for reactive updates
- Native SwiftUI environment integration
- Modern concurrency (async/await)

---

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
⌘U in Xcode
```

### Firebase Verification Checklist (Phase 1)
- [ ] New owner account creation
- [ ] Firestore data persistence
- [ ] Authentication flow
- [ ] Room management CRUD
- [ ] Financial calculations

---

## 🚧 Roadmap

### Phase 1 (Current)
✅ Owner dashboard & room management
✅ Tenant lifecycle tracking
✅ Rent payment tracking
✅ Maintenance & complaints
✅ Financial reports

### Phase 2 (Planned)
- Tenant login & portal
- Visitor log & management
- Notice board with badge count
- SMS notifications (Fast2SMS integration)
- Web CRM portal for owners
- Payment collection gateway

### Phase 3+ (Future)
- Multi-property support
- Advanced analytics & forecasting
- Expense tracking & budgeting
- Legal document templates
- Tenant credit scoring

---

## 🐛 Known Issues & Limitations

- Phase 2 features (tenant login, visitor log) not yet implemented
- Fast2SMS integration pending for Phase 1 completion
- Delete account functionality in progress

---

## 📝 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Vinoth Vivekanandan**  
iOS Developer | Chennai, India  
📧 [vinothvivekanandan22@gmail.com](mailto:vinothvivekanandan22@gmail.com)  
🔗 [GitHub](https://github.com/Morgan1822) | [Portfolio](https://morgan1822.github.io)

---

## 📞 Support

For issues, feature requests, or questions:
- **Support Portal:** [https://morgan1822.github.io/PGMate/support.html](https://morgan1822.github.io/PGMate/support.html)
- **GitHub Issues:** [Create an Issue](https://github.com/Morgan1822/PGMate/issues)

---

## ⭐ Contributing

This is currently a personal/client project. For collaboration inquiries, please reach out via email.

---

**Made with ❤️ for property managers in India**
