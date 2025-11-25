import SwiftUI

struct ConditionalProbabilityView: View {
    @StateObject private var viewModel = ConditionalProbabilityViewModel()
    @State private var selectedNumbers: Set<Int> = []
    @State private var excludedNumbers: Set<Int> = []
    @State private var selectedRound: Int?
    @State private var showingRoundPicker = false
    @State private var currentMode: SelectionMode = .selected

    enum SelectionMode: String, CaseIterable {
        case selected = "확정 번호"
        case excluded = "제외 번호"

        var color: Color {
            switch self {
            case .selected: return .green
            case .excluded: return .red
            }
        }

        var description: String {
            switch self {
            case .selected: return "반드시 포함될 번호"
            case .excluded: return "절대 나오지 않을 번호"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 설명 카드
                        introCard

                        // 회차 선택
                        roundSelectionCard

                        // 번호 선택 모드
                        modeSelectionCard

                        // 번호 선택 그리드
                        numberSelectionCard

                        // 선택된 번호 요약
                        if !selectedNumbers.isEmpty || !excludedNumbers.isEmpty {
                            selectionSummaryCard
                        }

                        // 계산 버튼
                        if selectedRound != nil {
                            calculateButton
                        }

                        // 확률 결과
                        if !viewModel.probabilityResults.isEmpty {
                            resultsCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("조건부 확률")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingRoundPicker) {
                roundPickerSheet
            }
            .task {
                if selectedRound == nil && viewModel.latestRound > 0 {
                    selectedRound = viewModel.latestRound
                    await viewModel.loadRound(round: viewModel.latestRound)
                }
            }
        }
    }

    // MARK: - View Components

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("조건부 확률이란?")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("특정 번호가 확정되거나 제외될 때의 당첨 확률을 계산합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .padding(.top, 2)
                    Text("확정 번호: 반드시 당첨 번호에 포함")
                        .font(.caption)
                }
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .padding(.top, 2)
                    Text("제외 번호: 절대 당첨 번호에 포함되지 않음")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var roundSelectionCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("분석할 회차")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingRoundPicker = true
                } label: {
                    HStack(spacing: 6) {
                        if let round = selectedRound {
                            Text("\(round)회")
                                .font(.headline)
                                .fontWeight(.bold)
                        } else {
                            Text("선택하기")
                                .font(.caption)
                        }
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title3)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
            }

