import SwiftUI

struct EnhancedStatisticsView: View {
    @StateObject private var viewModel = EnhancedStatisticsViewModel()
    @StateObject private var probabilityViewModel = ProbabilityAnalysisViewModel()
    @State private var selectedRange: AnalysisRange = .recent10
    @State private var selectedCategory: StatCategory = .frequency
    @State private var selectedCombination: Set<Int> = []
    @State private var savedCombinations: [(name: String, numbers: Set<Int>, probability: Double)] = []
    @State private var showSaveDialog = false
    @State private var combinationName = ""
    @State private var selectedSegment = 0 // 0: 통계 분석, 1: 확률 분석
    @State private var probabilitySelectedTab = 0 // For probability view tabs
    @State private var showingSavedCombinations = false

    enum AnalysisRange: String, CaseIterable {
        case recent10 = "최근 10회"
        case recent30 = "최근 30회"
        case recent50 = "최근 50회"
        case recent100 = "최근 100회"

        var count: Int {
            switch self {
            case .recent10: return 10
            case .recent30: return 30
            case .recent50: return 50
            case .recent100: return 100
            }
        }
    }

    enum StatCategory: String, CaseIterable {
        case frequency = "출현 빈도"
        case hot = "핫 번호"
        case cold = "콜드 번호"
        case patterns = "패턴 분석"
        case probability = "확률 분석"
        case combinations = "번호 조합"

        var icon: String {
            switch self {
            case .frequency: return "chart.bar.fill"
            case .hot: return "flame.fill"
            case .cold: return "snowflake"
            case .patterns: return "chart.line.uptrend.xyaxis"
            case .probability: return "percent"
            case .combinations: return "square.grid.3x3.fill"
            }
        }

