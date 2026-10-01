import SwiftUI

@main
struct JumpCollectExplorerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            LaunchThresholdView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
