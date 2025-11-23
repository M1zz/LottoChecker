import Foundation

class LottoService {
    static let shared = LottoService()

    private let baseURL = "https://www.dhlottery.co.kr/common.do"
    private let memoryCache = LottoCacheManager.shared
    private let localStorage = LottoDataStore.shared

    // 최신 회차 캐싱
    private var cachedLatestRound: Int?
    private var latestRoundCacheTime: Date?
    private let latestRoundCacheDuration: TimeInterval = 3600 // 1시간

    private init() {
        AppLogger.info("LottoService 초기화 - 캐싱 활성화", category: AppLogger.network)

        // 앱 시작 시 만료된 캐시 정리
        Task {
            await localStorage.cleanExpiredCache()
        }
    }
    
    func fetchLottoData(round: Int) async throws -> LottoResponse {
        let perf = PerformanceLogger(name: "로또 데이터 가져오기 (캐싱 포함) - 회차 \(round)", logger: AppLogger.network)

        // 1단계: 메모리 캐시 확인
        if let cachedData = memoryCache.get(round: round) {
            AppLogger.info("✅ 메모리 캐시에서 반환 - 회차: \(round)", category: AppLogger.network)
            perf.end()
            return cachedData
        }

        // 2단계: 로컬 DB 확인
        if let localData = await localStorage.fetch(round: round) {
            AppLogger.info("✅ 로컬 DB에서 반환 - 회차: \(round)", category: AppLogger.network)
            // 메모리 캐시에도 저장
            memoryCache.set(round: round, data: localData)
            perf.end()
            return localData
        }

        // 3단계: API 호출
        AppLogger.info("🌐 API 호출 시작 - 회차: \(round)", category: AppLogger.network)
        let response = try await fetchFromAPI(round: round)

        // 캐시에 저장
        memoryCache.set(round: round, data: response)
        await localStorage.save(response)

        perf.end()
        return response
    }

    /// API에서 직접 데이터 가져오기 (캐시 없이)
    private func fetchFromAPI(round: Int) async throws -> LottoResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "method", value: "getLottoNumber"),
            URLQueryItem(name: "drwNo", value: "\(round)")
        ]

        guard let url = components?.url else {
            AppLogger.error("URL 생성 실패", error: LottoError.invalidURL, category: AppLogger.network)
            throw LottoError.invalidURL
        }

        AppLogger.logNetworkRequest(url: url.absoluteString, method: "GET")

        let startTime = CFAbsoluteTimeGetCurrent()

        // 네트워크 에러 처리
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch let error as URLError {
            AppLogger.error("네트워크 에러", error: error, category: AppLogger.network)

            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw LottoError.networkError
            case .timedOut:
                throw LottoError.timeoutError
            default:
                throw LottoError.invalidResponse
            }
        } catch {
            AppLogger.error("알 수 없는 에러", error: error, category: AppLogger.network)
            throw LottoError.invalidResponse
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.error("HTTP 응답 변환 실패", category: AppLogger.network)
            throw LottoError.invalidResponse
        }

        AppLogger.logNetworkResponse(url: url.absoluteString, statusCode: httpResponse.statusCode, duration: duration)

        guard httpResponse.statusCode == 200 else {
            AppLogger.error("HTTP 상태 코드 오류: \(httpResponse.statusCode)", category: AppLogger.network)
            throw LottoError.invalidResponse
        }

        let decoder = JSONDecoder()
        let lottoResponse = try decoder.decode(LottoResponse.self, from: data)

        guard lottoResponse.returnValue == "success" else {
            AppLogger.warning("API 응답 returnValue가 success가 아님: \(lottoResponse.returnValue)", category: AppLogger.network)
            throw LottoError.noData
        }

        AppLogger.info("로또 \(round)회 데이터 API 로드 성공", category: AppLogger.network)

        return lottoResponse
    }
    
    func getLatestRound() async throws -> Int {
        // 캐시된 값이 유효하면 반환
        if let cached = cachedLatestRound,
           let cacheTime = latestRoundCacheTime,
           Date().timeIntervalSince(cacheTime) < latestRoundCacheDuration {
            AppLogger.info("✅ 캐시된 최신 회차 반환: \(cached)회", category: AppLogger.network)
            return cached
        }

        AppLogger.info("최신 회차 조회 시작 (캐시 만료 또는 없음)", category: AppLogger.network)

        // 현재 날짜 기준으로 대략적인 최신 회차 계산
        // 로또 1회: 2002년 12월 7일
        let startDate = DateComponents(year: 2002, month: 12, day: 7)
        let calendar = Calendar.current

        guard let firstDrawDate = calendar.date(from: startDate) else {
            AppLogger.error("로또 시작 날짜 계산 실패", error: LottoError.invalidDate, category: AppLogger.network)
            throw LottoError.invalidDate
        }

        let now = Date()
        let components = calendar.dateComponents([.weekOfYear], from: firstDrawDate, to: now)

        // 대략적인 회차 계산 (매주 토요일 추첨)
        let estimatedRound = (components.weekOfYear ?? 0) + 1
        AppLogger.debug("예상 회차: \(estimatedRound)", category: AppLogger.network)

        // 최신 회차 확인 (몇 회차 전부터 체크)
        for round in stride(from: estimatedRound, to: max(1, estimatedRound - 5), by: -1) {
            do {
                _ = try await fetchLottoData(round: round)
                AppLogger.info("최신 회차 확인: \(round)회", category: AppLogger.network)

                // 캐시에 저장
                cachedLatestRound = round
                latestRoundCacheTime = Date()

                return round
            } catch {
                AppLogger.debug("\(round)회 확인 실패, 이전 회차 확인 중...", category: AppLogger.network)
                continue
            }
        }

        AppLogger.error("최신 회차를 찾을 수 없음", error: LottoError.noData, category: AppLogger.network)
        throw LottoError.noData
    }
}

enum LottoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case invalidDate
    case networkError
    case timeoutError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "서버 응답 오류입니다."
        case .noData:
            return "데이터를 찾을 수 없습니다."
        case .invalidDate:
            return "날짜 계산 오류입니다."
        case .networkError:
            return "인터넷 연결을 확인해주세요."
        case .timeoutError:
            return "연결 시간이 초과되었습니다."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Wi-Fi 또는 모바일 데이터 연결을 확인하고 다시 시도해주세요."
        case .timeoutError:
            return "네트워크 상태가 불안정합니다. 잠시 후 다시 시도해주세요."
        case .noData:
            return "해당 회차의 데이터가 아직 발표되지 않았을 수 있습니다."
        case .invalidResponse:
            return "서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요."
        default:
            return "문제가 지속되면 앱을 재시작해주세요."
        }
    }
}
