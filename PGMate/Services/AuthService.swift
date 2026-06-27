import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCrashlytics

@Observable
class AuthService {
    static let shared = AuthService()

    var isAuthenticated = false
    var currentUserId: String?
    var currentPropertyId: String?
    var ownerName: String = ""
    var propertyName: String = ""
    var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.currentUserId = user.uid
                    self?.isAuthenticated = true
                    Crashlytics.crashlytics().setUserID(user.uid)
                    await self?.fetchOwnerProfile(userId: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUserId = nil
                    self?.currentPropertyId = nil
                    self?.ownerName = ""
                    self?.propertyName = ""
                    Crashlytics.crashlytics().setUserID("")
                }
            }
        }
    }

    func signUp(name: String, email: String, password: String, propertyName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        let propertyId = UUID().uuidString
        let db = Firestore.firestore()

        try await db.collection("properties").document(propertyId).setData([
            "id": propertyId,
            "name": propertyName,
            "ownerId": uid,
            "createdAt": Timestamp(date: Date())
        ])

        try await db.collection("owners").document(uid).setData([
            "uid": uid,
            "name": name,
            "email": email,
            "propertyId": propertyId,
            "createdAt": Timestamp(date: Date())
        ])

        await MainActor.run {
            self.currentUserId = uid
            self.currentPropertyId = propertyId
            self.ownerName = name
            self.propertyName = propertyName
            self.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await fetchOwnerProfile(userId: result.user.uid)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    @MainActor
    func fetchOwnerProfile(userId: String) async {
        let db = Firestore.firestore()
        guard let doc = try? await db.collection("owners").document(userId).getDocument(),
              let data = doc.data() else { return }

        ownerName = data["name"] as? String ?? ""
        currentPropertyId = data["propertyId"] as? String

        if let pid = currentPropertyId,
           let propDoc = try? await db.collection("properties").document(pid).getDocument(),
           let propData = propDoc.data() {
            propertyName = propData["name"] as? String ?? "My Property"
        }
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser,
              let propertyId = currentPropertyId else { return }
        let db = Firestore.firestore()
        let ref = db.collection("properties").document(propertyId)
        for sub in ["rooms", "tenants", "rentRecords", "maintenance"] {
            let docs = try await ref.collection(sub).getDocuments()
            for doc in docs.documents {
                try await doc.reference.delete()
            }
        }
        try await ref.delete()
        try await db.collection("owners").document(user.uid).delete()
        try await user.delete()
    }
}
