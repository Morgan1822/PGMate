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

        configureNavBarAppearance()
        configureTabBarAppearance()
        return true
    }

    // MARK: - Global Navigation Bar Appearance
    private func configureNavBarAppearance() {
        let navy = UIColor(hex: "#1B3A6B")
        let white = UIColor.white

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navy

        // Title attributes
        appearance.titleTextAttributes = [
            .foregroundColor: white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        // Back button chevron color
        appearance.setBackIndicatorImage(
            UIImage(systemName: "chevron.left"),
            transitionMaskImage: UIImage(systemName: "chevron.left")
        )

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
        UINavigationBar.appearance().tintColor            = white  // back button & bar buttons
    }

    // MARK: - Global Tab Bar Appearance
    private func configureTabBarAppearance() {
        let navy = UIColor(hex: "#1B3A6B")
        let gold = UIColor(hex: "#E8A33D")
        let dimWhite = UIColor.white.withAlphaComponent(0.65)

        let itemAppearance = UITabBarItemAppearance(style: .stacked)
        // Selected — gold
        itemAppearance.selected.iconColor = gold
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: gold]
        // Unselected — white at 65%
        itemAppearance.normal.iconColor = dimWhite
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: dimWhite]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navy
        // Suppress the floating pill/compact style introduced in iOS 18
        appearance.stackedLayoutAppearance   = itemAppearance
        appearance.inlineLayoutAppearance    = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance  = appearance
        // Force opaque — prevents translucency causing pill backgrounds
        UITabBar.appearance().isTranslucent = false
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
            ZStack {
                Color.bgPrimary.ignoresSafeArea(.all)
                RootView()
                    .tint(Color.gold)
            }
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
