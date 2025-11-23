import Foundation
import SwiftData

/// 로또 데이터 로컬 저장소
/// SwiftData를 사용한 영구 저장
@MainActor
class LottoDataStore {
    static let shared = LottoDataStore()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private init() {
        setupContainer()
    }

    private func setupContainer() {
        do {
            let schema = Schema([CachedLottoData.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer!)
            AppLogger.info("로컬 데이터 스토어 초기화 완료", category: AppLogger.storage)
        } catch {
            AppLogger.error("로컬 데이터 스토어 초기화 실패", error: error, category: AppLogger.storage)
        }
    }

    // MARK: - Public Methods

    /// 특정 회차 데이터 가져오기
    func fetch(round: Int) async -> LottoResponse? {
        guard let context = modelContext else {
            AppLogger.error("ModelContext가 없음", category: AppLogger.storage)
            return nil
        }

        let perf = PerformanceLogger(name: "로컬 DB 조회 - 회차 \(round)", logger: AppLogger.storage)

        let descriptor = FetchDescriptor<CachedLottoData>(
            predicate: #Predicate { $0.round == round }
        )

        do {
            let results = try context.fetch(descriptor)
            perf.end()

            if let cachedData = results.first {
                if cachedData.isValid {
                    AppLogger.info("로컬 DB 히트 - 회차: \(round), 나이: \(String(format: "%.1f", cachedData.age / 3600))시간", category: AppLogger.storage)
                    return cachedData.toLottoResponse()
                } else {
                    // 만료된 데이터 삭제
                    context.delete(cachedData)
                    try? context.save()
                    AppLogger.debug("로컬 DB 만료 데이터 삭제 - 회차: \(round)", category: AppLogger.storage)
                }
            } else {
                AppLogger.debug("로컬 DB 미스 - 회차: \(round)", category: AppLogger.storage)
            }
        } catch {
            AppLogger.error("로컬 DB 조회 실패 - 회차: \(round)", error: error, category: AppLogger.storage)
        }

        return nil
    }

    /// 데이터 저장
    func save(_ response: LottoResponse) async {
        guard let context = modelContext else {
            AppLogger.error("ModelContext가 없음", category: AppLogger.storage)
            return
        }

        // 기존 데이터 확인 및 삭제
        let descriptor = FetchDescriptor<CachedLottoData>(
            predicate: #Predicate { $0.round == response.drwNo }
        )

        do {
            let existing = try context.fetch(descriptor)
            for item in existing {
                context.delete(item)
            }

            // 새 데이터 저장
            let cachedData = CachedLottoData(from: response)
            context.insert(cachedData)
            try context.save()

            AppLogger.info("로컬 DB 저장 완료 - 회차: \(response.drwNo)", category: AppLogger.storage)
        } catch {
            AppLogger.error("로컬 DB 저장 실패 - 회차: \(response.drwNo)", error: error, category: AppLogger.storage)
        }
    }

    /// 특정 회차 데이터 삭제
    func delete(round: Int) async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<CachedLottoData>(
            predicate: #Predicate { $0.round == round }
        )

        do {
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
            try context.save()
            AppLogger.debug("로컬 DB 삭제 - 회차: \(round)", category: AppLogger.storage)
        } catch {
            AppLogger.error("로컬 DB 삭제 실패 - 회차: \(round)", error: error, category: AppLogger.storage)
        }
    }

    /// 만료된 캐시 정리
    func cleanExpiredCache() async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<CachedLottoData>()

        do {
            let allData = try context.fetch(descriptor)
            var deletedCount = 0

            for item in allData {
                if !item.isValid {
                    context.delete(item)
                    deletedCount += 1
                }
            }

            if deletedCount > 0 {
                try context.save()
                AppLogger.info("만료된 로컬 캐시 정리 완료 - \(deletedCount)건 삭제", category: AppLogger.storage)
            }
        } catch {
            AppLogger.error("만료 캐시 정리 실패", error: error, category: AppLogger.storage)
        }
    }

    /// 모든 캐시 삭제
    func clearAll() async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<CachedLottoData>()

        do {
            let allData = try context.fetch(descriptor)
            for item in allData {
                context.delete(item)
            }
            try context.save()
            AppLogger.info("모든 로컬 캐시 삭제 완료", category: AppLogger.storage)
        } catch {
            AppLogger.error("로컬 캐시 전체 삭제 실패", error: error, category: AppLogger.storage)
        }
    }

    /// 저장된 데이터 통계
    func getStats() async -> (count: Int, oldestDate: Date?, newestDate: Date?) {
        guard let context = modelContext else {
            return (0, nil, nil)
        }

        let descriptor = FetchDescriptor<CachedLottoData>(
            sortBy: [SortDescriptor(\.round)]
        )

        do {
            let allData = try context.fetch(descriptor)
            let count = allData.count
            let oldest = allData.first?.cachedAt
            let newest = allData.last?.cachedAt

            AppLogger.debug("로컬 DB 통계 - 총 \(count)건", category: AppLogger.storage)
            return (count, oldest, newest)
        } catch {
            AppLogger.error("로컬 DB 통계 조회 실패", error: error, category: AppLogger.storage)
            return (0, nil, nil)
        }
    }
}
