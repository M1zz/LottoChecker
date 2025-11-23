import Foundation
import OSLog

/// 앱 전역 로깅 시스템
/// OSLog를 사용한 통합 로깅 관리
class AppLogger {

    // MARK: - Subsystem

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.lottochecker.app"

    // MARK: - Categories

    /// 네트워크 관련 로그
    static let network = Logger(subsystem: subsystem, category: "🌐 Network")

    /// UI 관련 로그
    static let ui = Logger(subsystem: subsystem, category: "📱 UI")

    /// 데이터 저장소 관련 로그
    static let storage = Logger(subsystem: subsystem, category: "💾 Storage")

    /// ViewModel 관련 로그
    static let viewModel = Logger(subsystem: subsystem, category: "🔄 ViewModel")

    /// 일반 앱 로그
    static let app = Logger(subsystem: subsystem, category: "📲 App")

    /// QR 코드 스캐너 관련 로그
    static let qr = Logger(subsystem: subsystem, category: "📷 QR")

    /// 분석/통계 관련 로그
    static let analytics = Logger(subsystem: subsystem, category: "📊 Analytics")

    // MARK: - Helper Methods

    /// 디버그 로그 (개발 중에만 표시)
    static func debug(_ message: String, category: Logger = app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        category.debug("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// 정보 로그
    static func info(_ message: String, category: Logger = app) {
        category.info("\(message)")
    }

    /// 경고 로그
    static func warning(_ message: String, category: Logger = app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        category.warning("⚠️ [\(fileName):\(line)] \(function) - \(message)")
    }

    /// 에러 로그
    static func error(_ message: String, error: Error? = nil, category: Logger = app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "❌ [\(fileName):\(line)] \(function) - \(message)"
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        category.error("\(logMessage)")
    }

    /// 중요한 에러 로그 (크래시나 데이터 손실 가능성)
    static func fault(_ message: String, error: Error? = nil, category: Logger = app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "🔥 FAULT [\(fileName):\(line)] \(function) - \(message)"
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        category.fault("\(logMessage)")
    }

    /// 네트워크 요청 로그
    static func logNetworkRequest(url: String, method: String = "GET") {
        network.info("📤 Request: \(method) \(url)")
    }

    /// 네트워크 응답 로그
    static func logNetworkResponse(url: String, statusCode: Int?, duration: TimeInterval? = nil) {
        var message = "📥 Response: \(url)"
        if let code = statusCode {
            message += " | Status: \(code)"
        }
        if let duration = duration {
            message += " | Duration: \(String(format: "%.2f", duration))s"
        }
        network.info("\(message)")
    }

    /// 데이터 저장 로그
    static func logDataSave(type: String, count: Int? = nil) {
        var message = "💾 Saved: \(type)"
        if let count = count {
            message += " | Count: \(count)"
        }
        storage.info("\(message)")
    }

    /// 데이터 로드 로그
    static func logDataLoad(type: String, count: Int? = nil) {
        var message = "📂 Loaded: \(type)"
        if let count = count {
            message += " | Count: \(count)"
        }
        storage.info("\(message)")
    }

    /// UI 이벤트 로그
    static func logUIEvent(_ event: String, details: String? = nil) {
        var message = "👆 \(event)"
        if let details = details {
            message += " | \(details)"
        }
        ui.debug("\(message)")
    }

    /// 앱 라이프사이클 로그
    static func logLifecycle(_ event: String) {
        app.info("🔄 Lifecycle: \(event)")
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// 포매팅된 로그 출력
    func log(_ level: OSLogType, _ message: String) {
        self.log(level: level, "\(message)")
    }
}

// MARK: - Performance Logging

struct PerformanceLogger {
    private let name: String
    private let startTime: CFAbsoluteTime
    private let logger: Logger

    init(name: String, logger: Logger = AppLogger.app) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.logger = logger
        logger.debug("⏱️ Started: \(name)")
    }

    func end() {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("⏱️ Completed: \(name) in \(String(format: "%.3f", duration))s")
    }
}

// MARK: - Usage Example
/*

 // 기본 로깅
 AppLogger.info("앱 시작됨")
 AppLogger.debug("디버그 메시지")
 AppLogger.warning("경고 메시지")
 AppLogger.error("에러 발생", error: someError)

 // 카테고리별 로깅
 AppLogger.network.info("API 호출 시작")
 AppLogger.ui.debug("버튼 클릭됨")
 AppLogger.storage.info("데이터 저장 완료")

 // 헬퍼 메서드
 AppLogger.logNetworkRequest(url: "https://api.example.com", method: "GET")
 AppLogger.logNetworkResponse(url: "https://api.example.com", statusCode: 200, duration: 0.5)
 AppLogger.logDataSave(type: "PurchaseHistory", count: 5)
 AppLogger.logUIEvent("Button Tapped", details: "Generate Numbers")

 // 성능 측정
 let perf = PerformanceLogger(name: "데이터 로딩")
 // ... 작업 수행 ...
 perf.end()

 */
