import Foundation

struct SavedLottoNumber: Codable, Identifiable {
    var id: UUID
    var numbers: [Int]
    var createdAt: Date
    var generationType: String // "AI추천", "통계기반", "수동입력"
    var memo: String?

    init(numbers: [Int], generationType: String, memo: String? = nil) {
        self.id = UUID()
        self.numbers = numbers.sorted()
        self.createdAt = Date()
        self.generationType = generationType
        self.memo = memo
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: createdAt)
    }
}

// UserDefaults helper
class SavedNumbersManager {
    static let shared = SavedNumbersManager()
    private let key = "SavedLottoNumbers"

    func save(_ number: SavedLottoNumber) {
        var numbers = loadAll()
        numbers.append(number)
        if let encoded = try? JSONEncoder().encode(numbers) {
            UserDefaults.standard.set(encoded, forKey: key)
            print("✅ 번호 저장 성공 (UserDefaults): \(number.numbers)")
        }
    }

    func loadAll() -> [SavedLottoNumber] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let numbers = try? JSONDecoder().decode([SavedLottoNumber].self, from: data) else {
            return []
        }
        return numbers.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func delete(_ number: SavedLottoNumber) {
        var numbers = loadAll()
        numbers.removeAll { $0.id == number.id }
        if let encoded = try? JSONEncoder().encode(numbers) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
