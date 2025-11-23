import Foundation

@MainActor
class LottoViewModel: ObservableObject {
    @Published var lottoData: LottoResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentRound: Int = 1
    @Published var latestRound: Int = 1
    
    private let service = LottoService.shared
    
    init() {
        Task {
            await loadLatestRound()
        }
    }
    
    func loadLatestRound() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let latest = try await service.getLatestRound()
            latestRound = latest
            currentRound = latest
            await fetchLotto(round: latest)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func fetchLotto(round: Int) async {
        guard round > 0 else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await service.fetchLottoData(round: round)
            lottoData = data
            currentRound = round
        } catch {
            errorMessage = error.localizedDescription
            lottoData = nil
        }
        
        isLoading = false
    }
    
    func loadPreviousRound() async {
        guard currentRound > 1 else { return }
        await fetchLotto(round: currentRound - 1)
    }
    
    func loadNextRound() async {
        guard currentRound < latestRound else { return }
        await fetchLotto(round: currentRound + 1)
    }
}
