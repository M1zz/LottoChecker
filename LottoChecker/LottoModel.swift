import Foundation

// MARK: - API Response Model
struct LottoResponse: Codable {
    let returnValue: String
    let drwNoDate: String
    let drwNo: Int
    let drwtNo1: Int
    let drwtNo2: Int
    let drwtNo3: Int
    let drwtNo4: Int
    let drwtNo5: Int
    let drwtNo6: Int
    let bnusNo: Int
    let firstWinamnt: Int64
    let firstPrzwnerCo: Int
    let totSellamnt: Int64
    
    var numbers: [Int] {
        [drwtNo1, drwtNo2, drwtNo3, drwtNo4, drwtNo5, drwtNo6]
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: drwNoDate) {
            formatter.dateFormat = "yyyy년 MM월 dd일"
            return formatter.string(from: date)
        }
        return drwNoDate
    }
    
    var formattedFirstPrize: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: firstWinamnt)) ?? "\(firstWinamnt)"
    }
    
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: totSellamnt)) ?? "\(totSellamnt)"
    }
}