        var color: Color {
            switch self {
            case .frequency: return .blue
            case .hot: return .red
            case .cold: return .cyan
            case .patterns: return .purple
            case .probability: return .green
            case .combinations: return .orange
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment Control
                    Picker("", selection: $selectedSegment) {
                        Text("통계 분석").tag(0)
                        Text("확률 분석").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 5)

                    if selectedSegment == 0 {
                        // Statistics Analysis
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView("분석 중...")
                                .scaleEffect(1.5)
                            Spacer()
                        } else {
                            ScrollView {
                                VStack(spacing: 20) {
                                    // 범위 선택
                                    rangeSelectionCard

                                    // 카테고리 선택
                                    categorySelectionCard

                                    // 선택된 카테고리에 따른 컨텐츠
                                    switch selectedCategory {
                                    case .frequency:
                                        frequencyAnalysisCard
                                    case .hot:
                                        hotNumbersCard
                                    case .cold:
                                        coldNumbersCard
                                    case .patterns:
                                        patternAnalysisCard
                                    case .probability:
                                        probabilityAnalysisCard
                                    case .combinations:
                                        combinationsCard
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        // Probability Analysis
                        probabilityAnalysisContent
                    }
                }
            }
            .navigationTitle(selectedSegment == 0 ? "통계 분석" : "확률 분석")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedSegment == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSavedCombinations = true
                        } label: {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .task {
                if viewModel.statistics.isEmpty {
                    await viewModel.analyzeData(range: selectedRange.count)
                }
                if selectedSegment == 1 && probabilityViewModel.numberTrends.isEmpty {
                    await probabilityViewModel.analyzeNumberTrends()
                }
            }
            .sheet(isPresented: $showingSavedCombinations) {
                SavedCombinationsView(viewModel: probabilityViewModel)
            }
        }
    }

    // MARK: - View Components

    private var probabilityAnalysisContent: some View {
        ZStack {
            if probabilityViewModel.isAnalyzing {
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
                        Picker("", selection: $probabilitySelectedTab) {
                            Text("출현 추이").tag(0)
                            Text("추천 조합").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if probabilitySelectedTab == 0 {
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
    }

    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("분석 기간")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([10, 30, 50, 100], id: \.self) { range in
                        Button {
                            probabilityViewModel.selectedTimeRange = range
                            Task {
                                await probabilityViewModel.analyzeNumberTrends()
                            }
                        } label: {
                            Text("최근 \(range)회")
                                .font(.subheadline)
                                .fontWeight(probabilityViewModel.selectedTimeRange == range ? .bold : .medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    probabilityViewModel.selectedTimeRange == range ?
                                    Color.blue : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    probabilityViewModel.selectedTimeRange == range ?
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
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.blue)
                Text("자주 나온 번호 페어")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            if probabilityViewModel.numberPairs.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                // Top 15 페어 표시
                let topPairs = Array(probabilityViewModel.numberPairs.prefix(15))

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(topPairs) { pair in
                            PairCard(pair: pair)
                        }
                    }
                }
                .frame(maxHeight: 300)

                Divider()

                // 통계 정보
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("분석 기간")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("최근 \(probabilityViewModel.selectedTimeRange)회")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("총 페어 수")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(probabilityViewModel.numberPairs.count)개")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
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
                    count: probabilityViewModel.numberTrends.filter { $0.trend == .rising }.count,
                    color: .red,
                    icon: "arrow.up.circle.fill"
                )
                TrendSummaryBox(
                    title: "안정",
                    count: probabilityViewModel.numberTrends.filter { $0.trend == .stable }.count,
                    color: .gray,
                    icon: "minus.circle.fill"
                )
                TrendSummaryBox(
                    title: "하락",
                    count: probabilityViewModel.numberTrends.filter { $0.trend == .falling }.count,
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
                if let topRising = probabilityViewModel.numberTrends
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
                if let topFalling = probabilityViewModel.numberTrends
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
                numbers: Array(probabilityViewModel.numberTrends
                    .sorted { $0.deviation > $1.deviation }
                    .prefix(10))
            )

            // Top 10 콜드 번호
            DetailCard(
                title: "콜드 번호 TOP 10",
                icon: "snowflake",
                color: .blue,
                numbers: Array(probabilityViewModel.numberTrends
                    .sorted { $0.deviation < $1.deviation }
                    .prefix(10))
            )
        }
    }

    private var recommendationSection: some View {
        VStack(spacing: 15) {
            ForEach(probabilityViewModel.recommendedCombinations) { combination in
                RecommendationCard(
                    combination: combination,
                    onSave: {
                        probabilityViewModel.saveCombination(combination)
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    private var rangeSelectionCard: some View {
        VStack(spacing: 12) {
            Text("분석 범위")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("분석 범위", selection: $selectedRange) {
                ForEach(AnalysisRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedRange) { _, newValue in
                Task {
                    await viewModel.analyzeData(range: newValue.count)
                }
            }

            if viewModel.analyzedRounds > 0 {
                Text("\(viewModel.analyzedRounds)회차 분석 완료")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var categorySelectionCard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
    }

    private var frequencyAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("전체 번호 출현 빈도")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Divider()

            // 번호별 빈도 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(1...45, id: \.self) { number in
                    let stat = viewModel.statistics.first(where: { $0.number == number })
                    FrequencyBall(
                        number: number,
                        count: stat?.count ?? 0,
                        percentage: stat?.percentage ?? 0,
                        maxCount: viewModel.maxCount
                    )
                }
            }

            // 평균 출현 횟수
            if !viewModel.statistics.isEmpty {
                HStack {
                    Text("평균 출현")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f회", viewModel.averageCount))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var hotNumbersCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                Text("핫 번호 (자주 나온 번호)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("최근 \(selectedRange.count)회차에서 평균보다 자주 나온 번호들")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            if !viewModel.hotNumbers.isEmpty {
                ForEach(Array(viewModel.hotNumbers.prefix(10).enumerated()), id: \.element.number) { index, stat in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        LottoBall(number: stat.number, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stat.count)회 출현")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("평균 대비 +\(String(format: "%.1f", stat.deviation))%")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Spacer()

                        // 히트 게이지
                        HeatGauge(percentage: stat.heatLevel)
                    }
                    .padding(.vertical, 6)
                }
            } else {
                Text("데이터를 분석 중입니다...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var coldNumbersCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "snowflake")
                    .foregroundColor(.cyan)
                Text("콜드 번호 (적게 나온 번호)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("최근 \(selectedRange.count)회차에서 평균보다 적게 나온 번호들")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            if !viewModel.coldNumbers.isEmpty {
                ForEach(Array(viewModel.coldNumbers.prefix(10).enumerated()), id: \.element.number) { index, stat in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        LottoBall(number: stat.number, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stat.count)회 출현")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("평균 대비 \(String(format: "%.1f", stat.deviation))%")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }

                        Spacer()

                        // 콜드 게이지
                        ColdGauge(percentage: abs(stat.deviation))
                    }
                    .padding(.vertical, 6)
                }
            } else {
                Text("데이터를 분석 중입니다...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var patternAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                Text("패턴 분석")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Divider()

            // 구간별 분포
            VStack(alignment: .leading, spacing: 12) {
                Text("번호 구간별 분포")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(viewModel.rangeDistribution, id: \.range) { dist in
                    HStack {
                        Text(dist.range)
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.1))

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(dist.color.opacity(0.6))
                                    .frame(width: geometry.size.width * CGFloat(dist.percentage / 100))
                            }
                        }
                        .frame(height: 25)

                        Text("\(dist.count)개")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            Divider()

            // 홀짝 분석
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("홀수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.oddCount)개")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("\(String(format: "%.1f", viewModel.oddPercentage))%")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 8) {
                    Text("짝수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.evenCount)개")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("\(String(format: "%.1f", viewModel.evenPercentage))%")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var probabilityAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "percent")
                    .foregroundColor(.green)
                Text("확률 기반 분석")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Divider()

            // 핫 번호 선택 시 확률
            VStack(alignment: .leading, spacing: 10) {
                Text("핫 번호 6개 선택 시")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if viewModel.hotNumbers.count >= 6 {
                    let hotSix = Array(viewModel.hotNumbers.prefix(6))
                    HStack(spacing: 6) {
                        ForEach(hotSix, id: \.number) { stat in
                            LottoBall(number: stat.number, size: 35)
                        }
                    }

                    Text("이 조합의 이론적 당첨 확률")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("1등: 1 / 8,145,060")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 2)
                }
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(12)

            // 콜드 번호 제외 시 확률
            VStack(alignment: .leading, spacing: 10) {
                Text("콜드 번호 10개 제외 시")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if viewModel.coldNumbers.count >= 10 {
                    let coldTen = Array(viewModel.coldNumbers.prefix(10))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(coldTen, id: \.number) { stat in
                                LottoBall(number: stat.number, size: 30)
                                    .opacity(0.5)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    )
                            }
                        }
                    }

                    Text("남은 35개 중 6개 선택")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Text("확률 약 25% 증가")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 2)
                }
            }
            .padding()
            .background(Color.cyan.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var combinationsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(.orange)
                Text("번호 조합 분석")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("번호 조합을 선택하고 확률을 계산하여 저장하세요")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // 번호 선택 영역
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("번호 선택")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(selectedCombination.count)/6")
                        .font(.caption)
                        .foregroundColor(selectedCombination.count == 6 ? .green : .secondary)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                    ForEach(1...45, id: \.self) { number in
                        CombinationNumberButton(
                            number: number,
                            isSelected: selectedCombination.contains(number),
                            onTap: {
                                toggleCombinationNumber(number)
                            }
                        )
                        .disabled(selectedCombination.count >= 6 && !selectedCombination.contains(number))
                    }
                }

                // 선택된 번호 표시
                if !selectedCombination.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(selectedCombination.sorted(), id: \.self) { number in
                            LottoBall(number: number, size: 36)
                        }
                    }
                    .padding(.top, 8)
                }

                // 확률 계산 결과
                if selectedCombination.count == 6 {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.green)
                            Text("확률 분석")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        let probability = calculateCombinationProbability()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("1등 확률:")
                                    .font(.caption)
                                Spacer()
                                Text("1 / 8,145,060")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("이 조합의 출현 확률:")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.8f%%", probability * 100))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }

                            HStack {
                                Text("예상 대기 회차:")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(1.0 / probability))회")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(12)

                        // 저장 버튼
                        Button {
                            if selectedCombination.count == 6 {
                                showSaveDialog = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("조합 저장")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            // 저장된 조합들
            if !savedCombinations.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("저장된 조합")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(savedCombinations.enumerated()), id: \.offset) { index, combination in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(combination.name)
                                    .font(.caption)
                                    .fontWeight(.medium)

                                HStack(spacing: 4) {
                                    ForEach(combination.numbers.sorted(), id: \.self) { number in
                                        LottoBall(number: number, size: 28)
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.6f%%", combination.probability * 100))
                                    .font(.caption2)
                                    .foregroundColor(.orange)

                                Button {
                                    savedCombinations.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .alert("조합 저장", isPresented: $showSaveDialog) {
            TextField("조합 이름", text: $combinationName)
            Button("취소", role: .cancel) {
                combinationName = ""
            }
            Button("저장") {
                saveCombination()
            }
        } message: {
            Text("이 조합에 이름을 지정하세요")
        }
    }

    private func toggleCombinationNumber(_ number: Int) {
        if selectedCombination.contains(number) {
            selectedCombination.remove(number)
        } else if selectedCombination.count < 6 {
            selectedCombination.insert(number)
        }
    }

    private func calculateCombinationProbability() -> Double {
        // 45C6 = 8,145,060
        return 1.0 / 8145060.0
    }

    private func saveCombination() {
        if !combinationName.isEmpty && selectedCombination.count == 6 {
            let probability = calculateCombinationProbability()
            savedCombinations.append((
                name: combinationName,
                numbers: selectedCombination,
                probability: probability
            ))
            combinationName = ""
        }
    }
}

// MARK: - Supporting Views

struct CombinationNumberButton: View {
    let number: Int
    let isSelected: Bool
    let onTap: () -> Void

    private func ballColor(for number: Int) -> Color {
        switch number {
        case 1...10:
            return Color(red: 1.0, green: 0.7, blue: 0.0) // 노란색
        case 11...20:
            return Color(red: 0.0, green: 0.5, blue: 1.0) // 파란색
        case 21...30:
            return Color(red: 1.0, green: 0.3, blue: 0.3) // 빨간색
        case 31...40:
            return Color(red: 0.4, green: 0.4, blue: 0.4) // 회색
        case 41...45:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 초록색
        default:
            return Color.gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    ballColor(for: number),
                                    ballColor(for: number).opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: ballColor(for: number).opacity(0.5), radius: 2, x: 0, y: 1)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(ballColor(for: number).opacity(0.3), lineWidth: 1)
                        )
                }

                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct CategoryButton: View {
    let category: EnhancedStatisticsView.StatCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : category.color)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? category.color.opacity(0.3) : .clear, radius: 8)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct FrequencyBall: View {
    let number: Int
    let count: Int
    let percentage: Double
    let maxCount: Int

    private var intensityLevel: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                LottoBall(number: number, size: 45)
                    .opacity(0.3 + intensityLevel * 0.7)

                if count > 0 {
                    Circle()
                        .strokeBorder(Color.green, lineWidth: intensityLevel * 3)
                        .frame(width: 45, height: 45)
                }
            }

            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)

            Text("\(String(format: "%.1f", percentage))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct HeatGauge: View {
    let percentage: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(percentage / 100, 1.0)), height: 8)
            }
        }
        .frame(width: 60, height: 8)
    }
}

struct ColdGauge: View {
    let percentage: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.cyan.opacity(0.3), .cyan, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(percentage / 100, 1.0)), height: 8)
            }
        }
        .frame(width: 60, height: 8)
    }
}

