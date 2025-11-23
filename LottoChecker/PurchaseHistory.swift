import Foundation
import SwiftData

@Model
final class PurchaseHistory {
    var id: UUID
    var round: Int // 회차
    var numbers: [Int] // 구매한 번호 (6개)
    var purchaseDate: Date
    var purchaseMethod: String // "수동", "자동", "QR스캔"
    var cost: Int // 구매 금액 (1000원 단위)

    // 당첨 결과 (옵셔널 - 추후 확인)
    var isChecked: Bool
    var matchCount: Int?
    var hasBonus: Bool?
    var rank: Int?
    var prize: Int?

    init(round: Int, numbers: [Int], purchaseDate: Date = Date(), purchaseMethod: String = "수동", cost: Int = 1000) {
        self.id = UUID()
        self.round = round
        self.numbers = numbers.sorted()
        self.purchaseDate = purchaseDate
        self.purchaseMethod = purchaseMethod
        self.cost = cost
        self.isChecked = false
        self.matchCount = nil
        self.hasBonus = nil
        self.rank = nil
        self.prize = nil
    }

    // 당첨 결과 업데이트
    func updateResult(matchCount: Int, hasBonus: Bool, rank: Int?, prize: Int?) {
        self.isChecked = true
        self.matchCount = matchCount
        self.hasBonus = hasBonus
        self.rank = rank
        self.prize = prize
    }

    // 당첨 여부
    var isWinner: Bool {
        rank != nil && rank! <= 5
    }

    // 포맷된 번호 문자열
    var formattedNumbers: String {
        numbers.map { String($0) }.joined(separator: ", ")
    }

    // 포맷된 날짜
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: purchaseDate)
    }
}
