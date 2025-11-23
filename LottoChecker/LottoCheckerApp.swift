import SwiftUI
import SwiftData

@main
struct LottoCheckerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: PurchaseHistory.self)
    }
}
