import Foundation
import SwiftUI

// MARK: - Data Models
struct NumberPair: Identifiable, Hashable {
    let id = UUID()
    let first: Int
    let second: Int
    let appearances: Int
    let frequency: Double
    let rounds: [Int] // 출현한 회차들

    func hash(into hasher: inout Hasher) {
        hasher.combine(first)
        hasher.combine(second)
    }

    static func == (lhs: NumberPair, rhs: NumberPair) -> Bool {
        lhs.first == rhs.first && lhs.second == rhs.second
    }
}

struct NumberTrend: Identifiable {
    let id = UUID()
    let number: Int
    let appearances: Int
    let frequency: Double
    let expectedFrequency: Double
    let deviation: Double
    let trend: TrendDirection
    let recentAppearances: [Bool] // 최근 10회차 출현 여부

    enum TrendDirection {
        case rising, falling, stable

        var color: Color {
            switch self {
            case .rising: return .red
            case .falling: return .blue
            case .stable: return .gray
            }
        }

        var icon: String {
            switch self {
            case .rising: return "arrow.up.circle.fill"
            case .falling: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }
    }
}

struct RecommendedCombination: Identifiable, Codable {
    let id = UUID()
    let numbers: [Int]
    let type: CombinationType
    let score: Double
    let reason: String
    let createdDate: Date
    var isSaved: Bool = false

    enum CombinationType: String, Codable {
        case hotNumbers = "핫 번호 조합"
        case coldNumbers = "콜드 번호 조합"
        case balanced = "균형 조합"
        case pattern = "패턴 기반"
        case statistical = "통계 기반"

        var color: Color {
            switch self {
            case .hotNumbers: return .red
            case .coldNumbers: return .blue
            case .balanced: return .green
            case .pattern: return .purple
            case .statistical: return .orange
            }
        }
    }
}

// MARK: - View Model
@MainActor
class ProbabilityAnalysisViewModel: ObservableObject {
    @Published var numberTrends: [NumberTrend] = []
    @Published var numberPairs: [NumberPair] = []
    @Published var recommendedCombinations: [RecommendedCombination] = []
    @Published var savedCombinations: [RecommendedCombination] = []
    @Published var isAnalyzing = false
    @Published var selectedTimeRange = 50

    private let userDefaults = UserDefaults.standard
    private let savedCombinationsKey = "savedLottoCombinations"

    init() {
        loadSavedCombinations()
    }

    // MARK: - Analysis Functions

