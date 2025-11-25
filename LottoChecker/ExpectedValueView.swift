import SwiftUI

struct ExpectedValueView: View {
    @StateObject private var viewModel = SimulationViewModel()
    @State private var simulationCount: Int = 5
    @State private var selectedRound: Int?
    @State private var showingRoundPicker = false
    @State private var simulationResult: SimulationResult?
    @State private var showingResultDetail = false
    @State private var numberInputMethod: String = "자동"
    @State private var userNumbers: [Int?] = Array(repeating: nil, count: 6)
    @State private var showingNumberInput = false
    @State private var currentInputIndex = 0
    @State private var generatedNumbers: [[Int]] = []
    @State private var showGeneratedNumbers = true

    // 화면 크기에 따른 레이아웃 조정
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var numberOfGames: Int {
        simulationCount
    }

    var allNumbersEntered: Bool {
        userNumbers.allSatisfy { $0 != nil }
    }

    // 화면 크기별 설정
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var ballSize: CGFloat {
        isCompact ? 28 : 35
    }

    var cardPadding: CGFloat {
        isCompact ? 15 : 20
    }

    var spacing: CGFloat {
        isCompact ? 20 : 25
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.pink.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("확률 계산 중...")
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: spacing) {
                            // 회차 선택
                            roundSelectionCard

                            // 구매 금액 설정
                            purchaseInputCard

                            // 번호 입력 방식 선택
                            if selectedRound != nil {
                                numberMethodCard
                            }

                            // 수동 입력 UI
                            if selectedRound != nil && numberInputMethod == "수동" {
                                manualNumberInputCard
                            }

                            // 시뮬레이션 버튼
                            if selectedRound != nil && (numberInputMethod == "자동" || (numberInputMethod == "수동" && allNumbersEntered)) {
                                simulationButton
                            }

                            // 시뮬레이션 결과
                            if let result = simulationResult {
                                resultSummaryCard(result: result)
                                detailedResultCard(result: result)
                            }
                        }
                        .padding(cardPadding)
                    }
                }
            }
            .navigationTitle("당첨 시뮬레이션")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingRoundPicker) {
                roundPickerSheet
            }
            .sheet(isPresented: $showingNumberInput) {
                numberPickerSheet
            }
            .task {
                // 최신 회차를 기본값으로 설정하고 자동 로드
                if selectedRound == nil && viewModel.latestRound > 0 {
                    selectedRound = viewModel.latestRound
                    await viewModel.loadRound(round: viewModel.latestRound)
                }
            }
            .onAppear {
                // 자동 모드인 경우 번호 미리 생성
                if numberInputMethod == "자동" && generatedNumbers.isEmpty {
                    generateNumbers()
                }
            }
        }
    }

    // MARK: - View Components

    private var roundSelectionCard: some View {
        VStack(spacing: isCompact ? 12 : 15) {
            HStack {
                Text("확률 계산할 회차")
                    .font(isCompact ? .subheadline : .headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingRoundPicker = true
                } label: {
                    HStack(spacing: 6) {
                        if let round = selectedRound {
                            Text("\(round)회")
                                .font(isCompact ? .subheadline : .headline)
                                .fontWeight(.bold)
                        } else {
                            Text("선택하기")
                                .font(.caption)
                        }
                        Image(systemName: "chevron.down.circle.fill")
                            .font(isCompact ? .body : .title3)
                    }
                    .padding(.horizontal, isCompact ? 10 : 12)
                    .padding(.vertical, isCompact ? 6 : 8)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
            }

            if let round = selectedRound, let lotto = viewModel.lottoData {
                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 8) {
                    Text(lotto.formattedDate)
                        .font(isCompact ? .caption : .subheadline)
                        .foregroundColor(.secondary)

                    Text("확률 계산 준비 완료")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(cardPadding)
        .background(Color.white.opacity(0.8))
        .cornerRadius(isCompact ? 12 : 16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var purchaseInputCard: some View {
        VStack(spacing: isCompact ? 12 : 15) {
            Text("가상 상황 설정")
                .font(isCompact ? .headline : .title3)
                .fontWeight(.semibold)

            Divider()

            VStack(spacing: isCompact ? 12 : 15) {
                HStack {
                    Text("시뮬레이션 횟수")
                        .font(isCompact ? .subheadline : .body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(simulationCount)회")
                        .font(isCompact ? .headline : .title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Slider(value: Binding(
                    get: { Double(simulationCount) },
                    set: { newValue in
                        simulationCount = Int(newValue)
                        // 횟수가 변경되면 자동 생성 번호 다시 생성
                        if numberInputMethod == "자동" {
                            generateNumbers()
                        }
                    }
                ), in: 1...100, step: 1)
                .accentColor(.blue)

                HStack {
                    Text("1회")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("100회")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(isCompact ? .body : .title3)
                    .foregroundColor(.orange)
                Text("총 비용: \(formatNumber(numberOfGames * 1000))원")
                    .font(isCompact ? .subheadline : .body)
                    .fontWeight(.semibold)
                Spacer()
                Text("(회당 1,000원)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(isCompact ? 10 : 12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(cardPadding)
        .background(Color.white.opacity(0.8))
        .cornerRadius(isCompact ? 12 : 16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var numberMethodCard: some View {
        VStack(spacing: isCompact ? 12 : 15) {
            Text("번호 생성 방식")
                .font(isCompact ? .subheadline : .headline)
                .fontWeight(.semibold)

            Divider()
                .padding(.vertical, 4)

            Picker("번호 생성 방식", selection: $numberInputMethod) {
                Text("자동").tag("자동")
                Text("수동").tag("수동")
            }
            .pickerStyle(.segmented)
            .onChange(of: numberInputMethod) { _, newValue in
                // 방식 변경 시 초기화
                userNumbers = Array(repeating: nil, count: 6)
                simulationResult = nil

                // 자동으로 변경 시 번호 생성
                if newValue == "자동" {
                    generateNumbers()
                }
            }

            HStack {
                Image(systemName: numberInputMethod == "자동" ? "dice.fill" : "hand.tap.fill")
                    .foregroundColor(numberInputMethod == "자동" ? .green : .blue)
                Text(numberInputMethod == "자동" ? "매번 다른 랜덤 번호 생성" : "동일한 번호로 확률 계산")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background((numberInputMethod == "자동" ? Color.green : Color.blue).opacity(0.1))
            .cornerRadius(10)

            // 자동 생성 번호 표시
            if numberInputMethod == "자동" && !generatedNumbers.isEmpty {
                VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
                    HStack {
                        Text("생성된 번호 (\(generatedNumbers.count)개)")
                            .font(isCompact ? .caption : .subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Button {
                            withAnimation {
                                showGeneratedNumbers.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showGeneratedNumbers ? "eye.slash.fill" : "eye.fill")
                                Text(showGeneratedNumbers ? "가리기" : "보기")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        }
                    }

                    if showGeneratedNumbers {
                        VStack(spacing: isCompact ? 6 : 8) {
                            ForEach(Array(generatedNumbers.enumerated()), id: \.offset) { index, numbers in
                                HStack(spacing: isCompact ? 4 : 6) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: isCompact ? 20 : 25)

                                    ForEach(numbers, id: \.self) { number in
                                        numberBall(number: number, size: ballSize)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(isCompact ? 10 : 12)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(isCompact ? 10 : 12)
            }
        }
        .padding(cardPadding)
        .background(Color.white.opacity(0.8))
        .cornerRadius(isCompact ? 12 : 16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var manualNumberInputCard: some View {
        VStack(spacing: isCompact ? 12 : 15) {
            HStack {
                Text("번호 입력")
                    .font(isCompact ? .subheadline : .headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    userNumbers = Array(repeating: nil, count: 6)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("초기화")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()
                .padding(.vertical, 4)

            HStack(spacing: isCompact ? 6 : 8) {
                ForEach(0..<6) { index in
                    Button {
                        currentInputIndex = index
                        showingNumberInput = true
                    } label: {
                        ZStack {
                            let manualBallSize: CGFloat = isCompact ? 40 : 50
                            if let number = userNumbers[index] {
                                numberBall(number: number, size: manualBallSize)
                            } else {
                                Circle()
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                                    .background(Circle().fill(Color.blue.opacity(0.05)))
                                    .frame(width: manualBallSize, height: manualBallSize)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(isCompact ? .caption2 : .caption)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    }
                }
            }

            if !allNumbersEntered {
                Text("6개의 번호를 모두 입력해주세요")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("번호 입력 완료")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(cardPadding)
        .background(Color.white.opacity(0.8))
        .cornerRadius(isCompact ? 12 : 16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var simulationButton: some View {
        Button {
            runSimulation()
        } label: {
            HStack(spacing: isCompact ? 6 : 8) {
                Image(systemName: "function")
                    .font(isCompact ? .body : .title3)
                Text("확률 계산 시작")
                    .font(isCompact ? .body : .headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(isCompact ? 14 : 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(isCompact ? 12 : 15)
        }
    }

    private func resultSummaryCard(result: SimulationResult) -> some View {
        VStack(spacing: isCompact ? 15 : 20) {
            // 메인 결과
            VStack(spacing: isCompact ? 8 : 10) {
                Text(result.profit >= 0 ? "수익 발생!" : "손실 발생")
                    .font(isCompact ? .title3 : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(result.profit >= 0 ? .green : .red)

                Text("\(result.profit >= 0 ? "+" : "")\(formatNumber(result.profit))원")
                    .font(.system(size: isCompact ? 36 : 48, weight: .bold))
                    .foregroundColor(result.profit >= 0 ? .green : .red)

                Text("수익률 \(String(format: "%.1f", result.returnRate))%")
                    .font(isCompact ? .headline : .title3)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 통계 요약
            HStack(spacing: isCompact ? 12 : 20) {
                VStack(spacing: isCompact ? 4 : 6) {
                    Text("투자금")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(formatNumber(result.investment))원")
                        .font(isCompact ? .subheadline : .headline)
                }

                Divider()
                    .frame(height: isCompact ? 30 : 40)

                VStack(spacing: isCompact ? 4 : 6) {
                    Text("당첨금")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(formatNumber(result.totalPrize))원")
                        .font(isCompact ? .subheadline : .headline)
                        .foregroundColor(.green)
                }

                Divider()
                    .frame(height: isCompact ? 30 : 40)

                VStack(spacing: isCompact ? 4 : 6) {
                    Text("당첨 횟수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.winningGames)/\(result.totalGames)")
                        .font(isCompact ? .subheadline : .headline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(cardPadding)
        .background(Color.white.opacity(0.7))
        .cornerRadius(isCompact ? 16 : 20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private func detailedResultCard(result: SimulationResult) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 15) {
            HStack {
                Text("당첨 내역")
                    .font(isCompact ? .headline : .title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showingResultDetail.toggle()
                } label: {
                    Image(systemName: showingResultDetail ? "chevron.up" : "chevron.down")
                        .font(isCompact ? .body : .title3)
                }
            }

            Divider()

            // 등수별 당첨 통계
            if !result.rankStatistics.isEmpty {
                ForEach(result.rankStatistics.sorted(by: { $0.key < $1.key }), id: \.key) { rank, count in
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: rank <= 3 ? "star.fill" : "star")
                                .foregroundColor(rank <= 3 ? .yellow : .gray)
                            Text("\(rank)등")
                                .fontWeight(.semibold)
                        }

                        Text("\(count)개")
                            .foregroundColor(.blue)

                        Spacer()

                        if let prize = result.prizeByRank[rank] {
                            Text("+\(formatNumber(prize))원")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 5)
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.gray)
                    Text("당첨된 회차가 없습니다")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            }

            // 상세 결과
            if showingResultDetail {
                Divider()

                Text("전체 시뮬레이션 결과")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(Array(result.gameResults.enumerated()), id: \.offset) { index, game in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(index + 1)번째")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            if let rank = game.rank {
                                Text("\(rank)등 (\(formatNumber(game.prize))원)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(rank <= 3 ? .orange : .blue)
                            } else {
                                Text("낙첨")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack(spacing: 6) {
                            ForEach(game.numbers, id: \.self) { number in
                                let isMatched = game.matchedNumbers.contains(number)
                                numberBall(number: number, size: 28)
                                    .opacity(isMatched ? 1.0 : 0.4)
                                    .overlay(
                                        isMatched ?
                                        Circle()
                                            .strokeBorder(Color.green, lineWidth: 2)
                                            .frame(width: ballSize, height: ballSize) : nil
                                    )
                            }
                        }
                    }
                    .padding(isCompact ? 10 : 12)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding(cardPadding)
        .background(Color.white.opacity(0.7))
        .cornerRadius(isCompact ? 16 : 20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var roundPickerSheet: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("확률 계산할 회차를 입력하세요")
                    .font(.headline)
                    .padding(.top)

                // 회차 직접 입력
                VStack(spacing: 15) {
                    TextField("회차 번호", value: Binding(
                        get: { selectedRound ?? viewModel.latestRound },
                        set: { selectedRound = $0 }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)

                    Text("1회 ~ \(viewModel.latestRound)회")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

                // 빠른 선택 버튼
                VStack(spacing: 12) {
                    Text("빠른 선택")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        QuickSelectButton(title: "최신", round: viewModel.latestRound) {
                            selectedRound = viewModel.latestRound
                        }

                        QuickSelectButton(title: "10회 전", round: max(1, viewModel.latestRound - 10)) {
                            selectedRound = max(1, viewModel.latestRound - 10)
                        }

                        QuickSelectButton(title: "50회 전", round: max(1, viewModel.latestRound - 50)) {
                            selectedRound = max(1, viewModel.latestRound - 50)
                        }

                        QuickSelectButton(title: "100회 전", round: max(1, viewModel.latestRound - 100)) {
                            selectedRound = max(1, viewModel.latestRound - 100)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // 확인 버튼
                Button {
                    if let round = selectedRound, round >= 1 && round <= viewModel.latestRound {
                        Task {
                            await viewModel.loadRound(round: round)
                            showingRoundPicker = false
                            simulationResult = nil
                        }
                    }
                } label: {
                    Text("확인")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (selectedRound ?? 0) >= 1 && (selectedRound ?? 0) <= viewModel.latestRound ?
                            Color.blue : Color.gray
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding()
                .disabled((selectedRound ?? 0) < 1 || (selectedRound ?? 0) > viewModel.latestRound)
            }
            .navigationTitle("회차 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showingRoundPicker = false
                    }
                }
            }
            .task {
                if selectedRound == nil {
                    selectedRound = viewModel.latestRound
                    Task {
                        await viewModel.loadRound(round: viewModel.latestRound)
                    }
                }
            }
        }
    }

    private var numberPickerSheet: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 15) {
                    ForEach(1...45, id: \.self) { number in
                        let isSelected = userNumbers.contains(number)
                        let isDisabled = isSelected && userNumbers[currentInputIndex] != number

                        Button {
                            userNumbers[currentInputIndex] = number
                            showingNumberInput = false
                        } label: {
                            Text("\(number)")
                                .font(.headline)
                                .frame(width: 50, height: 50)
                                .background(
                                    isDisabled ? Color.gray.opacity(0.3) :
                                    isSelected ? Color.green :
                                    Color.blue.opacity(0.1)
                                )
                                .foregroundColor(isSelected ? .white : .primary)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .disabled(isDisabled)
                    }
                }
                .padding()
            }
            .navigationTitle("\(currentInputIndex + 1)번째 번호 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        showingNumberInput = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func numberBall(number: Int, size: CGFloat = 45, isBonus: Bool = false) -> some View {
        Circle()
            .fill(isBonus ? Color.orange : ballColor(for: number))
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

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // 번호 생성 함수
    private func generateNumbers() {
        generatedNumbers = []
        for _ in 0..<simulationCount {
            let numbers = Array(1...45).shuffled().prefix(6).sorted()
            generatedNumbers.append(Array(numbers))
        }
    }

    private func runSimulation() {
        guard let lotto = viewModel.lottoData else { return }

        viewModel.isLoading = true

        // 백그라운드에서 시뮬레이션 실행
        DispatchQueue.global(qos: .userInitiated).async {
            var gameResults: [GameResult] = []
            var rankStats: [Int: Int] = [:]
            var prizeByRank: [Int: Int] = [:]
            var totalPrize = 0
            var winningCount = 0

            // 수동 입력 번호 (수동 모드인 경우)
            let manualNumbers = numberInputMethod == "수동" ? userNumbers.compactMap { $0 }.sorted() : []

            // 각 회차 시뮬레이션
            for index in 0..<numberOfGames {
                let numbers: [Int]
                if numberInputMethod == "자동" {
                    // 미리 생성된 번호 사용
                    numbers = index < generatedNumbers.count ? generatedNumbers[index] : generateRandomNumbers()
                } else {
                    numbers = manualNumbers
                }

                let result = checkGame(numbers: numbers, lotto: lotto)
                gameResults.append(result)

                if let rank = result.rank {
                    rankStats[rank, default: 0] += 1
                    prizeByRank[rank, default: 0] += result.prize
                    totalPrize += result.prize
                    winningCount += 1
                }
            }

            let investment = numberOfGames * 1000
            let profit = totalPrize - investment
            let returnRate = Double(profit) / Double(investment) * 100

            let result = SimulationResult(
                investment: investment,
                totalPrize: totalPrize,
                profit: profit,
                returnRate: returnRate,
                totalGames: numberOfGames,
                winningGames: winningCount,
                rankStatistics: rankStats,
                prizeByRank: prizeByRank,
                gameResults: gameResults
            )

            DispatchQueue.main.async {
                simulationResult = result
                viewModel.isLoading = false
            }
        }
    }

    private func generateRandomNumbers() -> [Int] {
        Array(1...45).shuffled().prefix(6).sorted()
    }

    private func checkGame(numbers: [Int], lotto: LottoResponse) -> GameResult {
        let winningNumbers = Set(lotto.numbers)
        let userNumbers = Set(numbers)

        let matched = winningNumbers.intersection(userNumbers)
        let matchCount = matched.count
        let bonusMatched = userNumbers.contains(lotto.bnusNo)

        var rank: Int?
        var prize = 0

        switch matchCount {
        case 6:
            rank = 1
            prize = Int(lotto.firstWinamnt)
        case 5:
            if bonusMatched {
                rank = 2
                prize = Int(lotto.firstWinamnt) / 6
            } else {
                rank = 3
                prize = Int(lotto.firstWinamnt) / 100
            }
        case 4:
            rank = 4
            prize = 50_000
        case 3:
            rank = 5
            prize = 5_000
        default:
            break
        }

        return GameResult(
            numbers: numbers,
            matchedNumbers: Array(matched),
            rank: rank,
            prize: prize
        )
    }
}

// MARK: - Models

struct SimulationResult {
    let investment: Int
    let totalPrize: Int
    let profit: Int
    let returnRate: Double
    let totalGames: Int
    let winningGames: Int
    let rankStatistics: [Int: Int]
    let prizeByRank: [Int: Int]
    let gameResults: [GameResult]
}

struct GameResult {
    let numbers: [Int]
    let matchedNumbers: [Int]
    let rank: Int?
    let prize: Int
}

// MARK: - ViewModel

@MainActor
class SimulationViewModel: ObservableObject {
    @Published var lottoData: LottoResponse?
    @Published var isLoading = false
    @Published var latestRound = 1

    private let service = LottoService.shared

    init() {
        Task {
            await loadLatestRound()
        }
    }

    func loadLatestRound() async {
        do {
            let latest = try await service.getLatestRound()
            latestRound = latest
        } catch {
            print("최신 회차 로딩 실패: \(error)")
        }
    }

    func loadRound(round: Int) async {
        isLoading = true
        do {
            let data = try await service.fetchLottoData(round: round)
            lottoData = data
        } catch {
            print("회차 로딩 실패: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Quick Select Button Component
struct QuickSelectButton: View {
    let title: String
    let round: Int
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(round)회")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
        }
    }
}

#Preview {
    ExpectedValueView()
}
