import Foundation

class LottoService {
    static let shared = LottoService()
    
    private let baseURL = "https://www.dhlottery.co.kr/common.do"
    
    private init() {}
    
    func fetchLottoData(round: Int) async throws -> LottoResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "method", value: "getLottoNumber"),
            URLQueryItem(name: "drwNo", value: "\(round)")
        ]
        
        guard let url = components?.url else {
            throw LottoError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LottoError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let lottoResponse = try decoder.decode(LottoResponse.self, from: data)
        
        guard lottoResponse.returnValue == "success" else {
            throw LottoError.noData
        }
        
        return lottoResponse
    }
    
    func getLatestRound() async throws -> Int {
        // 현재 날짜 기준으로 대략적인 최신 회차 계산
        // 로또 1회: 2002년 12월 7일
        let startDate = DateComponents(year: 2002, month: 12, day: 7)
        let calendar = Calendar.current
        
        guard let firstDrawDate = calendar.date(from: startDate) else {
            throw LottoError.invalidDate
        }
        
        let now = Date()
        let components = calendar.dateComponents([.weekOfYear], from: firstDrawDate, to: now)
        
        // 대략적인 회차 계산 (매주 토요일 추첨)
        let estimatedRound = (components.weekOfYear ?? 0) + 1
        
        // 최신 회차 확인 (몇 회차 전부터 체크)
        for round in stride(from: estimatedRound, to: max(1, estimatedRound - 5), by: -1) {
            do {
                _ = try await fetchLottoData(round: round)
                return round
            } catch {
                continue
            }
        }
        
        throw LottoError.noData
    }
}

enum LottoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case invalidDate
    
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
        }
    }
}
