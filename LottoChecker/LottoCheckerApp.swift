import SwiftUI
import SwiftData

@main
struct LottoCheckerApp: App {
    init() {
        AppLogger.logLifecycle("앱 시작")
        AppLogger.info("LottoChecker v1.0 초기화", category: AppLogger.app)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    AppLogger.logLifecycle("MainView 표시됨")
                }
        }
        .modelContainer(for: [PurchaseHistory.self, CachedLottoData.self])
    }
}