// 로또 공식 색상을 사용하는 공 컴포넌트
struct LottoBall: View {
    let number: Int
    let size: CGFloat

    private var ballColor: Color {
        switch number {
        case 1...10:
            return Color(red: 251/255, green: 196/255, blue: 0/255) // 노란색
        case 11...20:
            return Color(red: 105/255, green: 200/255, blue: 242/255) // 파란색
        case 21...30:
            return Color(red: 255/255, green: 114/255, blue: 114/255) // 빨간색
        case 31...40:
            return Color(red: 170/255, green: 178/255, blue: 189/255) // 회색
        default: // 41...45
            return Color(red: 176/255, green: 216/255, blue: 64/255) // 초록색
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            ballColor,
                            ballColor.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        center: .init(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.3
                    )
                )
                .frame(width: size, height: size)

            Text("\(number)")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
        }
        .shadow(color: ballColor.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}

// MARK: - ViewModel

@MainActor
class EnhancedStatisticsViewModel: ObservableObject {
    @Published var statistics: [EnhancedNumberStatistic] = []
    @Published var isLoading = false
    @Published var analyzedRounds = 0
    @Published var totalNumbersDrawn = 0

    private let service = LottoService.shared

    // 계산된 속성들
    var hotNumbers: [EnhancedNumberStatistic] {
        let avg = averageCount
        return statistics
            .map { stat in
                var s = stat
                s.deviation = ((Double(stat.count) - avg) / avg) * 100
                s.heatLevel = min(100, max(0, s.deviation + 50))
                return s
            }
            .filter { $0.deviation > 0 }
            .sorted { $0.count > $1.count }
    }

