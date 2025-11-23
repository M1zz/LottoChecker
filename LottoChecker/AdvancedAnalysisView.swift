import SwiftUI

struct AdvancedAnalysisView: View {
    @StateObject private var viewModel = AdvancedAnalysisViewModel()
    @State private var selectedAnalysisRange: Int = 100
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("고급 분석 중...")
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 0) {
                        // 분석 범위 선택
                        analysisRangeHeader

                        // 탭 뷰
                        TabView(selection: $selectedTab) {
                            correlationAnalysisTab
                                .tag(0)

                            patternAnalysisTab
                                .tag(1)

                            recommendationTab
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                    }
                }
            }
            .navigationTitle("AI 분석")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if viewModel.correlationData.isEmpty {
                    await viewModel.analyzeData(rounds: selectedAnalysisRange)
                }
            }
        }
    }

    // MARK: - Analysis Range Header

    private var analysisRangeHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("분석 범위")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("범위", selection: $selectedAnalysisRange) {
                    Text("50회").tag(50)
                    Text("100회").tag(100)
                    Text("200회").tag(200)
                    Text("전체").tag(0)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Button {
                Task {
                    await viewModel.analyzeData(rounds: selectedAnalysisRange)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("재분석")
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 10)
        }
        .background(Color.white.opacity(0.7))
    }

    // MARK: - Correlation Analysis Tab

    private var correlationAnalysisTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("번호 간 상관관계")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                // 가장 자주 함께 나오는 번호 쌍
                topPairsCard

                // Hot & Cold 번호
                hotColdCard

                // 번호 간격 분석
                gapAnalysisCard
            }
            .padding()
        }
    }

    // MARK: - Pattern Analysis Tab

    private var patternAnalysisTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("패턴 분석")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                // 홀짝 비율
                oddEvenRatioCard

                // 구간별 분포
                sectionDistributionCard

                // 번호 합계 분석
                sumAnalysisCard

                // 연속 번호 분석
                consecutiveAnalysisCard
            }
            .padding()
        }
    }

    // MARK: - Recommendation Tab

    private var recommendationTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("AI 추천 번호")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("통계 분석 기반으로 최적화된 번호 조합을 추천합니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                ForEach(viewModel.recommendedNumbers.indices, id: \.self) { index in
                    recommendedNumberCard(numbers: viewModel.recommendedNumbers[index], rank: index + 1)
                }

                Button {
                    Task {
                        await viewModel.generateRecommendations()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("새로운 추천 생성")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
            }
            .padding()
        }
    }

    // MARK: - Cards

    private var topPairsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("자주 함께 나오는 번호 쌍 TOP 10")
                .font(.headline)

            Divider()

            ForEach(Array(viewModel.topPairs.prefix(10).enumerated()), id: \.offset) { index, pair in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    HStack(spacing: 8) {
                        numberBall(number: pair.number1, size: 30)
                        Text("+")
                            .foregroundColor(.gray)
                        numberBall(number: pair.number2, size: 30)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(pair.count)회")
                            .font(.headline)
                        Text("\(String(format: "%.1f", pair.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 5)

                if index < 9 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var hotColdCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("최근 트렌드")
                .font(.headline)

            Divider()

            VStack(alignment: .leading, spacing: 15) {
                Text("HOT 번호 (최근 자주 나옴)")
                    .font(.subheadline)
                    .foregroundColor(.red)

                FlowLayout(spacing: 8) {
                    ForEach(viewModel.hotNumbers.prefix(10), id: \.self) { number in
                        HStack(spacing: 4) {
                            numberBall(number: number, size: 28)
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Divider()

                Text("COLD 번호 (최근 안 나옴)")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                FlowLayout(spacing: 8) {
                    ForEach(viewModel.coldNumbers.prefix(10), id: \.self) { number in
                        HStack(spacing: 4) {
                            numberBall(number: number, size: 28)
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var gapAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("번호 간격 분석")
                .font(.headline)

            Divider()

            Text("당첨 번호들 사이의 평균 간격")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack {
                    Text("평균 간격")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", viewModel.averageGap))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    Text("최적 간격")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.optimalGap)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var oddEvenRatioCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("홀짝 비율 분포")
                .font(.headline)

            Divider()

            ForEach(viewModel.oddEvenDistribution.sorted(by: { $0.key > $1.key }), id: \.key) { ratio, percentage in
                HStack {
                    Text("홀수 \(ratio)개")
                        .font(.subheadline)

                    Spacer()

                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.headline)
                        .foregroundColor(.blue)

                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: geometry.size.width * CGFloat(percentage / 100))
                    }
                    .frame(height: 20)
                }
            }

            Text("가장 흔한 비율: 홀수 \(viewModel.mostCommonOddCount)개")
                .font(.caption)
                .foregroundColor(.green)
                .padding(.top, 5)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var sectionDistributionCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("구간별 번호 분포")
                .font(.headline)

            Divider()

            let sections = [
                ("1-10", viewModel.sectionDistribution[0]),
                ("11-20", viewModel.sectionDistribution[1]),
                ("21-30", viewModel.sectionDistribution[2]),
                ("31-40", viewModel.sectionDistribution[3]),
                ("41-45", viewModel.sectionDistribution[4])
            ]

            ForEach(sections, id: \.0) { section, average in
                HStack {
                    Text(section)
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)

                    Text("평균 \(String(format: "%.1f", average))개")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.purple.opacity(0.6))
                            .frame(width: geometry.size.width * CGFloat(average / 3))
                    }
                    .frame(height: 20)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var sumAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("번호 합계 분석")
                .font(.headline)

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("평균 합계")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.averageSum))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    Text("최적 범위")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.optimalSumRange.0) - \(viewModel.optimalSumRange.1)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)

            Text("합계가 이 범위에 있는 조합이 가장 자주 당첨되었습니다")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var consecutiveAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("연속 번호 분석")
                .font(.headline)

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("평균 연속 개수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", viewModel.averageConsecutive))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    Text("가장 흔한")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.mostCommonConsecutive)개")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)

            Text("연속된 번호(예: 5,6,7)가 몇 개나 포함되는지 분석")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private func recommendedNumberCard(numbers: [Int], rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(rank == 1 ? .yellow : rank == 2 ? .gray : .orange)
                    Text("추천 #\(rank)")
                        .font(.headline)
                }

                Spacer()

                Text("최적화 점수: \(Int(calculateOptimizationScore(numbers: numbers)))")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            HStack(spacing: 8) {
                ForEach(numbers, id: \.self) { number in
                    numberBall(number: number, size: 40)
                }
            }

            // 이 조합의 특징
            Text(getRecommendationReason(numbers: numbers))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.9), Color.purple.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(
                    rank == 1 ? Color.yellow : Color.gray.opacity(0.3),
                    lineWidth: rank == 1 ? 2 : 1
                )
        )
    }

    // MARK: - Helper Functions

    private func numberBall(number: Int, size: CGFloat = 45) -> some View {
        Circle()
            .fill(ballColor(for: number))
            .frame(width: size, height: size)
            .overlay(
                Text("\(number)")
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
    }

    private func ballColor(for number: Int) -> Color {
        switch number {
        case 1...10: return Color(red: 0.984, green: 0.769, blue: 0.0) // #FBC400 - 진한 노란색
        case 11...20: return Color(red: 0.412, green: 0.784, blue: 0.949) // #69C8F2 - 하늘색
        case 21...30: return Color(red: 1.0, green: 0.447, blue: 0.447) // #FF7272 - 연한 빨간색
        case 31...40: return Color(red: 0.667, green: 0.698, blue: 0.741) // #AAB2BD - 회색
        default: return Color(red: 0.69, green: 0.847, blue: 0.251) // #B0D840 - 연두색
        }
    }

    private func calculateOptimizationScore(numbers: [Int]) -> Double {
        var score = 0.0

        // 홀짝 비율 점수
        let oddCount = numbers.filter { $0 % 2 == 1 }.count
        if oddCount == viewModel.mostCommonOddCount {
            score += 30
        }

        // 구간 분포 점수
        score += 20

        // Hot 번호 포함 점수
        let hotIncluded = numbers.filter { viewModel.hotNumbers.prefix(10).contains($0) }.count
        score += Double(hotIncluded) * 5

        // 번호 합계 점수
        let sum = numbers.reduce(0, +)
        if sum >= viewModel.optimalSumRange.0 && sum <= viewModel.optimalSumRange.1 {
            score += 25
        }

        return min(score, 100)
    }

    private func getRecommendationReason(numbers: [Int]) -> String {
        var reasons: [String] = []

        let oddCount = numbers.filter { $0 % 2 == 1 }.count
        reasons.append("홀수 \(oddCount)개")

        let sum = numbers.reduce(0, +)
        reasons.append("합계 \(sum)")

        let hotCount = numbers.filter { viewModel.hotNumbers.prefix(10).contains($0) }.count
        if hotCount > 0 {
            reasons.append("HOT 번호 \(hotCount)개 포함")
        }

        return reasons.joined(separator: " • ")
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    AdvancedAnalysisView()
}