            if let round = selectedRound, let lotto = viewModel.lottoData {
                Divider()

                VStack(spacing: 8) {
                    Text("당첨번호")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        ForEach(lotto.numbers.sorted(), id: \.self) { number in
                            numberBall(number: number, size: 30)
                        }
                        Text("+")
                            .foregroundColor(.gray)
                        numberBall(number: lotto.bnusNo, size: 30, isBonus: true)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var modeSelectionCard: some View {
        VStack(spacing: 12) {
            Text("번호 선택 모드")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Selection Mode", selection: $currentMode) {
                ForEach(SelectionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Circle()
                    .fill(currentMode.color)
                    .frame(width: 8, height: 8)
                Text(currentMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var numberSelectionCard: some View {
        VStack(spacing: 15) {
            Text("번호를 선택하세요")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 10) {
                ForEach(1...45, id: \.self) { number in
                    Button {
                        toggleNumber(number)
                    } label: {
                        ZStack {
                            if selectedNumbers.contains(number) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 38, height: 38)
                            } else if excludedNumbers.contains(number) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 38, height: 38)
                            } else {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(Circle().fill(Color.white))
                                    .frame(width: 38, height: 38)
                            }

                            Text("\(number)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(
                                    selectedNumbers.contains(number) || excludedNumbers.contains(number)
                                    ? .white : .primary
                                )
                        }
                    }
                    .disabled(
                        (currentMode == .selected && excludedNumbers.contains(number)) ||
                        (currentMode == .excluded && selectedNumbers.contains(number))
                    )
                }
            }

            if selectedNumbers.count >= 6 && currentMode == .selected {
                Text("최대 6개까지만 확정 번호를 선택할 수 있습니다")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var selectionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선택 요약")
                .font(.headline)
                .fontWeight(.semibold)

            if !selectedNumbers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("확정 번호 (\(selectedNumbers.count)개)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 6) {
                        ForEach(selectedNumbers.sorted(), id: \.self) { number in
                            numberBall(number: number, size: 35, color: .green)
                        }
                    }
                }
            }

            if !excludedNumbers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("제외 번호 (\(excludedNumbers.count)개)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 6) {
                        ForEach(Array(excludedNumbers.sorted().prefix(10)), id: \.self) { number in
                            numberBall(number: number, size: 35, color: .red)
                        }
                        if excludedNumbers.count > 10 {
                            Text("+\(excludedNumbers.count - 10)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Button {
                selectedNumbers.removeAll()
                excludedNumbers.removeAll()
                viewModel.probabilityResults.removeAll()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("초기화")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var calculateButton: some View {
        Button {
            if let round = selectedRound {
                viewModel.calculateConditionalProbability(
                    selectedNumbers: Array(selectedNumbers),
                    excludedNumbers: Array(excludedNumbers),
                    round: round
                )
            }
        } label: {
            HStack {
                Image(systemName: "function")
                    .font(.title3)
                Text("조건부 확률 계산")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("계산 결과")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Divider()

            ForEach(viewModel.probabilityResults) { result in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: result.rank <= 3 ? "star.fill" : "star")
                                .foregroundColor(result.rank <= 3 ? .yellow : .gray)
                            Text("\(result.rank)등")
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(result.probabilityText)
                                .font(.headline)
                                .foregroundColor(result.color)
                            Text("1 / \(formatNumber(result.denominator))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 설명
                    Text(result.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 변화율
                    if result.changeFromNormal != 0 {
                        HStack {
                            Image(systemName: result.changeFromNormal > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(result.changeFromNormal > 0 ? .green : .red)
                            Text(String(format: "%.1f%% %@", abs(result.changeFromNormal), result.changeFromNormal > 0 ? "증가" : "감소"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(result.changeFromNormal > 0 ? .green : .red)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var roundPickerSheet: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("분석할 회차를 선택하세요")
                    .font(.headline)
                    .padding(.top)

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

                Spacer()

                Button {
                    if let round = selectedRound, round >= 1 && round <= viewModel.latestRound {
                        Task {
                            await viewModel.loadRound(round: round)
                            showingRoundPicker = false
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
            .padding()
            .navigationTitle("회차 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showingRoundPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func toggleNumber(_ number: Int) {
        switch currentMode {
        case .selected:
            if selectedNumbers.contains(number) {
                selectedNumbers.remove(number)
            } else if selectedNumbers.count < 6 && !excludedNumbers.contains(number) {
                selectedNumbers.insert(number)
            }
        case .excluded:
            if excludedNumbers.contains(number) {
                excludedNumbers.remove(number)
            } else if !selectedNumbers.contains(number) {
                excludedNumbers.insert(number)
            }
        }

        // 결과 초기화
        viewModel.probabilityResults.removeAll()
    }

    private func numberBall(number: Int, size: CGFloat = 45, isBonus: Bool = false, color: Color? = nil) -> some View {
        Circle()
            .fill(color ?? (isBonus ? Color.orange : ballColor(for: number)))
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
        case 1...10: return Color(red: 0.984, green: 0.769, blue: 0.0)
        case 11...20: return Color(red: 0.412, green: 0.784, blue: 0.949)
        case 21...30: return Color(red: 1.0, green: 0.447, blue: 0.447)
        case 31...40: return Color(red: 0.667, green: 0.698, blue: 0.741)
        default: return Color(red: 0.69, green: 0.847, blue: 0.251)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Models

struct ConditionalProbabilityResult: Identifiable {
    let id = UUID()
    let rank: Int
    let probability: Double
    let denominator: Int
    let description: String
    let changeFromNormal: Double // 일반 확률 대비 변화율 (%)

    var probabilityText: String {
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

    var color: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        case 4: return .purple
        case 5: return .blue
        default: return .gray
        }
    }
}

// MARK: - ViewModel

@MainActor
class ConditionalProbabilityViewModel: ObservableObject {
    @Published var probabilityResults: [ConditionalProbabilityResult] = []
    @Published var lottoData: LottoResponse?
    @Published var latestRound = 1
    @Published var isLoading = false

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

    func calculateConditionalProbability(selectedNumbers: [Int], excludedNumbers: [Int], round: Int) {
        guard let lotto = lottoData else { return }

        let winningSet = Set(lotto.numbers)
        let bonusNumber = lotto.bnusNo

        // 조합 계산 함수
        func combination(_ n: Int, _ r: Int) -> Int {
            guard r <= n, r >= 0 else { return 0 }
            if r == 0 || r == n { return 1 }

            var result = 1
            for i in 0..<r {
                result *= (n - i)
                result /= (i + 1)
            }
            return result
        }

        // 사용 가능한 번호 개수
        let availableNumbers = 45 - selectedNumbers.count - excludedNumbers.count
        let selectedCount = selectedNumbers.count
        let selectedMatchCount = selectedNumbers.filter { winningSet.contains($0) }.count
        let bonusInSelected = selectedNumbers.contains(bonusNumber)
        let bonusExcluded = excludedNumbers.contains(bonusNumber)

        var results: [ConditionalProbabilityResult] = []

        // 1등: 6개 모두 맞춤
        if selectedCount <= 6 {
            let needMore = 6 - selectedMatchCount
            if needMore >= 0 && needMore <= (6 - selectedCount) {
                let remainingWinning = winningSet.subtracting(selectedNumbers).count
                let remainingChoices = availableNumbers

                let cases = combination(remainingWinning, needMore) * combination(remainingChoices - remainingWinning, (6 - selectedCount) - needMore)
                let totalCases = combination(availableNumbers, 6 - selectedCount)

                if totalCases > 0 && cases > 0 {
                    let probability = Double(cases) / Double(totalCases)
                    let normalProbability = 1.0 / Double(combination(45, 6))
                    let change = ((probability - normalProbability) / normalProbability) * 100

                    results.append(ConditionalProbabilityResult(
                        rank: 1,
                        probability: probability,
                        denominator: totalCases / cases,
                        description: "선택한 번호 중 \(selectedMatchCount)개가 당첨번호와 일치",
                        changeFromNormal: change
                    ))
                }
            }
        }

        // 2등: 5개 맞추고 보너스 맞춤
        if selectedCount <= 6 && !bonusExcluded {
            let need5Match = 5 - selectedMatchCount
            if need5Match >= 0 && need5Match <= (6 - selectedCount) {
                let remainingWinning = winningSet.subtracting(selectedNumbers).count
                let mustSelectBonus = !bonusInSelected

                if mustSelectBonus {
                    // 보너스를 선택해야 하는 경우
                    let cases = combination(remainingWinning, need5Match) * 1
                    let totalCases = combination(availableNumbers, 6 - selectedCount)

                    if totalCases > 0 && cases > 0 {
                        let probability = Double(cases) / Double(totalCases)
                        let normalProbability = Double(combination(6, 5)) / Double(combination(45, 6))
                        let change = ((probability - normalProbability) / normalProbability) * 100

                        results.append(ConditionalProbabilityResult(
                            rank: 2,
                            probability: probability,
                            denominator: totalCases / cases,
                            description: "5개 번호 + 보너스 번호 일치",
                            changeFromNormal: change
                        ))
                    }
                }
            }
        }

        // 3등: 5개 맞춤 (보너스 X)
        if selectedCount <= 6 {
            let need5Match = 5 - selectedMatchCount
            if need5Match >= 0 && need5Match <= (6 - selectedCount) {
                let remainingWinning = winningSet.subtracting(selectedNumbers).count
                let nonWinningCount = availableNumbers - remainingWinning - (bonusExcluded ? 0 : 1)

                let cases = combination(remainingWinning, need5Match) * combination(nonWinningCount, (6 - selectedCount) - need5Match)
                let totalCases = combination(availableNumbers, 6 - selectedCount)

                if totalCases > 0 && cases > 0 {
                    let probability = Double(cases) / Double(totalCases)
                    let normalProbability = Double(combination(6, 5) * combination(38, 1)) / Double(combination(45, 6))
                    let change = ((probability - normalProbability) / normalProbability) * 100

                    results.append(ConditionalProbabilityResult(
                        rank: 3,
                        probability: probability,
                        denominator: totalCases / cases,
                        description: "5개 번호 일치 (보너스 제외)",
                        changeFromNormal: change
                    ))
                }
            }
        }

        // 4등과 5등도 유사하게 계산...

        probabilityResults = results.sorted(by: { $0.rank < $1.rank })
    }
}

#Preview {
    ConditionalProbabilityView()
}