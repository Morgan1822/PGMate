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
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        configureTabBarAppearance()
        return true
    }

    private func configureTabBarAppearance() {
        let navyBlue = UIColor(Color.primaryIndigo)
        let gold     = UIColor(Color.accentGold)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navyBlue

        // Selected — gold icon + label
        appearance.stackedLayoutAppearance.selected.iconColor = gold
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: gold
        ]

        // Unselected — white at 70%
        let dimWhite = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.iconColor = dimWhite
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: dimWhite
        ]

        UITabBar.appearance().standardAppearance  = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
                .tint(Color.primaryIndigo)
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
