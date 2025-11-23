import Foundation
import SwiftData

/// 로또 데이터 로컬 캐시 모델
@Model
final class CachedLottoData {
    var round: Int // 회차 (Primary Key로 사용)
    var drawDate: String // 추첨일
    var number1: Int
    var number2: Int
    var number3: Int
    var number4: Int
    var number5: Int
    var number6: Int
    var bonusNumber: Int
    var firstPrize: Int64 // 1등 당첨금
    var firstWinnerCount: Int // 1등 당첨자 수
    var totalSales: Int64 // 총 판매액
    var cachedAt: Date // 캐시된 시간
    var returnValue: String // API 응답 상태

    init(from response: LottoResponse) {
        self.round = response.drwNo
        self.drawDate = response.drwNoDate
        self.number1 = response.drwtNo1
        self.number2 = response.drwtNo2
        self.number3 = response.drwtNo3
        self.number4 = response.drwtNo4
        self.number5 = response.drwtNo5
        self.number6 = response.drwtNo6
        self.bonusNumber = response.bnusNo
        self.firstPrize = response.firstWinamnt
        self.firstWinnerCount = response.firstPrzwnerCo
        self.totalSales = response.totSellamnt
        self.cachedAt = Date()
        self.returnValue = response.returnValue

        AppLogger.logDataSave(type: "CachedLottoData", count: 1)
        AppLogger.debug("로또 \(round)회 데이터 캐시됨", category: AppLogger.storage)
    }

    /// SwiftData 모델을 LottoResponse로 변환
    func toLottoResponse() -> LottoResponse {
        return LottoResponse(
            returnValue: returnValue,
            drwNoDate: drawDate,
            drwNo: round,
            drwtNo1: number1,
            drwtNo2: number2,
            drwtNo3: number3,
            drwtNo4: number4,
            drwtNo5: number5,
            drwtNo6: number6,
            bnusNo: bonusNumber,
            firstWinamnt: firstPrize,
            firstPrzwnerCo: firstWinnerCount,
            totSellamnt: totalSales
        )
    }

    /// 캐시가 유효한지 확인 (24시간)
    var isValid: Bool {
        let expirationTime: TimeInterval = 24 * 60 * 60 // 24시간
        return Date().timeIntervalSince(cachedAt) < expirationTime
    }

    /// 캐시 나이 (초 단위)
    var age: TimeInterval {
        Date().timeIntervalSince(cachedAt)
    }
}
