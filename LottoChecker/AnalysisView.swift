import SwiftUI

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var selectedRange: AnalysisRange = .recent50

    enum AnalysisRange: String, CaseIterable {
        case recent10 = "최근 10회"
        case recent50 = "최근 50회"
        case recent100 = "최근 100회"
        case all = "전체"

        var count: Int {
            switch self {
            case .recent10: return 10
            case .recent50: return 50
            case .recent100: return 100
            case .all: return 0
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.orange.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("분석 중...")
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 분석 범위 선택
                            rangePickerCard

                            if !viewModel.statistics.isEmpty {
                                // 통계 요약
                                summaryCard

                                // 번호별 출현 빈도
                                frequencyCard

                                // Top 번호
                                topNumbersCard
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("번호 분석")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if viewModel.statistics.isEmpty {
                    await viewModel.analyzeData(range: selectedRange.count)
                }
            }
        }
    }

    // MARK: - View Components

    private var rangePickerCard: some View {
        VStack(spacing: 15) {
            Text("분석 범위")
                .font(.headline)

            Picker("분석 범위", selection: $selectedRange) {
                ForEach(AnalysisRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task {
                    await viewModel.analyzeData(range: selectedRange.count)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("분석 시작")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("통계 요약")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("분석 회차")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("\(viewModel.analyzedRounds)회")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("총 추출 번호")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("\(viewModel.totalNumbersDrawn)개")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }

            if let mostFrequent = viewModel.statistics.max(by: { $0.count < $1.count }) {
                Divider()
                HStack {
                    Text("최다 출현 번호")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 8) {
                        numberBall(number: mostFrequent.number, size: 35)
                        Text("\(mostFrequent.count)회 (\(String(format: "%.1f", mostFrequent.percentage))%)")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var frequencyCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("번호별 출현 빈도")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(viewModel.statistics.sorted(by: { $0.number < $1.number }), id: \.number) { stat in
                    VStack(spacing: 5) {
                        numberBall(number: stat.number, size: 40)
                        Text("\(stat.count)회")
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Text("\(String(format: "%.1f", stat.percentage))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.5))
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var topNumbersCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("출현 빈도 순위")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            // Top 10
            VStack(alignment: .leading, spacing: 10) {
                Text("TOP 10 (많이 나온 번호)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                ForEach(Array(viewModel.topNumbers.prefix(10).enumerated()), id: \.element.number) { index, stat in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 25)

                        numberBall(number: stat.number, size: 35)

                        Text("\(stat.count)회")
                            .fontWeight(.semibold)

                        Spacer()

                        // 막대 그래프
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.green.opacity(0.6))
                                .frame(width: geometry.size.width * CGFloat(stat.percentage / 100))
                        }
                        .frame(height: 20)

                        Text("\(String(format: "%.1f", stat.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }

            Divider()

            // Bottom 10
            VStack(alignment: .leading, spacing: 10) {
                Text("적게 나온 번호")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                ForEach(Array(viewModel.bottomNumbers.prefix(10).enumerated()), id: \.element.number) { index, stat in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 25)

                        numberBall(number: stat.number, size: 35)

                        Text("\(stat.count)회")
                            .fontWeight(.semibold)

                        Spacer()

                        // 막대 그래프
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.orange.opacity(0.6))
                                .frame(width: geometry.size.width * CGFloat(stat.percentage / 100))
                        }
                        .frame(height: 20)

                        Text("\(String(format: "%.1f", stat.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
        case 1...10:
            return Color(red: 0.984, green: 0.769, blue: 0.0) // #FBC400 - 진한 노란색
        case 11...20:
            return Color(red: 0.412, green: 0.784, blue: 0.949) // #69C8F2 - 하늘색
        case 21...30:
            return Color(red: 1.0, green: 0.447, blue: 0.447) // #FF7272 - 연한 빨간색
        case 31...40:
            return Color(red: 0.667, green: 0.698, blue: 0.741) // #AAB2BD - 회색
        default:
            return Color(red: 0.69, green: 0.847, blue: 0.251) // #B0D840 - 연두색
        }
    }
}

// MARK: - ViewModel

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var statistics: [NumberStatistic] = []
    @Published var isLoading = false
    @Published var analyzedRounds = 0
    @Published var totalNumbersDrawn = 0

    private let service = LottoService.shared

    var topNumbers: [NumberStatistic] {
        statistics.sorted { $0.count > $1.count }
    }

    var bottomNumbers: [NumberStatistic] {
        statistics.sorted { $0.count < $1.count }
    }

    func analyzeData(range: Int) async {
        isLoading = true
        var frequencyMap: [Int: Int] = [:]

        do {
            let latestRound = try await service.getLatestRound()
            let startRound: Int
            if range == 0 {
                startRound = 1
            } else {
                startRound = max(1, latestRound - range + 1)
            }

            var successfulFetches = 0

            for round in startRound...latestRound {
                do {
                    let data = try await service.fetchLottoData(round: round)
                    for number in data.numbers {
                        frequencyMap[number, default: 0] += 1
                    }
                    successfulFetches += 1
                } catch {
                    continue
                }

                // 10회차마다 잠깐 대기 (API 과부하 방지)
                if (round - startRound + 1) % 10 == 0 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                }
            }

            analyzedRounds = successfulFetches
            totalNumbersDrawn = frequencyMap.values.reduce(0, +)

            // 통계 계산
            let stats = frequencyMap.map { number, count in
                NumberStatistic(
                    number: number,
                    count: count,
                    percentage: Double(count) / Double(successfulFetches) * 100
                )
            }

            statistics = stats
        } catch {
            print("분석 중 오류: \(error)")
        }

        isLoading = false
    }
}

struct NumberStatistic {
    let number: Int
    let count: Int
    let percentage: Double
}

#Preview {
    AnalysisView()
}
