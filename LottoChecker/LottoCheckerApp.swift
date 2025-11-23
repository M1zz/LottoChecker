import SwiftUI
import SwiftData

@main
struct LottoCheckerApp: App {
    let modelContainer: ModelContainer

    init() {
        AppLogger.logLifecycle("앱 시작")
        AppLogger.info("LottoChecker v1.0 초기화", category: AppLogger.app)

        // 먼저 기존 데이터베이스 파일을 모두 삭제
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            do {
                let contents = try fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    if fileURL.lastPathComponent.contains("default.store") ||
                       fileURL.lastPathComponent.contains(".wal") ||
                       fileURL.lastPathComponent.contains(".shm") {
                        try? fileManager.removeItem(at: fileURL)
                        print("🗑️ 삭제됨: \(fileURL.lastPathComponent)")
                    }
                }
            } catch {
                print("⚠️ 디렉토리 확인 실패: \(error)")
            }
        }

        // ModelContainer 설정
        do {
            let schema = Schema([
                PurchaseHistory.self,
                CachedLottoData.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ ModelContainer 초기화 성공")
        } catch {
            print("❌ ModelContainer 초기화 실패: \(error)")
            fatalError("데이터베이스 초기화 실패. 앱을 삭제하고 재설치하세요.")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    AppLogger.logLifecycle("MainView 표시됨")
                }
        }
        .modelContainer(modelContainer)
    }
}