    func analyzeNumberTrends() async {
        isAnalyzing = true

        do {
            // 최근 데이터 가져오기
            let service = LottoService.shared
            let latestRound = try await service.getLatestRound()
            let startRound = max(1, latestRound - selectedTimeRange + 1)

            var allNumbers = Array(repeating: 0, count: 46) // 인덱스 0은 사용 안함
            var recentData: [[Bool]] = Array(repeating: Array(repeating: false, count: 10), count: 46)
            var pairCounts: [String: (count: Int, rounds: [Int])] = [:]

            for round in startRound...latestRound {
                do {
                    let lottoData = try await service.fetchLottoData(round: round)

                    // 번호별 출현 횟수 카운트
                    for number in lottoData.numbers {
                        allNumbers[number] += 1
                    }

                    // 페어 분석 - 모든 2개 조합 카운트
                    let sortedNumbers = lottoData.numbers.sorted()
                    for i in 0..<sortedNumbers.count {
                        for j in (i+1)..<sortedNumbers.count {
                            let pairKey = "\(sortedNumbers[i])-\(sortedNumbers[j])"
                            if var pairData = pairCounts[pairKey] {
                                pairData.count += 1
                                pairData.rounds.append(round)
                                pairCounts[pairKey] = pairData
                            } else {
                                pairCounts[pairKey] = (count: 1, rounds: [round])
                            }
                        }
                    }

                    // 최근 10회차 데이터 저장
                    if round > latestRound - 10 {
                        let recentIndex = round - (latestRound - 9)
                        for number in lottoData.numbers {
                            recentData[number][recentIndex] = true
                        }
                    }
                } catch {
                    print("Error fetching round \(round): \(error)")
                }

                // API 호출 제한 방지
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }

            // 트렌드 분석
            let expectedFrequency = Double(selectedTimeRange * 6) / 45.0
            var trends: [NumberTrend] = []

            for number in 1...45 {
                let appearances = allNumbers[number]
                let frequency = Double(appearances) / Double(selectedTimeRange)
                let deviation = ((Double(appearances) - expectedFrequency) / expectedFrequency) * 100

                // 트렌드 판단 (최근 10회차 중 전반 5회 vs 후반 5회)
                let firstHalf = recentData[number].prefix(5).filter { $0 }.count
                let secondHalf = recentData[number].suffix(5).filter { $0 }.count

                let trend: NumberTrend.TrendDirection
                if secondHalf > firstHalf {
                    trend = .rising
                } else if secondHalf < firstHalf {
                    trend = .falling
                } else {
                    trend = .stable
                }

                trends.append(NumberTrend(
                    number: number,
                    appearances: appearances,
                    frequency: frequency,
                    expectedFrequency: expectedFrequency,
                    deviation: deviation,
                    trend: trend,
                    recentAppearances: recentData[number]
                ))
            }

            // 페어 데이터 처리
            var pairs: [NumberPair] = []
            for (pairKey, pairData) in pairCounts {
                let components = pairKey.split(separator: "-").compactMap { Int($0) }
                if components.count == 2 {
                    let frequency = Double(pairData.count) / Double(selectedTimeRange)
                    pairs.append(NumberPair(
                        first: components[0],
                        second: components[1],
                        appearances: pairData.count,
                        frequency: frequency * 100, // 백분율로 변환
                        rounds: pairData.rounds.sorted()
                    ))
                }
            }

            await MainActor.run {
                self.numberTrends = trends.sorted { $0.deviation > $1.deviation }
                self.numberPairs = pairs.sorted { $0.appearances > $1.appearances }
                self.generateRecommendations()
                self.isAnalyzing = false
            }

        } catch {
            await MainActor.run {
                self.isAnalyzing = false
            }
            print("Error analyzing trends: \(error)")
        }
    }

    // MARK: - Recommendation Generation

    private func generateRecommendations() {
        recommendedCombinations.removeAll()

        // 1. 핫 번호 조합 (출현율 높은 번호들)
        let hotNumbers = numberTrends
            .sorted { $0.deviation > $1.deviation }
            .prefix(15)
            .map { $0.number }
            .shuffled()
            .prefix(6)
            .sorted()

        if hotNumbers.count == 6 {
            recommendedCombinations.append(RecommendedCombination(
                numbers: Array(hotNumbers),
                type: .hotNumbers,
                score: calculateScore(numbers: Array(hotNumbers)),
                reason: "최근 \(selectedTimeRange)회차에서 가장 자주 출현한 번호들의 조합",
                createdDate: Date()
            ))
        }

        // 2. 콜드 번호 조합 (출현율 낮은 번호들)
        let coldNumbers = numberTrends
            .sorted { $0.deviation < $1.deviation }
            .prefix(15)
            .map { $0.number }
            .shuffled()
            .prefix(6)
            .sorted()

        if coldNumbers.count == 6 {
            recommendedCombinations.append(RecommendedCombination(
                numbers: Array(coldNumbers),
                type: .coldNumbers,
                score: calculateScore(numbers: Array(coldNumbers)),
                reason: "최근 \(selectedTimeRange)회차에서 적게 출현한 번호들 (역발상)",
                createdDate: Date()
            ))
        }

        // 3. 균형 조합 (핫 3개 + 콜드 3개)
        let balancedHot = numberTrends
            .sorted { $0.deviation > $1.deviation }
            .prefix(10)
            .map { $0.number }
            .shuffled()
            .prefix(3)

        let balancedCold = numberTrends
            .sorted { $0.deviation < $1.deviation }
            .prefix(10)
            .map { $0.number }
            .shuffled()
            .prefix(3)

        let balanced = (Array(balancedHot) + Array(balancedCold)).sorted()
        if balanced.count == 6 {
            recommendedCombinations.append(RecommendedCombination(
                numbers: balanced,
                type: .balanced,
                score: calculateScore(numbers: balanced),
                reason: "핫 번호와 콜드 번호를 균형있게 섞은 조합",
                createdDate: Date()
            ))
        }

        // 4. 상승 트렌드 조합
        let risingNumbers = numberTrends
            .filter { $0.trend == .rising }
            .sorted { $0.deviation > $1.deviation }
            .prefix(10)
            .map { $0.number }
            .shuffled()
            .prefix(6)
            .sorted()

        if risingNumbers.count == 6 {
            recommendedCombinations.append(RecommendedCombination(
                numbers: Array(risingNumbers),
                type: .pattern,
                score: calculateScore(numbers: Array(risingNumbers)),
                reason: "최근 상승 트렌드를 보이는 번호들의 조합",
                createdDate: Date()
            ))
        }

        // 5. 통계 기반 최적 조합
        let optimalNumbers = generateStatisticalOptimal()
        if optimalNumbers.count == 6 {
            recommendedCombinations.append(RecommendedCombination(
                numbers: optimalNumbers,
                type: .statistical,
                score: calculateScore(numbers: optimalNumbers),
                reason: "통계적 분석에 기반한 최적 조합",
                createdDate: Date()
            ))
        }
    }

