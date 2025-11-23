import SwiftUI
import AVFoundation

struct WinningCheckView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = LottoViewModel()
    @State private var userNumbers: [Int?] = Array(repeating: nil, count: 6)
    @State private var checkResult: CheckResult?
    @State private var showingNumberInput = false
    @State private var currentInputIndex = 0
    @State private var savedTickets: [LottoTicket] = []
    @State private var showingRoundPicker = false
    @State private var selectedRound: Int?
    @State private var showingPastLotteryView = false

    var body: some View {
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

                    // 과거 회차 당첨번호 확인 버튼
                    pastLotteryButton
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingNumberInput) {
            numberPickerSheet
        }
        .sheet(isPresented: $showingRoundPicker) {
            roundPickerSheet
        }
        .sheet(isPresented: $showingPastLotteryView) {
            PastLotteryLookupView()
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
        VStack(spacing: 12) {
            HStack {
                Text("회차 선택")
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
                                .font(.subheadline)
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

            if selectedRound != nil, let lotto = viewModel.lottoData {
                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(lotto.numbers, id: \.self) { number in
                            numberBall(number: number, size: 38)
                        }
                        Text("+")
                            .font(.title3)
                            .foregroundColor(.gray)
                        numberBall(number: lotto.bnusNo, size: 38, isBonus: true)
                    }

                    Text(lotto.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var numberInputCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("내 번호")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    userNumbers = Array(repeating: nil, count: 6)
                    checkResult = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("초기화")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()
                .padding(.vertical, 4)

            // 인라인 QR 스캐너
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.green)
                    Text("QR 코드 스캔")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }

                InlineQRScannerView { numbers in
                    handleScannedNumbers(numbers)
                }
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.6), lineWidth: 3)
                )

                Text("로또 용지의 QR 코드를 카메라에 맞춰주세요")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()
                .padding(.vertical, 4)

            // 수동 입력 섹션
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.blue)
                    Text("수동 입력")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }

                HStack(spacing: 8) {
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
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                                        .background(Circle().fill(Color.blue.opacity(0.05)))
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
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var checkButton: some View {
        Button {
            checkWinning()
        } label: {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                Text("당첨 확인하기")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: selectedRound != nil ?
                        [Color.blue.opacity(0.8), Color.purple.opacity(0.8)] :
                        [Color.gray.opacity(0.5), Color.gray.opacity(0.5)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: selectedRound != nil ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(selectedRound == nil)
    }

    private var pastLotteryButton: some View {
        Button {
            showingPastLotteryView = true
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("과거 회차 당첨번호 확인하기")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("원하는 회차의 당첨번호를 조회할 수 있습니다")
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.pink.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
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
                Text("저장된 번호")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(savedTickets.count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(12)

                Spacer()

                Button {
                    if selectedRound != nil {
                        checkAllSavedTickets()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("일괄확인")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(selectedRound == nil)

                Button {
                    savedTickets.removeAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text("전체삭제")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()
                .padding(.vertical, 4)

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
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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

// MARK: - Inline QR Scanner

struct InlineQRScannerView: View {
    var onScanSuccess: ([Int]) -> Void

    var body: some View {
        InlineQRScanner(onScanSuccess: { code in
            if let numbers = parseLottoQRCode(code) {
                onScanSuccess(numbers)
                AppLogger.info("인라인 QR 스캔 성공: \(numbers)", category: AppLogger.qr)
            }
        })
    }

    private func parseLottoQRCode(_ code: String) -> [Int]? {
        AppLogger.info("QR 코드 파싱 시작", category: AppLogger.qr)
        AppLogger.debug("QR 코드 내용: \(code)", category: AppLogger.qr)

        let components = code.components(separatedBy: ",")

        guard components.count >= 7 else {
            AppLogger.debug("표준 형식이 아님, 대체 파싱 시도", category: AppLogger.qr)
            let numbers = code.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
                .filter { $0 >= 1 && $0 <= 45 }

            if numbers.count >= 6 {
                let result = Array(numbers.prefix(6)).sorted()
                AppLogger.info("QR 코드 파싱 성공 (대체 형식): \(result)", category: AppLogger.qr)
                return result
            }
            AppLogger.warning("QR 코드 파싱 실패: 유효한 번호 부족", category: AppLogger.qr)
            return nil
        }

        let numbers = components.dropFirst()
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 >= 1 && $0 <= 45 }

        guard numbers.count >= 6 else {
            AppLogger.warning("QR 코드 파싱 실패: 유효한 번호가 6개 미만", category: AppLogger.qr)
            return nil
        }

        let result = Array(numbers.prefix(6)).sorted()
        AppLogger.info("QR 코드 파싱 성공: \(result)", category: AppLogger.qr)
        return result
    }
}

struct InlineQRScanner: UIViewControllerRepresentable {
    var onScanSuccess: (String) -> Void

    func makeUIViewController(context: Context) -> InlineQRScannerViewController {
        let controller = InlineQRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: InlineQRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanSuccess: onScanSuccess)
    }

    class Coordinator: NSObject, InlineQRScannerDelegate {
        var onScanSuccess: (String) -> Void

        init(onScanSuccess: @escaping (String) -> Void) {
            self.onScanSuccess = onScanSuccess
        }

        func didFindCode(_ code: String) {
            onScanSuccess(code)
        }
    }
}

protocol InlineQRScannerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class InlineQRScannerViewController: UIViewController {
    weak var delegate: InlineQRScannerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        AppLogger.info("인라인 QR 스캐너 초기화 시작", category: AppLogger.qr)

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            AppLogger.error("카메라 장치를 찾을 수 없음", category: AppLogger.qr)
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            AppLogger.error("카메라 입력 설정 실패", error: error, category: AppLogger.qr)
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            AppLogger.debug("카메라 입력 추가 성공", category: AppLogger.qr)
        } else {
            AppLogger.error("카메라 입력 추가 실패", category: AppLogger.qr)
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            AppLogger.debug("메타데이터 출력 설정 성공", category: AppLogger.qr)
        } else {
            AppLogger.error("메타데이터 출력 추가 실패", category: AppLogger.qr)
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            AppLogger.info("인라인 QR 스캐너 시작됨", category: AppLogger.qr)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
}

extension InlineQRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                AppLogger.debug("읽을 수 없는 메타데이터 객체", category: AppLogger.qr)
                return
            }
            guard let stringValue = readableObject.stringValue else {
                AppLogger.warning("QR 코드 문자열 값이 없음", category: AppLogger.qr)
                return
            }

            AppLogger.info("인라인 QR 코드 스캔 성공", category: AppLogger.qr)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            delegate?.didFindCode(stringValue)

            // 인라인 스캐너는 계속 실행 (멈추지 않음)
        }
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

// MARK: - Past Lottery Lookup View

struct PastLotteryLookupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LottoViewModel()
    @State private var inputRound = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.pink.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // 회차 입력 섹션
                        VStack(spacing: 15) {
                            Text("조회할 회차를 입력하세요")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                TextField("회차 번호", text: $inputRound)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)

                                Button {
                                    if let round = Int(inputRound), round >= 1, round <= viewModel.latestRound {
                                        Task {
                                            await viewModel.fetchLotto(round: round)
                                            showError = false
                                        }
                                    } else {
                                        showError = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                        Text("조회")
                                    }
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(inputRound.isEmpty)
                            }

                            Text("1회 ~ \(viewModel.latestRound)회")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if showError {
                                Text("올바른 회차를 입력해주세요")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                        // 결과 표시
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.top, 50)
                        } else if let lotto = viewModel.lottoData {
                            VStack(spacing: 20) {
                                // 회차 정보
                                VStack(spacing: 8) {
                                    Text("\(lotto.drwNo)회")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text(lotto.formattedDate)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top)

                                // 당첨 번호
                                VStack(spacing: 15) {
                                    Text("당첨번호")
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                    HStack(spacing: 10) {
                                        ForEach(lotto.numbers, id: \.self) { number in
                                            numberBall(number: number)
                                        }
                                    }

                                    HStack(spacing: 10) {
                                        Text("+")
                                            .font(.title2)
                                            .foregroundColor(.gray)

                                        numberBall(number: lotto.bnusNo, isBonus: true)

                                        Text("보너스")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                                // 상세 정보
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("당첨 정보")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Divider()

                                    DetailRow(title: "1등 당첨자", value: "\(lotto.firstPrzwnerCo)명")
                                    DetailRow(title: "1등 당첨금", value: "\(lotto.formattedFirstPrize)원")
                                    DetailRow(title: "총 판매금액", value: "\(lotto.formattedTotalAmount)원")
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                                // 네비게이션 버튼
                                HStack(spacing: 15) {
                                    Button {
                                        Task {
                                            await viewModel.loadPreviousRound()
                                            inputRound = "\(viewModel.currentRound)"
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text("이전")
                                        }
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(viewModel.currentRound > 1 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(viewModel.currentRound <= 1)

                                    Button {
                                        Task {
                                            await viewModel.loadNextRound()
                                            inputRound = "\(viewModel.currentRound)"
                                        }
                                    } label: {
                                        HStack {
                                            Text("다음")
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(viewModel.currentRound < viewModel.latestRound ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(viewModel.currentRound >= viewModel.latestRound)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("과거 회차 조회")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func numberBall(number: Int, isBonus: Bool = false) -> some View {
        Circle()
            .fill(isBonus ? Color.orange : ballColor(for: number))
            .frame(width: 45, height: 45)
            .overlay(
                Text("\(number)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
    }

    private func ballColor(for number: Int) -> Color {
        switch number {
        case 1...10:
            return Color(red: 0.984, green: 0.769, blue: 0.0) // #FBC400
        case 11...20:
            return Color(red: 0.412, green: 0.784, blue: 0.949) // #69C8F2
        case 21...30:
            return Color(red: 1.0, green: 0.447, blue: 0.447) // #FF7272
        case 31...40:
            return Color(red: 0.667, green: 0.698, blue: 0.741) // #AAB2BD
        default:
            return Color(red: 0.69, green: 0.847, blue: 0.251) // #B0D840
        }
    }
}

#Preview {
    WinningCheckView(selectedTab: .constant(1))
}