    var coldNumbers: [EnhancedNumberStatistic] {
        let avg = averageCount
        return statistics
            .map { stat in
                var s = stat
                s.deviation = ((Double(stat.count) - avg) / avg) * 100
                return s
            }
            .filter { $0.deviation < 0 }
            .sorted { $0.count < $1.count }
    }

    var maxCount: Int {
        statistics.max(by: { $0.count < $1.count })?.count ?? 0
    }

    var averageCount: Double {
        guard !statistics.isEmpty else { return 0 }
        return Double(statistics.reduce(0) { $0 + $1.count }) / Double(statistics.count)
    }

    var rangeDistribution: [RangeDistribution] {
        let ranges = [
            (1...10, "1-10", Color(red: 251/255, green: 196/255, blue: 0/255)),
            (11...20, "11-20", Color(red: 105/255, green: 200/255, blue: 242/255)),
            (21...30, "21-30", Color(red: 255/255, green: 114/255, blue: 114/255)),
            (31...40, "31-40", Color(red: 170/255, green: 178/255, blue: 189/255)),
            (41...45, "41-45", Color(red: 176/255, green: 216/255, blue: 64/255))
        ]

        return ranges.map { range, label, color in
            let count = statistics.filter { range.contains($0.number) }.reduce(0) { $0 + $1.count }
            let percentage = totalNumbersDrawn > 0 ? Double(count) / Double(totalNumbersDrawn) * 100 : 0
            return RangeDistribution(range: label, count: count, percentage: percentage, color: color)
        }
    }

