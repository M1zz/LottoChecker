import SwiftUI

struct ProbabilityCalculatorView: View {
    @StateObject private var viewModel = ProbabilityViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 앱 소개 카드
                        introCard

                        // 확률 계산 카드들
                        ForEach(viewModel.probabilityItems) { item in
                            probabilityCard(item: item)
                        }

                        // 기대값 설명 카드
                        expectedValueExplanationCard
                    }
                    .padding()
                }
            }
            .navigationTitle("확률계산기")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - View Components

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "function")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("확률의 이해")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("로또 6/45는 1부터 45까지의 숫자 중 6개를 선택하는 게임입니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("각 등수별 당첨 확률과 기대 시행 횟수를 확인해보세요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private func probabilityCard(item: ProbabilityItem) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // 헤더
            HStack {
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(item.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // 확률 정보
            VStack(spacing: 12) {
                // 당첨 확률
                HStack {
                    Text("당첨 확률")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1 / \(formatNumber(item.denominator))")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                // 퍼센트 표시
                HStack {
                    Text("백분율")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(item.percentageText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(item.color)
                }

                Divider()

                // 기대 시행 횟수
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("기대 당첨까지 필요한 시행 횟수")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("\(formatNumber(item.expectedTrials))회")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(item.color)
                        Spacer()
                    }

                    Text("약 \(item.expectedCostText) 투자")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(item.color.opacity(0.1))
                .cornerRadius(12)

                // 설명
                if let explanation = item.explanation {
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var expectedValueExplanationCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("기대값이란?")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "1.circle.fill",
                    text: "확률이 0.01(1%)이라면, 평균적으로 100번 시도해야 1번 당첨됩니다."
                )

                InfoRow(
                    icon: "2.circle.fill",
                    text: "하지만 이것은 평균값입니다. 실제로는 더 적게 또는 더 많이 시도해야 할 수 있습니다."
                )

                InfoRow(
                    icon: "3.circle.fill",
                    text: "100번 시도한다고 해서 반드시 당첨되는 것은 아닙니다. 약 63.2%의 확률로 1번 이상 당첨됩니다."
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Helper Functions

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Models

struct ProbabilityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let denominator: Int
    let probability: Double
    let expectedTrials: Int
    let explanation: String?

    var percentageText: String {
        if probability < 0.000001 {
            return String(format: "%.8f%%", probability * 100)
        } else if probability < 0.0001 {
            return String(format: "%.6f%%", probability * 100)
        } else if probability < 0.01 {
            return String(format: "%.4f%%", probability * 100)
        } else {
            return String(format: "%.2f%%", probability * 100)
        }
    }

    var expectedCostText: String {
        let cost = expectedTrials * 1000
        if cost >= 100_000_000 {
            return String(format: "%.0f억원", Double(cost) / 100_000_000)
        } else if cost >= 10_000 {
            return String(format: "%.0f만원", Double(cost) / 10_000)
        } else {
            return "\(cost)원"
        }
    }
}

// MARK: - ViewModel

@MainActor
class ProbabilityViewModel: ObservableObject {
    @Published var probabilityItems: [ProbabilityItem] = []

    init() {
        calculateProbabilities()
    }

    private func calculateProbabilities() {
        // 조합 계산 함수
        func combination(_ n: Int, _ r: Int) -> Int {
            guard r <= n else { return 0 }
            if r == 0 || r == n { return 1 }

            var result = 1
            for i in 0..<r {
                result *= (n - i)
                result /= (i + 1)
            }
            return result
        }

        // 전체 경우의 수: 45C6
        let totalCombinations = combination(45, 6)

        // 1등: 6개 모두 맞춤
        let rank1Cases = 1
        let rank1Probability = Double(rank1Cases) / Double(totalCombinations)

        // 2등: 5개 맞추고 + 보너스 맞춤
        let rank2Cases = combination(6, 5) * combination(39, 0) * 1 // 5개 선택 * 보너스 1개
        let rank2Probability = Double(rank2Cases) / Double(totalCombinations)

        // 3등: 5개 맞춤 (보너스 X)
        let rank3Cases = combination(6, 5) * combination(38, 1) // 5개 선택 * 나머지 38개 중 1개
        let rank3Probability = Double(rank3Cases) / Double(totalCombinations)

        // 4등: 4개 맞춤
        let rank4Cases = combination(6, 4) * combination(39, 2)
        let rank4Probability = Double(rank4Cases) / Double(totalCombinations)

        // 5등: 3개 맞춤
        let rank5Cases = combination(6, 3) * combination(39, 3)
        let rank5Probability = Double(rank5Cases) / Double(totalCombinations)

        probabilityItems = [
            ProbabilityItem(
                title: "1등 당첨",
                subtitle: "6개 번호 모두 일치",
                icon: "crown.fill",
                color: .yellow,
                denominator: totalCombinations,
                probability: rank1Probability,
                expectedTrials: totalCombinations,
                explanation: "약 814만번 구매해야 1번 당첨될 확률입니다."
            ),
            ProbabilityItem(
                title: "2등 당첨",
                subtitle: "5개 번호 + 보너스 번호 일치",
                icon: "star.fill",
                color: .orange,
                denominator: totalCombinations / rank2Cases,
                probability: rank2Probability,
                expectedTrials: totalCombinations / rank2Cases,
                explanation: "약 136만번 구매해야 1번 당첨될 확률입니다."
            ),
            ProbabilityItem(
                title: "3등 당첨",
                subtitle: "5개 번호 일치",
                icon: "star.circle.fill",
                color: .red,
                denominator: totalCombinations / rank3Cases,
                probability: rank3Probability,
                expectedTrials: totalCombinations / rank3Cases,
                explanation: "약 3만 5천번 구매해야 1번 당첨될 확률입니다."
            ),
            ProbabilityItem(
                title: "4등 당첨",
                subtitle: "4개 번호 일치",
                icon: "gift.fill",
                color: .purple,
                denominator: totalCombinations / rank4Cases,
                probability: rank4Probability,
                expectedTrials: totalCombinations / rank4Cases,
                explanation: "약 733번 구매하면 1번 당첨될 확률입니다."
            ),
            ProbabilityItem(
                title: "5등 당첨",
                subtitle: "3개 번호 일치",
                icon: "ticket.fill",
                color: .blue,
                denominator: totalCombinations / rank5Cases,
                probability: rank5Probability,
                expectedTrials: totalCombinations / rank5Cases,
                explanation: "약 45번 구매하면 1번 당첨될 확률입니다."
            )
        ]
    }
}

#Preview {
    ProbabilityCalculatorView()
}