    private func generateStatisticalOptimal() -> [Int] {
        var optimal: [Int] = []

        // 구간별 균등 분배 (1-10, 11-20, 21-30, 31-40, 41-45)
        let ranges = [(1, 10), (11, 20), (21, 30), (31, 40), (41, 45)]

        for range in ranges {
            let rangeNumbers = numberTrends
                .filter { $0.number >= range.0 && $0.number <= range.1 }
                .sorted { abs($0.deviation) < abs($1.deviation) } // 평균에 가까운 것 선택
                .prefix(range == (41, 45) ? 1 : 1)
                .map { $0.number }

            optimal.append(contentsOf: rangeNumbers)
        }

        // 부족한 만큼 랜덤 추가
        while optimal.count < 6 {
            let randomNumber = Int.random(in: 1...45)
            if !optimal.contains(randomNumber) {
                optimal.append(randomNumber)
            }
        }

        return optimal.prefix(6).sorted()
    }

    private func calculateScore(numbers: [Int]) -> Double {
        var score = 0.0

        for number in numbers {
            if let trend = numberTrends.first(where: { $0.number == number }) {
                // 출현 빈도 점수
                score += trend.frequency * 10

                // 트렌드 점수
                switch trend.trend {
                case .rising: score += 5
                case .stable: score += 3
                case .falling: score += 1
                }

                // 최근 출현 점수
                let recentCount = trend.recentAppearances.filter { $0 }.count
                score += Double(recentCount) * 2
            }
        }

        // 번호 분포 점수 (고른 분포일수록 높은 점수)
        let ranges = [(1, 10), (11, 20), (21, 30), (31, 40), (41, 45)]
        var rangeCount = 0
        for range in ranges {
            if numbers.contains(where: { $0 >= range.0 && $0 <= range.1 }) {
                rangeCount += 1
            }
        }
        score += Double(rangeCount) * 5

        return min(100, score)
    }

    // MARK: - Save/Load Functions

    func saveCombination(_ combination: RecommendedCombination) {
        var updatedCombination = combination
        updatedCombination.isSaved = true

        savedCombinations.append(updatedCombination)
        saveCombinationsToStorage()

        // 추천 목록에서도 업데이트
        if let index = recommendedCombinations.firstIndex(where: { $0.id == combination.id }) {
            recommendedCombinations[index].isSaved = true
        }
    }

    func removeSavedCombination(_ combination: RecommendedCombination) {
        savedCombinations.removeAll { $0.id == combination.id }
        saveCombinationsToStorage()

        // 추천 목록에서도 업데이트
        if let index = recommendedCombinations.firstIndex(where: { $0.id == combination.id }) {
            recommendedCombinations[index].isSaved = false
        }
    }

    private func loadSavedCombinations() {
        if let data = userDefaults.data(forKey: savedCombinationsKey),
           let combinations = try? JSONDecoder().decode([RecommendedCombination].self, from: data) {
            savedCombinations = combinations
        }
    }

    private func saveCombinationsToStorage() {
        if let data = try? JSONEncoder().encode(savedCombinations) {
            userDefaults.set(data, forKey: savedCombinationsKey)
        }
    }
}