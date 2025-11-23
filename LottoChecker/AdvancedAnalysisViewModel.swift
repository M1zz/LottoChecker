import Foundation
import SwiftUI

@MainActor
class AdvancedAnalysisViewModel: ObservableObject {
    @Published var isLoading = false

    // 상관관계 데이터
    @Published var correlationData: [[Int]] = Array(repeating: Array(repeating: 0, count: 45), count: 45)
    @Published var topPairs: [NumberPair] = []
    @Published var hotNumbers: [Int] = []
    @Published var coldNumbers: [Int] = []

    // 패턴 데이터
    @Published var oddEvenDistribution: [Int: Double] = [:]  // 홀수 개수: 비율
    @Published var mostCommonOddCount = 3
    @Published var sectionDistribution: [Double] = [0, 0, 0, 0, 0]  // 각 구간별 평균 개수
    @Published var averageSum: Double = 0
    @Published var optimalSumRange: (Int, Int) = (100, 150)
    @Published var averageConsecutive: Double = 0
    @Published var mostCommonConsecutive = 0
    @Published var averageGap: Double = 0
    @Published var optimalGap = 7

    // 추천 번호
    @Published var recommendedNumbers: [[Int]] = []

    private let service = LottoService.shared
    private var analyzedData: [LottoResponse] = []

    // 분석 결과 캐싱
    private var cachedAnalysisRounds: Int?
    private var cachedAnalysisTime: Date?
    private let analysisCacheDuration: TimeInterval = 3600 // 1시간

    func analyzeData(rounds: Int) async {
        // 캐시된 분석 결과가 유효하면 재사용
        if let cachedRounds = cachedAnalysisRounds,
           let cacheTime = cachedAnalysisTime,
           cachedRounds == rounds,
           Date().timeIntervalSince(cacheTime) < analysisCacheDuration,
           !analyzedData.isEmpty {
            print("✅ 캐시된 분석 결과 사용 - \(rounds)회차 데이터")
            performAnalysis()
            isLoading = false
            return
        }

        print("🔄 새로운 분석 시작 - \(rounds)회차 데이터")
        isLoading = true
        analyzedData.removeAll()

        do {
            let latestRound = try await service.getLatestRound()
            let startRound = rounds == 0 ? 1 : max(1, latestRound - rounds + 1)

            // 데이터 수집
            for round in startRound...latestRound {
                do {
                    let data = try await service.fetchLottoData(round: round)
                    analyzedData.append(data)
                } catch {
                    continue
                }

                if (round - startRound + 1) % 20 == 0 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }

            // 분석 실행
            performAnalysis()

            // 캐시 정보 저장
            cachedAnalysisRounds = rounds
            cachedAnalysisTime = Date()
            print("💾 분석 결과 캐싱 완료 - \(rounds)회차")

        } catch {
            print("분석 중 오류: \(error)")
        }

        isLoading = false
    }

    private func performAnalysis() {
        analyzeCorrelations()
        analyzeHotColdNumbers()
        analyzeOddEvenRatio()
        analyzeSectionDistribution()
        analyzeSumRange()
        analyzeConsecutiveNumbers()
        analyzeGaps()
    }

    // MARK: - Correlation Analysis

    private func analyzeCorrelations() {
        // 번호 쌍 빈도 초기화
        var pairCount: [String: Int] = [:]

        for lotto in analyzedData {
            let numbers = lotto.numbers
            // 모든 쌍 조합 확인
            for i in 0..<numbers.count {
                for j in (i+1)..<numbers.count {
                    let num1 = min(numbers[i], numbers[j])
                    let num2 = max(numbers[i], numbers[j])
                    let key = "\(num1)-\(num2)"
                    pairCount[key, default: 0] += 1
                }
            }
        }

        // 상위 쌍 추출
        let totalGames = Double(analyzedData.count)
        topPairs = pairCount.map { key, count in
            let nums = key.split(separator: "-").compactMap { Int($0) }
            return NumberPair(
                number1: nums[0],
                number2: nums[1],
                count: count,
                percentage: Double(count) / totalGames * 100
            )
        }.sorted { $0.count > $1.count }
    }

    // MARK: - Hot & Cold Analysis

    private func analyzeHotColdNumbers() {
        var recentFrequency: [Int: Int] = [:]

        // 최근 데이터만 사용 (최대 50회)
        let recentData = Array(analyzedData.suffix(min(50, analyzedData.count)))

        for lotto in recentData {
            for number in lotto.numbers {
                recentFrequency[number, default: 0] += 1
            }
        }

        // Hot 번호 (자주 나옴)
        hotNumbers = recentFrequency.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }

