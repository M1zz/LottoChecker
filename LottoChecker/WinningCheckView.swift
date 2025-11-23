import SwiftUI

struct WinningCheckView: View {
    @StateObject private var viewModel = LottoViewModel()
    @State private var userNumbers: [Int?] = Array(repeating: nil, count: 6)
    @State private var checkResult: CheckResult?
    @State private var showingNumberInput = false
    @State private var currentInputIndex = 0
    @State private var savedTickets: [LottoTicket] = []
    @State private var showingRoundPicker = false
    @State private var selectedRound: Int?
    @State private var showingQRScanner = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 회차 선택
                        roundSelectionCard

                        // 번호 입력
                        numberInputCard

                        // 확인 버튼
                        if allNumbersEntered {
                            checkButton
                        }

                        // 당첨 결과
                        if let result = checkResult {
                            resultCard(result: result)
                        }

                        // 저장된 번호들
                        if !savedTickets.isEmpty {
                            savedTicketsCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("당첨 확인")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingNumberInput) {
                numberPickerSheet
            }
            .sheet(isPresented: $showingRoundPicker) {
                roundPickerSheet
            }
            .fullScreenCover(isPresented: $showingQRScanner) {
                QRCodeScannerView(isPresented: $showingQRScanner) { numbers in
                    handleScannedNumbers(numbers)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var allNumbersEntered: Bool {
        userNumbers.allSatisfy { $0 != nil }
    }

    private var validNumbers: [Int] {
        userNumbers.compactMap { $0 }.sorted()
    }

    // MARK: - View Components

    private var roundSelectionCard: some View {
        VStack(spacing: 15) {
            Text("회차 선택")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            HStack {
                if let round = selectedRound {
                    Text("\(round)회")
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("회차를 선택하세요")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingRoundPicker = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
            }

            if selectedRound != nil, let lotto = viewModel.lottoData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("당첨 번호")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(lotto.numbers, id: \.self) { number in
                            numberBall(number: number, size: 35)
                        }
                        Text("+")
                            .foregroundColor(.gray)
                        numberBall(number: lotto.bnusNo, size: 35, isBonus: true)
                    }

                    Text(lotto.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var numberInputCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("내 번호")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    userNumbers = Array(repeating: nil, count: 6)
                    checkResult = nil
                } label: {
                    Text("초기화")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()

            // QR 스캔 버튼 (메인)
            Button {
                showingQRScanner = true
            } label: {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QR 코드 스캔")
                            .font(.headline)
                        Text("로또 용지의 QR 코드를 스캔하세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
            }
            .buttonStyle(.plain)

            // 수동 입력 섹션
            VStack(spacing: 10) {
                Text("또는 수동으로 입력")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    ForEach(0..<6) { index in
                        Button {
                            currentInputIndex = index
                            showingNumberInput = true
                        } label: {
                            ZStack {
                                if let number = userNumbers[index] {
                                    numberBall(number: number, size: 50)
                                } else {
                                    Circle()
                                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                                        .background(Circle().fill(Color.white.opacity(0.5)))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                        }
                    }
                }
            }

            if allNumbersEntered {
                Button {
                    savedTickets.append(LottoTicket(numbers: validNumbers))
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("이 번호 저장")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var checkButton: some View {
        Button {
            checkWinning()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("당첨 확인하기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedRound != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .disabled(selectedRound == nil)
    }

    private func resultCard(result: CheckResult) -> some View {
        VStack(spacing: 20) {
            // 결과 아이콘과 텍스트
            if let rank = result.rank {
                VStack(spacing: 10) {
                    Image(systemName: rank <= 3 ? "star.fill" : "star")
                        .font(.system(size: 60))
                        .foregroundColor(rank == 1 ? .yellow : rank <= 3 ? .orange : .blue)

                    Text("\(rank)등 당첨!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(rank <= 3 ? .orange : .blue)

                    if let prize = result.estimatedPrize {
                        Text("예상 당첨금")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(formatNumber(prize))원")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("낙첨")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    Text("아쉽지만 다음 기회에!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // 일치 정보
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("일치 번호")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(result.matchedCount)개")
                        .foregroundColor(.blue)
                }

                if !result.matchedNumbers.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(result.matchedNumbers.sorted(), id: \.self) { number in
                            numberBall(number: number, size: 35)
                        }
                    }
                }

                if result.bonusMatched {
                    HStack {
                        Text("보너스 번호")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("일치")
                            .foregroundColor(.orange)
                    }
                }

                if !result.unmatchedNumbers.isEmpty {
                    Divider()
                    Text("불일치 번호")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(result.unmatchedNumbers.sorted(), id: \.self) { number in
                            numberBall(number: number, size: 35)
                                .opacity(0.4)
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

    private var savedTicketsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("저장된 번호 (\(savedTickets.count))")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    if selectedRound != nil {
                        checkAllSavedTickets()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("일괄 확인")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(selectedRound == nil)

                Button {
                    savedTickets.removeAll()
                } label: {
                    Text("전체 삭제")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()

            ForEach(Array(savedTickets.enumerated()), id: \.offset) { index, ticket in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            ForEach(ticket.numbers, id: \.self) { number in
                                numberBall(number: number, size: 35)
                            }
                        }

                        Spacer()

                        if let result = ticket.checkResult {
                            if let rank = result.rank {
                                Text("\(rank)등")
                                    .font(.headline)
                                    .foregroundColor(rank <= 3 ? .orange : .blue)
                            } else {
                                Text("낙첨")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Button {
                            userNumbers = ticket.numbers.map { $0 as Int? }
                            checkResult = nil
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            savedTickets.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 5)

                if index < savedTickets.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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

    private var roundPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("확인할 회차를 선택하세요")
                    .font(.headline)
                    .padding(.top)

                Stepper(value: Binding(
                    get: { selectedRound ?? viewModel.latestRound },
                    set: { selectedRound = $0 }
                ), in: 1...viewModel.latestRound) {
                    Text("\(selectedRound ?? viewModel.latestRound)회")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding()

                Button {
                    if let round = selectedRound {
                        Task {
                            await viewModel.fetchLotto(round: round)
                            showingRoundPicker = false
                            checkResult = nil
                        }
                    }
                } label: {
                    Text("선택")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding()

                Spacer()
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

    private func checkWinning() {
        guard let lotto = viewModel.lottoData else { return }

        let winningNumbers = Set(lotto.numbers)
        let userNumbersSet = Set(validNumbers)

        let matched = winningNumbers.intersection(userNumbersSet)
        let unmatched = userNumbersSet.subtracting(winningNumbers)
        let bonusMatched = userNumbersSet.contains(lotto.bnusNo)

        let matchCount = matched.count

        var rank: Int?
        var estimatedPrize: Int?

        switch matchCount {
        case 6:
            rank = 1
            estimatedPrize = Int(lotto.firstWinamnt)
        case 5:
            if bonusMatched {
                rank = 2
                estimatedPrize = Int(lotto.firstWinamnt) / 6
            } else {
                rank = 3
                estimatedPrize = Int(lotto.firstWinamnt) / 100
            }
        case 4:
            rank = 4
            estimatedPrize = 50_000
        case 3:
            rank = 5
            estimatedPrize = 5_000
        default:
            break
        }

        checkResult = CheckResult(
            rank: rank,
            matchedCount: matchCount,
            bonusMatched: bonusMatched && matchCount == 5,
            matchedNumbers: Array(matched),
            unmatchedNumbers: Array(unmatched),
            estimatedPrize: estimatedPrize
        )
    }

    private func checkAllSavedTickets() {
        guard let lotto = viewModel.lottoData else { return }

        for index in savedTickets.indices {
            let ticket = savedTickets[index]
            let winningNumbers = Set(lotto.numbers)
            let userNumbersSet = Set(ticket.numbers)

            let matched = winningNumbers.intersection(userNumbersSet)
            let unmatched = userNumbersSet.subtracting(winningNumbers)
            let bonusMatched = userNumbersSet.contains(lotto.bnusNo)

            let matchCount = matched.count

            var rank: Int?
            var estimatedPrize: Int?

            switch matchCount {
            case 6:
                rank = 1
                estimatedPrize = Int(lotto.firstWinamnt)
            case 5:
                if bonusMatched {
                    rank = 2
                    estimatedPrize = Int(lotto.firstWinamnt) / 6
                } else {
                    rank = 3
                    estimatedPrize = Int(lotto.firstWinamnt) / 100
                }
            case 4:
                rank = 4
                estimatedPrize = 50_000
            case 3:
                rank = 5
                estimatedPrize = 5_000
            default:
                break
            }

            savedTickets[index].checkResult = CheckResult(
                rank: rank,
                matchedCount: matchCount,
                bonusMatched: bonusMatched && matchCount == 5,
                matchedNumbers: Array(matched),
                unmatchedNumbers: Array(unmatched),
                estimatedPrize: estimatedPrize
            )
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func handleScannedNumbers(_ numbers: [Int]) {
        // QR 스캔으로 받은 번호들을 userNumbers에 설정
        for (index, number) in numbers.enumerated() {
            if index < 6 {
                userNumbers[index] = number
            }
        }
        // 결과 초기화
        checkResult = nil
    }
}

// MARK: - Models

struct CheckResult {
    let rank: Int?
    let matchedCount: Int
    let bonusMatched: Bool
    let matchedNumbers: [Int]
    let unmatchedNumbers: [Int]
    let estimatedPrize: Int?
}

struct LottoTicket: Identifiable {
    let id = UUID()
    let numbers: [Int]
    var checkResult: CheckResult?
}

#Preview {
    WinningCheckView()
}
