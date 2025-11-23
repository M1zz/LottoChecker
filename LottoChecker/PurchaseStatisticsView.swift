import SwiftUI

struct PurchaseStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    let purchases: [PurchaseHistory]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 전체 통계 요약
                        overallStatisticsCard

                        // 등수별 당첨 내역
                        if !rankStatistics.isEmpty {
                            rankStatisticsCard
                        }

                        // 회차별 통계
                        roundStatisticsCard

                        // 자주 선택한 번호
                        frequentNumbersCard

                        // 투자 대비 수익 차트
                        investmentReturnCard
                    }
                    .padding()
                }
            }
            .navigationTitle("상세 통계")
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

    // MARK: - View Components

    private var overallStatisticsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("전체 통계")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            StatisticRow(title: "총 구매 횟수", value: "\(purchases.count)회")
            StatisticRow(title: "총 투자 금액", value: "\(formatNumber(totalInvestment))원")
            StatisticRow(title: "총 당첨 금액", value: "\(formatNumber(totalPrize))원", valueColor: .green)
            StatisticRow(
                title: "순이익",
                value: "\(netProfit >= 0 ? "+" : "")\(formatNumber(netProfit))원",
                valueColor: netProfit >= 0 ? .green : .red
            )
            StatisticRow(
                title: "수익률",
                value: "\(String(format: "%.1f", returnRate))%",
                valueColor: returnRate >= 0 ? .green : .red
            )

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("당첨률")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", winningRate))%")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("평균 당첨금")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(formatNumber(averagePrize))원")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var rankStatisticsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("등수별 당첨 내역")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            ForEach(rankStatistics.sorted(by: { $0.key < $1.key }), id: \.key) { rank, info in
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: rank <= 3 ? "star.fill" : "star")
                            .foregroundColor(rank <= 3 ? .yellow : .gray)
                        Text("\(rank)등")
                            .fontWeight(.semibold)
                    }

                    Text("\(info.count)회")
                        .foregroundColor(.blue)

                    Spacer()

                    Text("+\(formatNumber(info.totalPrize))원")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var roundStatisticsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("회차별 통계")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("참여 회차")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(uniqueRounds)회차")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("회당 평균 구매")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f게임", averagePurchasePerRound))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            Text("최근 구매 회차")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(recentRounds.prefix(5), id: \.self) { round in
                let roundPurchases = purchases.filter { $0.round == round }
                HStack {
                    Text("\(round)회")
                        .fontWeight(.semibold)

                    Text("(\(roundPurchases.count)게임)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    let winCount = roundPurchases.filter { $0.isWinner }.count
                    if winCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(winCount)건 당첨")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var frequentNumbersCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("자주 선택한 번호 TOP 10")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(Array(mostFrequentNumbers.prefix(10).enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 5) {
                        numberBall(number: item.number, size: 40)
                        Text("\(item.count)회")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.5))
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var investmentReturnCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("투자 대비 수익")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text("투자")
                            .font(.caption)
                    }
                    Text("\(formatNumber(totalInvestment))원")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("수익")
                            .font(.caption)
                    }
                    Text("\(formatNumber(totalPrize))원")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            // 투자 대비 수익 비율 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 30)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.6))
                        .frame(width: min(CGFloat(totalPrize) / CGFloat(max(totalInvestment, 1)) * geometry.size.width, geometry.size.width), height: 30)
                }
            }
            .frame(height: 30)

            if returnRate >= 0 {
                Text("투자 대비 \(String(format: "%.1f", returnRate))% 수익")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("투자 대비 \(String(format: "%.1f", abs(returnRate)))% 손실")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Computed Properties

    private var totalInvestment: Int {
        purchases.reduce(0) { $0 + $1.cost }
    }

    private var totalPrize: Int {
        purchases.reduce(0) { $0 + ($1.prize ?? 0) }
    }

    private var netProfit: Int {
        totalPrize - totalInvestment
    }

    private var returnRate: Double {
        guard totalInvestment > 0 else { return 0 }
        return Double(netProfit) / Double(totalInvestment) * 100
    }

    private var winningRate: Double {
        guard !purchases.isEmpty else { return 0 }
        let winCount = purchases.filter { $0.isWinner }.count
        return Double(winCount) / Double(purchases.count) * 100
    }

    private var averagePrize: Int {
        guard !purchases.isEmpty else { return 0 }
        return totalPrize / purchases.count
    }

    private var rankStatistics: [Int: (count: Int, totalPrize: Int)] {
        var stats: [Int: (count: Int, totalPrize: Int)] = [:]

        for purchase in purchases {
            if let rank = purchase.rank, let prize = purchase.prize {
                let current = stats[rank] ?? (count: 0, totalPrize: 0)
                stats[rank] = (count: current.count + 1, totalPrize: current.totalPrize + prize)
            }
        }

        return stats
    }

    private var uniqueRounds: Int {
        Set(purchases.map { $0.round }).count
    }

    private var recentRounds: [Int] {
        Array(Set(purchases.map { $0.round })).sorted(by: >)
    }

    private var averagePurchasePerRound: Double {
        guard uniqueRounds > 0 else { return 0 }
        return Double(purchases.count) / Double(uniqueRounds)
    }

    private var mostFrequentNumbers: [(number: Int, count: Int)] {
        var frequency: [Int: Int] = [:]

        for purchase in purchases {
            for number in purchase.numbers {
                frequency[number, default: 0] += 1
            }
        }

        return frequency.map { (number: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Helper Functions

    private func numberBall(number: Int, size: CGFloat) -> some View {
        Circle()
            .fill(ballColor(for: number))
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

// MARK: - Supporting Views

struct StatisticRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    PurchaseStatisticsView(purchases: [])
}
