import SwiftUI
import SwiftData

struct PurchaseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PurchaseHistory.purchaseDate, order: .reverse) private var purchases: [PurchaseHistory]
    @State private var showingAddSheet = false
    @State private var showingStatistics = false
    @State private var selectedRound: Int?

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.indigo.opacity(0.1), Color.cyan.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if purchases.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 통계 요약 카드
                            statisticsSummaryCard

                            // 구매 내역 목록
                            purchaseListSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("구매 히스토리")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("수동 입력", systemImage: "pencil")
                        }

                        Button {
                            showingStatistics = true
                        } label: {
                            Label("상세 통계", systemImage: "chart.bar.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPurchaseView()
            }
            .sheet(isPresented: $showingStatistics) {
                PurchaseStatisticsView(purchases: purchases)
            }
        }
    }

    // MARK: - View Components

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            Text("구매 내역이 없습니다")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("QR 코드를 스캔하거나\n수동으로 번호를 입력하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 15) {
                Button {
                    showingAddSheet = true
                } label: {
                    VStack {
                        Image(systemName: "pencil.circle")
                            .font(.largeTitle)
                        Text("수동 입력")
                            .font(.caption)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                }
            }
        }
    }

    private var statisticsSummaryCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("요약 통계")
                    .font(.headline)
                Spacer()
                Button {
                    showingStatistics = true
                } label: {
                    HStack(spacing: 4) {
                        Text("상세보기")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
            }

            Divider()

            HStack(spacing: 20) {
                StatBox(title: "총 구매", value: "\(purchases.count)회", color: .blue)
                StatBox(title: "총 투자", value: "\(formatNumber(totalInvestment))원", color: .orange)
                StatBox(title: "당첨", value: "\(winningCount)회", color: .green)
            }

            if totalPrize > 0 {
                Divider()
                HStack {
                    Text("총 당첨금")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatNumber(totalPrize))원")
                        .font(.headline)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("수익률")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1f", returnRate))%")
                        .font(.headline)
                        .foregroundColor(returnRate >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var purchaseListSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("구매 내역 (\(purchases.count))")
                    .font(.headline)
                Spacer()
                if !purchases.isEmpty {
                    Button {
                        checkAllPurchases()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                            Text("전체 확인")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            ForEach(groupedPurchases.sorted(by: { $0.key > $1.key }), id: \.key) { round, items in
                RoundSection(round: round, purchases: items, modelContext: modelContext)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Computed Properties

    private var groupedPurchases: [Int: [PurchaseHistory]] {
        Dictionary(grouping: purchases) { $0.round }
    }

    private var totalInvestment: Int {
        purchases.reduce(0) { $0 + $1.cost }
    }

    private var totalPrize: Int {
        purchases.reduce(0) { $0 + ($1.prize ?? 0) }
    }

    private var winningCount: Int {
        purchases.filter { $0.isWinner }.count
    }

    private var returnRate: Double {
        guard totalInvestment > 0 else { return 0 }
        return Double(totalPrize - totalInvestment) / Double(totalInvestment) * 100
    }

    // MARK: - Helper Functions

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func checkAllPurchases() {
        Task {
            let service = LottoService.shared

            for purchase in purchases where !purchase.isChecked {
                do {
                    let lotto = try await service.fetchLottoData(round: purchase.round)

                    let winningNumbers = Set(lotto.numbers)
                    let userNumbers = Set(purchase.numbers)

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

                    await MainActor.run {
                        purchase.updateResult(
                            matchCount: matchCount,
                            hasBonus: bonusMatched && matchCount == 5,
                            rank: rank,
                            prize: prize
                        )
                    }
                } catch {
                    print("회차 \(purchase.round) 확인 실패: \(error)")
                }

                // API 과부하 방지를 위한 딜레이
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2초
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RoundSection: View {
    let round: Int
    let purchases: [PurchaseHistory]
    let modelContext: ModelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(round)회")
                .font(.headline)
                .foregroundColor(.blue)

            ForEach(purchases) { purchase in
                PurchaseItemRow(purchase: purchase, modelContext: modelContext)
            }
        }
        .padding(.vertical, 5)
    }
}

struct PurchaseItemRow: View {
    let purchase: PurchaseHistory
    let modelContext: ModelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    ForEach(purchase.numbers, id: \.self) { number in
                        numberBall(number: number, size: 30)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if purchase.isChecked {
                        if let rank = purchase.rank {
                            Text("\(rank)등")
                                .font(.headline)
                                .foregroundColor(rank <= 3 ? .orange : .blue)
                            if let prize = purchase.prize, prize > 0 {
                                Text("+\(formatNumber(prize))원")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("낙첨")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("미확인")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Button {
                    deletePurchase()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }

            HStack {
                Text(purchase.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text(purchase.purchaseMethod)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }

    private func numberBall(number: Int, size: CGFloat) -> some View {
        Circle()
            .fill(ballColor(for: number))
            .frame(width: size, height: size)
            .overlay(
                Text("\(number)")
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
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

    private func deletePurchase() {
        modelContext.delete(purchase)
    }
}

#Preview {
    PurchaseHistoryView()
        .modelContainer(for: PurchaseHistory.self, inMemory: true)
}
