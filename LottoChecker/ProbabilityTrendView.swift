import SwiftUI
import Charts

struct ProbabilityTrendView: View {
    @StateObject private var viewModel = ProbabilityAnalysisViewModel()
    @State private var selectedTab = 0
    @State private var showingSavedCombinations = false

    private func ballColor(for number: Int) -> Color {
        switch number {
        case 1...10:
            return Color(red: 1.0, green: 0.7, blue: 0.0)
        case 11...20:
            return Color(red: 0.0, green: 0.5, blue: 1.0)
        case 21...30:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        case 31...40:
            return Color(red: 0.4, green: 0.4, blue: 0.4)
        case 41...45:
            return Color(red: 0.0, green: 0.7, blue: 0.3)
        default:
            return Color.gray
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isAnalyzing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("데이터 분석 중...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 기간 선택
                            timeRangeSelector

                            // 탭 선택
                            Picker("", selection: $selectedTab) {
                                Text("출현 추이").tag(0)
                                Text("추천 조합").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            if selectedTab == 0 {
                                // 출현 추이 분석
                                trendAnalysisSection
                            } else {
                                // 추천 조합
                                recommendationSection
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("확률 분석")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSavedCombinations = true
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .task {
                if viewModel.numberTrends.isEmpty {
                    await viewModel.analyzeNumberTrends()
                }
            }
            .sheet(isPresented: $showingSavedCombinations) {
                SavedCombinationsView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Components

    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("분석 기간")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([10, 30, 50, 100], id: \.self) { range in
                        Button {
                            viewModel.selectedTimeRange = range
                            Task {
                                await viewModel.analyzeNumberTrends()
                            }
                        } label: {
                            Text("최근 \(range)회")
                                .font(.subheadline)
                                .fontWeight(viewModel.selectedTimeRange == range ? .bold : .medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedTimeRange == range ?
                                    Color.blue : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    viewModel.selectedTimeRange == range ?
                                    .white : .primary
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var trendAnalysisSection: some View {
        VStack(spacing: 15) {
            // 출현 빈도 차트
            frequencyChartCard

            // 트렌드 분석
            trendAnalysisCard

            // 번호별 상세 분석
            numberDetailCards
        }
        .padding(.horizontal)
    }

    private var frequencyChartCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("출현 빈도 분포")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(viewModel.numberTrends.sorted { $0.number < $1.number }) { trend in
                        VStack(spacing: 4) {
                            // 막대 그래프
                            Rectangle()
                                .fill(
                                    trend.deviation > 10 ? Color.red.opacity(0.8) :
                                    trend.deviation < -10 ? Color.blue.opacity(0.8) :
                                    Color.gray.opacity(0.5)
                                )
                                .frame(width: 25, height: CGFloat(max(10, trend.appearances * 3)))

                            Text("\(trend.number)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 150)
                .padding(.vertical, 10)
            }

            HStack(spacing: 20) {
                Label("높은 빈도", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Label("평균", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Label("낮은 빈도", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .font(.caption2)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var trendAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.purple)
                Text("트렌드 분석")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // 상승/하락/안정 트렌드 요약
            HStack(spacing: 15) {
                TrendSummaryBox(
                    title: "상승",
                    count: viewModel.numberTrends.filter { $0.trend == .rising }.count,
                    color: .red,
                    icon: "arrow.up.circle.fill"
                )
                TrendSummaryBox(
                    title: "안정",
                    count: viewModel.numberTrends.filter { $0.trend == .stable }.count,
                    color: .gray,
                    icon: "minus.circle.fill"
                )
                TrendSummaryBox(
                    title: "하락",
                    count: viewModel.numberTrends.filter { $0.trend == .falling }.count,
                    color: .blue,
                    icon: "arrow.down.circle.fill"
                )
            }

            Divider()

            // 주목할 번호들
            VStack(alignment: .leading, spacing: 10) {
                Text("주목할 번호")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // 급상승 번호
                if let topRising = viewModel.numberTrends
                    .filter({ $0.trend == .rising })
                    .sorted(by: { $0.deviation > $1.deviation })
                    .first {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        Text("급상승")
                            .font(.caption)
                        Spacer()
                        LottoBall(number: topRising.number, size: 30)
                        Text("+\(String(format: "%.1f", topRising.deviation))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }

                // 급하락 번호
                if let topFalling = viewModel.numberTrends
                    .filter({ $0.trend == .falling })
                    .sorted(by: { $0.deviation < $1.deviation })
                    .first {
                    HStack {
                        Image(systemName: "snowflake")
                            .foregroundColor(.blue)
                        Text("급하락")
                            .font(.caption)
                        Spacer()
                        LottoBall(number: topFalling.number, size: 30)
                        Text("\(String(format: "%.1f", topFalling.deviation))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var numberDetailCards: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("번호별 상세 분석")
                .font(.headline)
                .fontWeight(.semibold)

            // Top 10 핫 번호
            DetailCard(
                title: "핫 번호 TOP 10",
                icon: "flame.fill",
                color: .red,
                numbers: Array(viewModel.numberTrends
                    .sorted { $0.deviation > $1.deviation }
                    .prefix(10))
            )

            // Top 10 콜드 번호
            DetailCard(
                title: "콜드 번호 TOP 10",
                icon: "snowflake",
                color: .blue,
                numbers: Array(viewModel.numberTrends
                    .sorted { $0.deviation < $1.deviation }
                    .prefix(10))
            )
        }
    }

    private var recommendationSection: some View {
        VStack(spacing: 15) {
            ForEach(viewModel.recommendedCombinations) { combination in
                RecommendationCard(
                    combination: combination,
                    onSave: {
                        viewModel.saveCombination(combination)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct TrendSummaryBox: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailCard: View {
    let title: String
    let icon: String
    let color: Color
    let numbers: [NumberTrend]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(numbers) { trend in
                        VStack(spacing: 6) {
                            LottoBall(number: trend.number, size: 36)

                            Text("\(trend.appearances)회")
                                .font(.caption2)
                                .fontWeight(.semibold)

                            Text("\(String(format: "%+.1f", trend.deviation))%")
                                .font(.caption2)
                                .foregroundColor(trend.deviation > 0 ? .red : .blue)

                            Image(systemName: trend.trend.icon)
                                .font(.caption)
                                .foregroundColor(trend.trend.color)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
}

struct RecommendationCard: View {
    let combination: RecommendedCombination
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(combination.type.rawValue, systemImage: "star.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(combination.type.color)

                Spacer()

                if combination.isSaved {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.orange)
                } else {
                    Button(action: onSave) {
                        Image(systemName: "bookmark")
                            .foregroundColor(.gray)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach(combination.numbers, id: \.self) { number in
                    LottoBall(number: number, size: 36)
                }
            }

            Text(combination.reason)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Label("점수: \(Int(combination.score))/100", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Spacer()

                Text(combination.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
}

#Preview {
    ProbabilityTrendView()
}