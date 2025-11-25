import SwiftUI

struct RealTimeProbabilityCalculator: View {
    @StateObject private var viewModel = RealTimeCalculatorViewModel()
    @State private var selectedNumbers: Set<Int> = []
    @State private var excludedNumbers: Set<Int> = []
    @State private var showExcludeMode = false
    @State private var animateChanges = false
    @State private var showProbabilityInfo = false
    @State private var selectedRound: Int? = nil
    @State private var winningNumbers: [Int] = []
    @State private var bonusNumber: Int? = nil
    @State private var isLoadingRound = false
    @State private var showRoundInput = false
    @State private var inputRoundText = ""

    // 로또 공 색상 함수
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
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 헤더 카드
                        headerCard

                        // 회차 선택 및 당첨 번호 표시
                        roundSelectionCard

                        // 실시간 확률 표시
                        probabilityDisplayCard

                        // 번호 선택 인터페이스
                        numberSelectionCard

                        // 선택된 번호 표시
                        if !selectedNumbers.isEmpty || !excludedNumbers.isEmpty {
                            selectedNumbersCard
                        }

                        // 상세 설명
                        explanationCard
                    }
                    .padding()
                }
            }
            .navigationTitle("실시간 계산기")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProbabilityInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showProbabilityInfo) {
                ProbabilityInfoView()
            }
        }
    }

    // MARK: - View Components

    private var roundSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
                Text("회차 선택")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if isLoadingRound {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Menu {
                        Button("최신 회차") {
                            loadLatestRound()
                        }

                        if let currentRound = selectedRound {
                            Divider()

                            // 최근 10개 회차 표시
                            ForEach((max(1, currentRound - 10)..<currentRound).reversed(), id: \.self) { round in
                                Button("\(round)회") {
                                    loadSpecificRound(round)
                                }
                            }
                        }

                        Divider()

                        Button("직접 입력") {
                            showRoundInput = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedRound != nil ? "\(selectedRound!)회" : "회차 선택")
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

            if !winningNumbers.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("당첨 번호")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(winningNumbers.sorted(), id: \.self) { number in
                            ZStack {
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
                                    .shadow(color: ballColor(for: number).opacity(0.5), radius: 3, x: 0, y: 2)

                                Text("\(number)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        if let bonus = bonusNumber {
                            Image(systemName: "plus")
                                .foregroundColor(.gray)

                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                ballColor(for: bonus),
                                                ballColor(for: bonus).opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: ballColor(for: bonus).opacity(0.5), radius: 3, x: 0, y: 2)

                                Text("\(bonus)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // 선택한 번호와 당첨 번호 비교
                    if !selectedNumbers.isEmpty && !winningNumbers.isEmpty {
                        let matchCount = selectedNumbers.intersection(Set(winningNumbers)).count
                        let bonusMatch = bonusNumber != nil && selectedNumbers.contains(bonusNumber!)

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("일치: \(matchCount)개")
                                .font(.caption)
                                .fontWeight(.medium)

                            if bonusMatch {
                                Text("+ 보너스")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .onAppear {
            loadLatestRound()
        }
        .alert("회차 입력", isPresented: $showRoundInput) {
            TextField("회차 번호", text: $inputRoundText)
                .keyboardType(.numberPad)
            Button("취소", role: .cancel) {
                inputRoundText = ""
            }
            Button("확인") {
                if let round = Int(inputRoundText) {
                    loadSpecificRound(round)
                }
                inputRoundText = ""
            }
        } message: {
            Text("조회할 회차 번호를 입력하세요")
        }
    }

    private func loadLatestRound() {
        Task {
            await MainActor.run {
                isLoadingRound = true
            }

            do {
                // 최신 회차 번호 가져오기
                let latestRound = try await LottoService.shared.getLatestRound()

                // 해당 회차의 데이터 가져오기
                let lottoData = try await LottoService.shared.fetchLottoData(round: latestRound)

                await MainActor.run {
                    selectedRound = lottoData.drwNo
                    winningNumbers = lottoData.numbers
                    bonusNumber = lottoData.bnusNo
                    isLoadingRound = false

                    // 당첨 번호가 로드되면 확률 재계산
                    viewModel.updateProbabilities(
                        selected: Array(selectedNumbers),
                        excluded: Array(excludedNumbers),
                        winningNumbers: winningNumbers,
                        bonusNumber: bonusNumber
                    )
                }
            } catch {
                print("Error loading latest round: \(error)")
                // 에러 발생 시 기본값 설정
                await MainActor.run {
                    selectedRound = nil
                    winningNumbers = []
                    bonusNumber = nil
                    isLoadingRound = false
                }
            }
        }
    }

    private func loadSpecificRound(_ round: Int) {
        Task {
            await MainActor.run {
                isLoadingRound = true
            }

            do {
                // 특정 회차의 데이터 가져오기
                let lottoData = try await LottoService.shared.fetchLottoData(round: round)

                await MainActor.run {
                    selectedRound = lottoData.drwNo
                    winningNumbers = lottoData.numbers
                    bonusNumber = lottoData.bnusNo
                    isLoadingRound = false

                    // 당첨 번호가 로드되면 확률 재계산
                    viewModel.updateProbabilities(
                        selected: Array(selectedNumbers),
                        excluded: Array(excludedNumbers),
                        winningNumbers: winningNumbers,
                        bonusNumber: bonusNumber
                    )
                }
            } catch {
                print("Error loading round \(round): \(error)")
                // 에러 발생 시 알림 표시
                await MainActor.run {
                    selectedRound = nil
                    winningNumbers = []
                    bonusNumber = nil
                    isLoadingRound = false
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("번호를 선택할 때마다 당첨 확률이 어떻게 변하는지 실시간으로 확인하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("선택 번호")
                        .font(.caption)
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 12, height: 12)
                    Text("제외 번호")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var probabilityDisplayCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("현재 확률")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if !selectedNumbers.isEmpty || !excludedNumbers.isEmpty {
                    Button {
                        withAnimation {
                            selectedNumbers.removeAll()
                            excludedNumbers.removeAll()
                            viewModel.updateProbabilities(
                                selected: [],
                                excluded: [],
                                winningNumbers: winningNumbers,
                                bonusNumber: bonusNumber
                            )
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("초기화")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }

            Divider()

            // 각 등수별 확률 표시
            ForEach(1...5, id: \.self) { rank in
                ProbabilityRow(
                    rank: rank,
                    probability: viewModel.probabilities[rank] ?? 0,
                    originalProbability: viewModel.originalProbabilities[rank] ?? 0,
                    selectedCount: selectedNumbers.count,
                    animateChanges: animateChanges
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.3), value: viewModel.probabilities)
    }

    private var numberSelectionCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("번호 선택")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Toggle(isOn: $showExcludeMode) {
                    Text(showExcludeMode ? "제외 모드" : "선택 모드")
                        .font(.caption)
                        .foregroundColor(showExcludeMode ? .red : .green)
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .tint(showExcludeMode ? .red : .green)
            }

            Text(showExcludeMode ? "제외할 번호를 선택하세요" : "선택할 번호를 선택하세요 (최대 6개)")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 10) {
                ForEach(1...45, id: \.self) { number in
                    NumberButton(
                        number: number,
                        isSelected: selectedNumbers.contains(number),
                        isExcluded: excludedNumbers.contains(number),
                        isWinningNumber: winningNumbers.contains(number),
                        isBonusNumber: bonusNumber == number,
                        onTap: {
                            toggleNumber(number)
                        }
                    )
                    .disabled(
                        (!showExcludeMode && selectedNumbers.count >= 6 && !selectedNumbers.contains(number)) ||
                        (!showExcludeMode && excludedNumbers.contains(number)) ||
                        (showExcludeMode && selectedNumbers.contains(number))
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private var selectedNumbersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선택 상태")
                .font(.headline)
                .fontWeight(.semibold)

            if !selectedNumbers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("선택한 번호 (\(selectedNumbers.count)/6)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if !winningNumbers.isEmpty {
                            let matchCount = selectedNumbers.intersection(Set(winningNumbers)).count
                            if matchCount > 0 {
                                Text("일치: \(matchCount)개")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(selectedNumbers.sorted(), id: \.self) { number in
                            let isMatched = winningNumbers.contains(number)
                            let isBonus = bonusNumber == number

                            ZStack {
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
                                    .frame(width: 40, height: 40)
                                    .shadow(color: ballColor(for: number).opacity(0.5), radius: 3, x: 0, y: 2)

                                // 일치 표시 링
                                if isMatched || isBonus {
                                    Circle()
                                        .stroke(isBonus ? Color.orange : Color.yellow, lineWidth: 3)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: isBonus ? Color.orange : Color.yellow, radius: 4, x: 0, y: 0)
                                }

                                Text("\(number)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                // 일치 표시 아이콘
                                if isMatched || isBonus {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(isBonus ? .orange : .yellow)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                        .offset(x: 14, y: -14)
                                }
                            }
                            .scaleEffect(isMatched || isBonus ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: isMatched)
                        }
                    }
                }
            }

            if !excludedNumbers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("제외한 번호 (\(excludedNumbers.count)개)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if !winningNumbers.isEmpty {
                            let excludedWinning = excludedNumbers.intersection(Set(winningNumbers)).count
                            let excludedBonus = bonusNumber != nil && excludedNumbers.contains(bonusNumber!)

                            if excludedWinning > 0 || excludedBonus {
                                Text("당첨번호 제외: \(excludedWinning + (excludedBonus ? 1 : 0))개")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(excludedNumbers.sorted(), id: \.self) { number in
                                let isWinning = winningNumbers.contains(number)
                                let isBonus = bonusNumber == number

                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.8))
                                        .frame(width: 35, height: 35)

                                    if isWinning || isBonus {
                                        Circle()
                                            .stroke(isBonus ? Color.orange : Color.yellow, lineWidth: 2)
                                            .frame(width: 35, height: 35)
                                    }

                                    Text("\(number)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)

                                    // 당첨 번호 제외 표시
                                    if isWinning || isBonus {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.yellow)
                                            .offset(x: 12, y: -12)
                                    }
                                }
                                .scaleEffect(isWinning || isBonus ? 1.1 : 1.0)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .transition(.scale.combined(with: .opacity))
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text("계산 방법")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 10) {
                ExplanationRow(
                    icon: "1.circle",
                    text: "선택한 번호가 많을수록 1-3등 확률은 감소합니다"
                )
                ExplanationRow(
                    icon: "2.circle",
                    text: "선택한 번호가 많을수록 4-5등 확률은 증가합니다"
                )
                ExplanationRow(
                    icon: "3.circle",
                    text: "제외한 번호가 많을수록 모든 확률이 증가합니다"
                )
                ExplanationRow(
                    icon: "4.circle",
                    text: "6개를 모두 선택하면 그 번호의 당첨 확률만 계산됩니다"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    // MARK: - Helper Functions

    private func toggleNumber(_ number: Int) {
        withAnimation(.spring(response: 0.3)) {
            animateChanges = true

            if showExcludeMode {
                if excludedNumbers.contains(number) {
                    excludedNumbers.remove(number)
                } else if !selectedNumbers.contains(number) {
                    excludedNumbers.insert(number)
                }
            } else {
                if selectedNumbers.contains(number) {
                    selectedNumbers.remove(number)
                } else if selectedNumbers.count < 6 && !excludedNumbers.contains(number) {
                    selectedNumbers.insert(number)
                }
            }

            // 확률 업데이트 - 당첨 번호 정보 포함
            viewModel.updateProbabilities(
                selected: Array(selectedNumbers),
                excluded: Array(excludedNumbers),
                winningNumbers: winningNumbers,
                bonusNumber: bonusNumber
            )

            // 애니메이션 플래그 리셋
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateChanges = false
            }
        }
    }
}

// MARK: - Supporting Views

struct NumberButton: View {
    let number: Int
    let isSelected: Bool
    let isExcluded: Bool
    let isWinningNumber: Bool
    let isBonusNumber: Bool
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
                    // 선택된 번호 - 진한 색상
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
                        .frame(width: 38, height: 38)
                        .shadow(color: ballColor(for: number).opacity(0.5), radius: 2, x: 0, y: 1)
                } else if isExcluded {
                    // 제외된 번호
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                        )
                } else if isWinningNumber || isBonusNumber {
                    // 당첨 번호 또는 보너스 번호 - 연한 배경색
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    ballColor(for: number).opacity(0.3),
                                    ballColor(for: number).opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(isBonusNumber ? Color.orange : ballColor(for: number).opacity(0.5), lineWidth: isBonusNumber ? 2 : 1.5)
                        )
                } else {
                    // 일반 번호
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.gray.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(ballColor(for: number).opacity(0.3), lineWidth: 1)
                        )
                }

                Text("\(number)")
                    .font(.system(size: 14, weight: isWinningNumber || isBonusNumber ? .bold : .semibold))
                    .foregroundColor(isSelected || isExcluded ? .white : (isWinningNumber || isBonusNumber ? ballColor(for: number) : .primary))
            }
        }
        .scaleEffect(isSelected || isExcluded ? 1.15 : (isWinningNumber || isBonusNumber ? 1.05 : 1.0))
        .animation(.spring(response: 0.3), value: isSelected)
        .animation(.spring(response: 0.3), value: isExcluded)
        .animation(.spring(response: 0.3), value: isWinningNumber)
    }
}

struct ProbabilityRow: View {
    let rank: Int
    let probability: Double
    let originalProbability: Double
    let selectedCount: Int
    let animateChanges: Bool

    private var changePercentage: Double {
        guard originalProbability > 0 else { return 0 }
        return ((probability - originalProbability) / originalProbability) * 100
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        case 4: return .purple
        case 5: return .blue
        default: return .gray
        }
    }

    private var probabilityText: String {
        if probability == 0 {
            return "불가능"
        } else if probability < 0.0000001 {
            return String(format: "%.10f%%", probability * 100)
        } else if probability < 0.000001 {
            return String(format: "%.8f%%", probability * 100)
        } else if probability < 0.0001 {
            return String(format: "%.6f%%", probability * 100)
        } else if probability < 0.01 {
            return String(format: "%.4f%%", probability * 100)
        } else {
            return String(format: "%.2f%%", probability * 100)
        }
    }

    private var denominatorText: String {
        guard probability > 0 else { return "-" }
        let denominator = Int(1.0 / probability)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "1 / \(formatter.string(from: NSNumber(value: denominator)) ?? "\(denominator)")"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: rank <= 3 ? "star.fill" : "star")
                        .foregroundColor(rank <= 3 ? rankColor : .gray)
                    Text("\(rank)등")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(probabilityText)
                        .font(.headline)
                        .foregroundColor(rankColor)
                        .animation(.none, value: probability)

                    Text(denominatorText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // 변화율 표시
            if changePercentage != 0 && (selectedCount > 0 || animateChanges) {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: changePercentage > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(String(format: "%.1f%%", abs(changePercentage)))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(changePercentage > 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(changePercentage > 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(rankColor.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(rankColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ExplanationRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - ViewModel

@MainActor
class RealTimeCalculatorViewModel: ObservableObject {
    @Published var probabilities: [Int: Double] = [:]
    @Published var originalProbabilities: [Int: Double] = [:]

    init() {
        calculateOriginalProbabilities()
        probabilities = originalProbabilities
    }

    private func calculateOriginalProbabilities() {
        // 조합 계산 함수
        func combination(_ n: Int, _ r: Int) -> Double {
            guard r <= n, r >= 0 else { return 0 }
            if r == 0 || r == n { return 1 }

            var result: Double = 1
            for i in 0..<r {
                result *= Double(n - i)
                result /= Double(i + 1)
            }
            return result
        }

        let totalCombinations = combination(45, 6)

        // 원래 확률 계산
        originalProbabilities[1] = 1.0 / totalCombinations // 1등: 6개 모두
        originalProbabilities[2] = 6.0 / totalCombinations // 2등: 5개 + 보너스
        originalProbabilities[3] = (combination(6, 5) * combination(38, 1)) / totalCombinations // 3등: 5개
        originalProbabilities[4] = (combination(6, 4) * combination(39, 2)) / totalCombinations // 4등: 4개
        originalProbabilities[5] = (combination(6, 3) * combination(39, 3)) / totalCombinations // 5등: 3개
    }

    func updateProbabilities(selected: [Int], excluded: [Int], winningNumbers: [Int] = [], bonusNumber: Int? = nil) {
        guard selected.count <= 6 else { return }

        // 조합 계산 함수
        func combination(_ n: Int, _ r: Int) -> Double {
            guard r <= n, r >= 0 else { return 0 }
            if r == 0 || r == n { return 1 }

            var result: Double = 1
            for i in 0..<r {
                result *= Double(n - i)
                result /= Double(i + 1)
            }
            return result
        }

        // 당첨 번호가 있는 경우 - 선택한 번호와 비교
        if !winningNumbers.isEmpty && !selected.isEmpty {
            let selectedSet = Set(selected)
            let winningSet = Set(winningNumbers)
            let matchCount = selectedSet.intersection(winningSet).count
            let bonusMatch = bonusNumber != nil && selectedSet.contains(bonusNumber!)

            let selectedCount = selected.count
            let remainingSlots = 6 - selectedCount

            // 남은 번호들 중에서 추가로 맞춰야 할 개수 계산
            let remainingWinningNumbers = 6 - matchCount
            let remainingNonWinningNumbers = 39 - (selectedCount - matchCount)

            if remainingSlots == 0 {
                // 6개 모두 선택한 경우 - 실제 매칭 결과만
                if matchCount == 6 {
                    probabilities[1] = 1.0
                    probabilities[2] = 0
                    probabilities[3] = 0
                    probabilities[4] = 0
                    probabilities[5] = 0
                } else if matchCount == 5 && bonusMatch {
                    probabilities[1] = 0
                    probabilities[2] = 1.0
                    probabilities[3] = 0
                    probabilities[4] = 0
                    probabilities[5] = 0
                } else if matchCount == 5 {
                    probabilities[1] = 0
                    probabilities[2] = 0
                    probabilities[3] = 1.0
                    probabilities[4] = 0
                    probabilities[5] = 0
                } else if matchCount == 4 {
                    probabilities[1] = 0
                    probabilities[2] = 0
                    probabilities[3] = 0
                    probabilities[4] = 1.0
                    probabilities[5] = 0
                } else if matchCount == 3 {
                    probabilities[1] = 0
                    probabilities[2] = 0
                    probabilities[3] = 0
                    probabilities[4] = 0
                    probabilities[5] = 1.0
                } else {
                    probabilities[1] = 0
                    probabilities[2] = 0
                    probabilities[3] = 0
                    probabilities[4] = 0
                    probabilities[5] = 0
                }
            } else {
                // 부분 선택한 경우 - 남은 슬롯에서 추가로 맞춰야 할 확률 계산
                let totalRemainingCombinations = combination(39, remainingSlots)

                // 1등: 이미 맞춘 개수 + 추가로 맞춰야 할 개수 = 6
                let need1st = 6 - matchCount
                if need1st <= remainingSlots && need1st >= 0 && remainingWinningNumbers >= need1st {
                    probabilities[1] = combination(remainingWinningNumbers, need1st) * combination(remainingNonWinningNumbers, remainingSlots - need1st) / totalRemainingCombinations
                } else {
                    probabilities[1] = 0
                }

                // 2등: 5개 맞추고 보너스
                let need2nd = 5 - matchCount
                if need2nd <= remainingSlots && need2nd >= 0 && remainingWinningNumbers >= need2nd {
                    if bonusMatch {
                        // 이미 보너스를 선택한 경우
                        probabilities[2] = combination(remainingWinningNumbers, need2nd) * combination(remainingNonWinningNumbers - 1, remainingSlots - need2nd) / totalRemainingCombinations
                    } else if bonusNumber != nil && !Set(excluded).contains(bonusNumber!) {
                        // 보너스를 아직 선택하지 않은 경우
                        probabilities[2] = combination(remainingWinningNumbers, need2nd) * combination(remainingNonWinningNumbers - 1, remainingSlots - need2nd - 1) / totalRemainingCombinations
                    } else {
                        probabilities[2] = 0
                    }
                } else {
                    probabilities[2] = 0
                }

                // 3등: 5개 맞춤 (보너스 제외)
                let need3rd = 5 - matchCount
                if need3rd <= remainingSlots && need3rd >= 0 && remainingWinningNumbers >= need3rd {
                    if bonusMatch {
                        // 보너스를 선택했지만 5개만 맞추는 경우는 없음
                        probabilities[3] = 0
                    } else {
                        probabilities[3] = combination(remainingWinningNumbers, need3rd) * combination(remainingNonWinningNumbers - 1, remainingSlots - need3rd) / totalRemainingCombinations
                    }
                } else {
                    probabilities[3] = 0
                }

                // 4등: 4개 맞춤
                let need4th = 4 - matchCount
                if need4th <= remainingSlots && need4th >= 0 && remainingWinningNumbers >= need4th {
                    probabilities[4] = combination(remainingWinningNumbers, need4th) * combination(remainingNonWinningNumbers, remainingSlots - need4th) / totalRemainingCombinations
                } else {
                    probabilities[4] = 0
                }

                // 5등: 3개 맞춤
                let need5th = 3 - matchCount
                if need5th <= remainingSlots && need5th >= 0 && remainingWinningNumbers >= need5th {
                    probabilities[5] = combination(remainingWinningNumbers, need5th) * combination(remainingNonWinningNumbers, remainingSlots - need5th) / totalRemainingCombinations
                } else {
                    probabilities[5] = 0
                }
            }
        } else {
            // 당첨 번호가 없는 경우 - 기존 로직
            let availableNumbers = 45 - selected.count - excluded.count
            let selectedCount = selected.count
            let remainingSlots = 6 - selectedCount

            guard availableNumbers >= remainingSlots else {
                probabilities = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
                return
            }

            if selectedCount == 0 {
                probabilities = originalProbabilities
            } else {
                let totalCombinations = combination(45, 6)

                // 각 등수별 확률 계산 (선택한 번호가 모두 맞는다고 가정)
                probabilities[1] = combination(6 - selectedCount, 6 - selectedCount) * combination(39, 0) / combination(39, remainingSlots)
                probabilities[2] = combination(6 - selectedCount, 5 - selectedCount) * 1 * combination(38, remainingSlots - (5 - selectedCount) - 1) / combination(39, remainingSlots) * 6.0 / totalCombinations
                probabilities[3] = combination(6 - selectedCount, 5 - selectedCount) * combination(38, remainingSlots - (5 - selectedCount)) / combination(39, remainingSlots) * combination(6, 5) * combination(38, 1) / totalCombinations
                probabilities[4] = combination(6 - selectedCount, max(0, 4 - selectedCount)) * combination(39, remainingSlots - max(0, 4 - selectedCount)) / combination(39, remainingSlots) * combination(6, 4) * combination(39, 2) / totalCombinations
                probabilities[5] = combination(6 - selectedCount, max(0, 3 - selectedCount)) * combination(39, remainingSlots - max(0, 3 - selectedCount)) / combination(39, remainingSlots) * combination(6, 3) * combination(39, 3) / totalCombinations
            }
        }
    }
}

// MARK: - Probability Info View

struct ProbabilityInfoView: View {
    @Environment(\.dismiss) private var dismiss

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
                        ForEach(probabilityInfoItems) { item in
                            probabilityCard(item: item)
                        }

                        // 기대값 설명 카드
                        expectedValueExplanationCard
                    }
                    .padding()
                }
            }
            .navigationTitle("확률 정보")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }

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

    private func probabilityCard(item: ProbabilityInfoItem) -> some View {
        VStack(alignment: .leading, spacing: 15) {
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

            VStack(spacing: 12) {
                HStack {
                    Text("당첨 확률")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1 / \(formatNumber(item.denominator))")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

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
                ProbabilityInfoRow(
                    icon: "1.circle.fill",
                    text: "확률이 0.01(1%)이라면, 평균적으로 100번 시도해야 1번 당첨됩니다."
                )

                ProbabilityInfoRow(
                    icon: "2.circle.fill",
                    text: "하지만 이것은 평균값입니다. 실제로는 더 적게 또는 더 많이 시도해야 할 수 있습니다."
                )

                ProbabilityInfoRow(
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

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private var probabilityInfoItems: [ProbabilityInfoItem] {
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

        let totalCombinations = combination(45, 6)

        let rank1Cases = 1
        let rank1Probability = Double(rank1Cases) / Double(totalCombinations)

        let rank2Cases = combination(6, 5) * combination(39, 0) * 1
        let rank2Probability = Double(rank2Cases) / Double(totalCombinations)

        let rank3Cases = combination(6, 5) * combination(38, 1)
        let rank3Probability = Double(rank3Cases) / Double(totalCombinations)

        let rank4Cases = combination(6, 4) * combination(39, 2)
        let rank4Probability = Double(rank4Cases) / Double(totalCombinations)

        let rank5Cases = combination(6, 3) * combination(39, 3)
        let rank5Probability = Double(rank5Cases) / Double(totalCombinations)

        return [
            ProbabilityInfoItem(
                title: "1등 당첨",
                subtitle: "6개 번호 모두 일치",
                icon: "crown.fill",
                color: .yellow,
                denominator: totalCombinations,
                probability: rank1Probability,
                expectedTrials: totalCombinations,
                explanation: "약 814만번 구매해야 1번 당첨될 확률입니다."
            ),
            ProbabilityInfoItem(
                title: "2등 당첨",
                subtitle: "5개 번호 + 보너스 번호 일치",
                icon: "star.fill",
                color: .orange,
                denominator: totalCombinations / rank2Cases,
                probability: rank2Probability,
                expectedTrials: totalCombinations / rank2Cases,
                explanation: "약 136만번 구매해야 1번 당첨될 확률입니다."
            ),
            ProbabilityInfoItem(
                title: "3등 당첨",
                subtitle: "5개 번호 일치",
                icon: "star.circle.fill",
                color: .red,
                denominator: totalCombinations / rank3Cases,
                probability: rank3Probability,
                expectedTrials: totalCombinations / rank3Cases,
                explanation: "약 3만 5천번 구매해야 1번 당첨될 확률입니다."
            ),
            ProbabilityInfoItem(
                title: "4등 당첨",
                subtitle: "4개 번호 일치",
                icon: "gift.fill",
                color: .purple,
                denominator: totalCombinations / rank4Cases,
                probability: rank4Probability,
                expectedTrials: totalCombinations / rank4Cases,
                explanation: "약 733번 구매하면 1번 당첨될 확률입니다."
            ),
            ProbabilityInfoItem(
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

struct ProbabilityInfoRow: View {
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

struct ProbabilityInfoItem: Identifiable {
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

#Preview {
    RealTimeProbabilityCalculator()
}
