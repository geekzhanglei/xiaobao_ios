import SwiftUI

@main
struct XiaobaoNativeApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }
}