        // Cold 번호 (적게 나옴)
        var allNumbers = Set(1...45)
        for (num, _) in recentFrequency.sorted(by: { $0.value > $1.value }).prefix(35) {
            allNumbers.remove(num)
        }
        coldNumbers = Array(allNumbers).sorted().prefix(10).map { $0 }
    }

    // MARK: - Odd/Even Ratio

    private func analyzeOddEvenRatio() {
        var ratioCount: [Int: Int] = [:]

        for lotto in analyzedData {
            let oddCount = lotto.numbers.filter { $0 % 2 == 1 }.count
            ratioCount[oddCount, default: 0] += 1
        }

        let total = Double(analyzedData.count)
        oddEvenDistribution = ratioCount.mapValues { Double($0) / total * 100 }

        mostCommonOddCount = ratioCount.max { $0.value < $1.value }?.key ?? 3
    }

    // MARK: - Section Distribution

    private func analyzeSectionDistribution() {
        var sectionCounts: [[Int]] = Array(repeating: [], count: 5)

        for lotto in analyzedData {
            var counts = [0, 0, 0, 0, 0]
            for number in lotto.numbers {
                let section = min((number - 1) / 10, 4)
                counts[section] += 1
            }
            for i in 0..<5 {
                sectionCounts[i].append(counts[i])
            }
        }

        sectionDistribution = sectionCounts.map { counts in
            let sum = counts.reduce(0, +)
            return Double(sum) / Double(counts.count)
        }
    }

    // MARK: - Sum Range Analysis

    private func analyzeSumRange() {
        var sums: [Int] = []

        for lotto in analyzedData {
            let sum = lotto.numbers.reduce(0, +)
            sums.append(sum)
        }

        if !sums.isEmpty {
            averageSum = Double(sums.reduce(0, +)) / Double(sums.count)

            // 최적 범위: 평균 ± 20
            let avg = Int(averageSum)
            optimalSumRange = (avg - 20, avg + 20)
        }
    }

    // MARK: - Consecutive Numbers

    private func analyzeConsecutiveNumbers() {
        var consecutiveCounts: [Int] = []

        for lotto in analyzedData {
            var count = 0
            let sortedNumbers = lotto.numbers.sorted()

            for i in 0..<(sortedNumbers.count - 1) {
                if sortedNumbers[i + 1] == sortedNumbers[i] + 1 {
                    count += 1
                }
            }
            consecutiveCounts.append(count)
        }

        if !consecutiveCounts.isEmpty {
            averageConsecutive = Double(consecutiveCounts.reduce(0, +)) / Double(consecutiveCounts.count)

            var countFrequency: [Int: Int] = [:]
            for count in consecutiveCounts {
                countFrequency[count, default: 0] += 1
            }
            mostCommonConsecutive = countFrequency.max { $0.value < $1.value }?.key ?? 0
        }
    }

    // MARK: - Gap Analysis

    private func analyzeGaps() {
        var gaps: [Int] = []

        for lotto in analyzedData {
            let sortedNumbers = lotto.numbers.sorted()
            for i in 0..<(sortedNumbers.count - 1) {
                let gap = sortedNumbers[i + 1] - sortedNumbers[i]
                gaps.append(gap)
            }
        }

        if !gaps.isEmpty {
            averageGap = Double(gaps.reduce(0, +)) / Double(gaps.count)

            var gapFrequency: [Int: Int] = [:]
            for gap in gaps {
                gapFrequency[gap, default: 0] += 1
            }
            optimalGap = gapFrequency.max { $0.value < $1.value }?.key ?? 7
        }
    }

    // MARK: - Generate Recommendations

    func generateRecommendations() async {
        isLoading = true

        let hotNumbers = self.hotNumbers
        let mostCommonOddCount = self.mostCommonOddCount

        let recommendations = await withTaskGroup(of: [Int].self) { group in
            var results: [[Int]] = []

            // 5개의 추천 조합 생성
            for _ in 0..<5 {
                group.addTask {
                    return Self.generateOptimizedNumbers(
                        hotNumbers: hotNumbers,
                        mostCommonOddCount: mostCommonOddCount
                    )
                }
            }

            for await result in group {
                results.append(result)
            }

            return results
        }

        self.recommendedNumbers = recommendations
        self.isLoading = false
    }

    nonisolated private static func generateOptimizedNumbers(hotNumbers: [Int], mostCommonOddCount: Int) -> [Int] {
        var numbers: [Int] = []
        var availableNumbers = Set(1...45)

        // 1. Hot 번호에서 2-3개 선택
        let hotCount = Int.random(in: 2...3)
        let selectedHot = Array(hotNumbers.prefix(15).shuffled().prefix(hotCount))
        numbers.append(contentsOf: selectedHot)
        selectedHot.forEach { availableNumbers.remove($0) }

        // 2. 나머지는 최적 조건을 만족하도록 선택
        while numbers.count < 6 {
            // 홀짝 비율 고려
            let currentOdd = numbers.filter { $0 % 2 == 1 }.count
            let needOdd = mostCommonOddCount - currentOdd
            let needEven = (6 - numbers.count) - needOdd

            var candidates = Array(availableNumbers)

            if needOdd > 0 && needEven <= 0 {
                candidates = candidates.filter { $0 % 2 == 1 }
            } else if needEven > 0 && needOdd <= 0 {
                candidates = candidates.filter { $0 % 2 == 0 }
            }

            if let selected = candidates.randomElement() {
                numbers.append(selected)
                availableNumbers.remove(selected)
            } else {
                // 조건을 만족하지 못하면 아무거나 선택
                if let selected = availableNumbers.randomElement() {
                    numbers.append(selected)
                    availableNumbers.remove(selected)
                }
            }
        }

        return numbers.sorted()
    }
}

// MARK: - Models

struct NumberPair {
    let number1: Int
    let number2: Int
    let count: Int
    let percentage: Double
}
