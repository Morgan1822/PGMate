import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif
        return true
    }
}

@main
struct PGMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    private func configureFirebase() {
        #if DEBUG
        let plistName = "GoogleService-Info-Dev"
        #else
        let plistName = "GoogleService-Info-Prod"
        #endif

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Could not load \(plistName).plist from bundle.")
        }

        FirebaseApp.configure(options: options)
        print("Firebase configured with \(plistName)")
    }
}