    var oddCount: Int {
        statistics.filter { $0.number % 2 == 1 }.reduce(0) { $0 + $1.count }
    }

    var evenCount: Int {
        statistics.filter { $0.number % 2 == 0 }.reduce(0) { $0 + $1.count }
    }

    var oddPercentage: Double {
        totalNumbersDrawn > 0 ? Double(oddCount) / Double(totalNumbersDrawn) * 100 : 0
    }

    var evenPercentage: Double {
        totalNumbersDrawn > 0 ? Double(evenCount) / Double(totalNumbersDrawn) * 100 : 0
    }

    func analyzeData(range: Int) async {
        isLoading = true
        var frequencyMap: [Int: Int] = [:]

        do {
            let latestRound = try await service.getLatestRound()
            let startRound = max(1, latestRound - range + 1)

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

                // API 과부하 방지
                if (round - startRound + 1) % 10 == 0 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }

            analyzedRounds = successfulFetches
            totalNumbersDrawn = frequencyMap.values.reduce(0, +)

            // 통계 계산
            let stats = (1...45).map { number in
                let count = frequencyMap[number] ?? 0
                return EnhancedNumberStatistic(
                    number: number,
                    count: count,
                    percentage: Double(count) / Double(successfulFetches * 6) * 100,
                    deviation: 0,
                    heatLevel: 0
                )
            }

            statistics = stats
        } catch {
            print("분석 중 오류: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Models

struct EnhancedNumberStatistic {
    let number: Int
    let count: Int
    let percentage: Double
    var deviation: Double = 0
    var heatLevel: Double = 0
}

struct RangeDistribution {
    let range: String
    let count: Int
    let percentage: Double
    let color: Color
}

// MARK: - Pair Card View

struct PairCard: View {
    let pair: NumberPair

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                LottoBall(number: pair.first, size: 36)
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundColor(.gray)
                LottoBall(number: pair.second, size: 36)
            }

            VStack(spacing: 2) {
                Text("\(pair.appearances)회")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("\(String(format: "%.1f", pair.frequency))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 출현 강도 표시
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            pair.appearances > 5 ? Color.red :
                            pair.appearances > 3 ? Color.orange :
                            Color.blue
                        )
                        .frame(width: geometry.size.width * min(CGFloat(pair.frequency) / 20.0, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

#Preview {
    EnhancedStatisticsView()
}