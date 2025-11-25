import SwiftUI

struct SavedCombinationsView: View {
    @ObservedObject var viewModel: ProbabilityAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCombination: RecommendedCombination?
    @State private var showingCheckResult = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.05), Color.yellow.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.savedCombinations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            // 통계 카드
                            statisticsCard

                            // 저장된 조합들
                            ForEach(viewModel.savedCombinations) { combination in
                                SavedCombinationCard(
                                    combination: combination,
                                    onCheck: {
                                        selectedCombination = combination
                                        showingCheckResult = true
                                    },
                                    onDelete: {
                                        viewModel.removeSavedCombination(combination)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("저장된 조합")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCheckResult) {
                if let combination = selectedCombination {
                    CombinationCheckView(combination: combination)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("저장된 조합이 없습니다")
                .font(.title3)
                .foregroundColor(.gray)

            Text("추천 조합에서 마음에 드는\n번호를 저장해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Label("조합 추천 보기", systemImage: "arrow.left")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
    }

    private var statisticsCard: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.orange)
                Text("저장된 조합 통계")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(viewModel.savedCombinations.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("총 조합")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    let avgScore = viewModel.savedCombinations.reduce(0.0) { $0 + $1.score } / Double(max(1, viewModel.savedCombinations.count))
                    Text("\(Int(avgScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("평균 점수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    let types = Set(viewModel.savedCombinations.map { $0.type })
                    Text("\(types.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("조합 유형")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // 유형별 분포
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RecommendedCombination.CombinationType.allCases, id: \.self) { type in
                        let count = viewModel.savedCombinations.filter { $0.type == type }.count
                        if count > 0 {
                            TypeBadge(type: type, count: count)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10)
    }
}

// Supporting Views
struct SavedCombinationCard: View {
    let combination: RecommendedCombination
    let onCheck: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(combination.type.rawValue, systemImage: "star.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(combination.type.color)

                    Text(combination.createdDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onCheck()
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                    }

                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach(combination.numbers, id: \.self) { number in
                    LottoBall(number: number, size: 38)
                }
            }

            Text(combination.reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Label("점수: \(Int(combination.score))/100", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)

                Spacer()

                // 점수에 따른 등급 표시
                ScoreGrade(score: combination.score)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .alert("삭제 확인", isPresented: $showingDeleteConfirmation) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 조합을 삭제하시겠습니까?")
        }
    }
}

struct TypeBadge: View {
    let type: RecommendedCombination.CombinationType
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(type.color)
                .frame(width: 8, height: 8)
            Text(type.rawValue)
                .font(.caption)
            Text("(\(count))")
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ScoreGrade: View {
    let score: Double

    var gradeInfo: (text: String, color: Color) {
        switch score {
        case 80...100:
            return ("S등급", .red)
        case 60..<80:
            return ("A등급", .orange)
        case 40..<60:
            return ("B등급", .yellow)
        case 20..<40:
            return ("C등급", .green)
        default:
            return ("D등급", .gray)
        }
    }

    var body: some View {
        Text(gradeInfo.text)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(gradeInfo.color.opacity(0.2))
            .foregroundColor(gradeInfo.color)
            .cornerRadius(8)
    }
}

struct CombinationCheckView: View {
    let combination: RecommendedCombination
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRound = ""
    @State private var checkResult: CheckResult?
    @State private var isChecking = false

    struct CheckResult {
        let round: Int
        let matchCount: Int
        let bonusMatch: Bool
        let rank: Int?
        let prize: String?
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 선택된 조합
                VStack(alignment: .leading, spacing: 12) {
                    Text("선택된 조합")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(combination.numbers, id: \.self) { number in
                            LottoBall(number: number, size: 40)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // 회차 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("확인할 회차")
                        .font(.headline)

                    HStack {
                        TextField("회차 번호", text: $selectedRound)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button {
                            checkCombination()
                        } label: {
                            Text("확인")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(selectedRound.isEmpty || isChecking)
                    }
                }
                .padding()

                // 결과 표시
                if let result = checkResult {
                    ResultCard(result: result)
                }

                if isChecking {
                    ProgressView("확인 중...")
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("당첨 확인")
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

    private func checkCombination() {
        guard let round = Int(selectedRound) else { return }

        isChecking = true
        Task {
            do {
                let service = LottoService.shared
                let lottoData = try await service.fetchLottoData(round: round)

                let winningSet = Set(lottoData.numbers)
                let userSet = Set(combination.numbers)
                let matchCount = winningSet.intersection(userSet).count
                let bonusMatch = userSet.contains(lottoData.bnusNo)

                var rank: Int?
                var prize: String?

                switch matchCount {
                case 6:
                    rank = 1
                    prize = "1등 당첨!"
                case 5:
                    if bonusMatch {
                        rank = 2
                        prize = "2등 당첨!"
                    } else {
                        rank = 3
                        prize = "3등 당첨!"
                    }
                case 4:
                    rank = 4
                    prize = "4등 당첨!"
                case 3:
                    rank = 5
                    prize = "5등 당첨!"
                default:
                    prize = "낙첨"
                }

                await MainActor.run {
                    checkResult = CheckResult(
                        round: round,
                        matchCount: matchCount,
                        bonusMatch: bonusMatch,
                        rank: rank,
                        prize: prize
                    )
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                }
            }
        }
    }
}

struct ResultCard: View {
    let result: CombinationCheckView.CheckResult

    var body: some View {
        VStack(spacing: 15) {
            Text("\(result.round)회차 결과")
                .font(.headline)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("일치 개수")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(result.matchCount)개")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if result.bonusMatch {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("보너스")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }

            if let prize = result.prize {
                Text(prize)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(result.rank != nil ? .green : .gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        result.rank != nil ?
                        Color.green.opacity(0.1) :
                        Color.gray.opacity(0.1)
                    )
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// Extension for CombinationType to make it CaseIterable
extension RecommendedCombination.CombinationType: CaseIterable {
    static var allCases: [RecommendedCombination.CombinationType] {
        return [.hotNumbers, .coldNumbers, .balanced, .pattern, .statistical]
    }
}