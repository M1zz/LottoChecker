import Foundation

@MainActor
class LottoViewModel: ObservableObject {
    @Published var lottoData: LottoResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorSuggestion: String?
    @Published var currentRound: Int = 1
    @Published var latestRound: Int = 1

    private let service = LottoService.shared
    
    init() {
        AppLogger.info("LottoViewModel 초기화", category: AppLogger.viewModel)
        Task {
            await loadLatestRound()
        }
    }

    func loadLatestRound() async {
        AppLogger.debug("최신 회차 로드 시작", category: AppLogger.viewModel)
        isLoading = true
        errorMessage = nil
        errorSuggestion = nil

        do {
            let latest = try await service.getLatestRound()
            latestRound = latest
            currentRound = latest
            AppLogger.info("최신 회차 설정: \(latest)회", category: AppLogger.viewModel)
            await fetchLotto(round: latest)
        } catch {
            AppLogger.error("최신 회차 로드 실패", error: error, category: AppLogger.viewModel)
            handleError(error)
            isLoading = false
        }
    }

    func fetchLotto(round: Int) async {
        guard round > 0 else {
            AppLogger.warning("유효하지 않은 회차: \(round)", category: AppLogger.viewModel)
            return
        }

        AppLogger.debug("로또 데이터 가져오기: \(round)회", category: AppLogger.viewModel)
        isLoading = true
        errorMessage = nil
        errorSuggestion = nil

        do {
            let data = try await service.fetchLottoData(round: round)
            lottoData = data
            currentRound = round
            AppLogger.info("로또 \(round)회 데이터 로드 완료", category: AppLogger.viewModel)
        } catch {
            AppLogger.error("로또 \(round)회 데이터 로드 실패", error: error, category: AppLogger.viewModel)
            handleError(error)
            lottoData = nil
        }

        isLoading = false
    }

    private func handleError(_ error: Error) {
        if let lottoError = error as? LottoError {
            errorMessage = lottoError.errorDescription
            errorSuggestion = lottoError.recoverySuggestion
        } else {
            errorMessage = error.localizedDescription
            errorSuggestion = "문제가 지속되면 앱을 재시작해주세요."
        }
    }

    func loadPreviousRound() async {
        guard currentRound > 1 else {
            AppLogger.debug("이전 회차 없음 (현재: 1회)", category: AppLogger.viewModel)
            return
        }
        AppLogger.debug("이전 회차로 이동: \(currentRound - 1)회", category: AppLogger.viewModel)
        await fetchLotto(round: currentRound - 1)
    }

    func loadNextRound() async {
        guard currentRound < latestRound else {
            AppLogger.debug("다음 회차 없음 (현재: \(currentRound)회, 최신: \(latestRound)회)", category: AppLogger.viewModel)
            return
        }
        AppLogger.debug("다음 회차로 이동: \(currentRound + 1)회", category: AppLogger.viewModel)
        await fetchLotto(round: currentRound + 1)
    }
}
