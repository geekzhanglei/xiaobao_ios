import SwiftUI

struct AppStoreKey: EnvironmentKey {
    static var defaultValue: AppStore? = nil
}

extension EnvironmentValues {
    var appStore: AppStore? {
        get { self[AppStoreKey.self] }
        set { self[AppStoreKey.self] = newValue }
    }
}
