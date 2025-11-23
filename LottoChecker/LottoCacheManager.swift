import Foundation
import UIKit

/// 로또 데이터 메모리 캐시 매니저
/// NSCache를 사용한 빠른 메모리 캐싱
class LottoCacheManager {
    static let shared = LottoCacheManager()

    private let cache = NSCache<NSNumber, CacheEntry>()
    private let cacheQueue = DispatchQueue(label: "com.lottochecker.cache", attributes: .concurrent)

    // 캐시 만료 시간 (초)
    private let expirationTime: TimeInterval = 24 * 60 * 60 // 24시간

    private init() {
        // 메모리 경고 시 캐시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        AppLogger.info("메모리 캐시 매니저 초기화", category: AppLogger.storage)
    }

    // MARK: - Cache Entry

    private class CacheEntry {
        let data: LottoResponse
        let timestamp: Date

        init(data: LottoResponse) {
            self.data = data
            self.timestamp = Date()
        }

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > LottoCacheManager.shared.expirationTime
        }

        var age: TimeInterval {
            Date().timeIntervalSince(timestamp)
        }
    }

    // MARK: - Public Methods

    /// 캐시에서 데이터 가져오기
    func get(round: Int) -> LottoResponse? {
        var result: LottoResponse?

        cacheQueue.sync {
            if let entry = cache.object(forKey: NSNumber(value: round)) {
                if !entry.isExpired {
                    result = entry.data
                    AppLogger.debug("메모리 캐시 히트 - 회차: \(round), 나이: \(String(format: "%.1f", entry.age))초", category: AppLogger.storage)
                } else {
                    // 만료된 캐시 제거
                    cache.removeObject(forKey: NSNumber(value: round))
                    AppLogger.debug("메모리 캐시 만료 - 회차: \(round)", category: AppLogger.storage)
                }
            } else {
                AppLogger.debug("메모리 캐시 미스 - 회차: \(round)", category: AppLogger.storage)
            }
        }

        return result
    }

    /// 캐시에 데이터 저장
    func set(round: Int, data: LottoResponse) {
        cacheQueue.async(flags: .barrier) {
            let entry = CacheEntry(data: data)
            self.cache.setObject(entry, forKey: NSNumber(value: round))
            AppLogger.debug("메모리 캐시 저장 - 회차: \(round)", category: AppLogger.storage)
        }
    }

    /// 특정 회차 캐시 제거
    func remove(round: Int) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeObject(forKey: NSNumber(value: round))
            AppLogger.debug("메모리 캐시 제거 - 회차: \(round)", category: AppLogger.storage)
        }
    }

    /// 모든 캐시 제거
    @objc func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAllObjects()
            AppLogger.info("메모리 캐시 전체 삭제", category: AppLogger.storage)
        }
    }

    /// 캐시 통계
    func getCacheStats() -> (count: Int, totalSize: Int) {
        var stats = (count: 0, totalSize: 0)
        // NSCache는 정확한 카운트를 제공하지 않으므로 근사값
        AppLogger.debug("캐시 통계 조회", category: AppLogger.storage)
        return stats
    }
}
