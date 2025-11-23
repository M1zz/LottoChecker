import SwiftUI

struct SavedNumbersView: View {
    @State private var savedNumbers: [SavedLottoNumber] = []
    @State private var showingDeleteAlert = false
    @State private var numberToDelete: SavedLottoNumber?
    @State private var refreshID = UUID()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if savedNumbers.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(savedNumbers) { savedNumber in
                                SavedNumberCard(savedNumber: savedNumber) {
                                    numberToDelete = savedNumber
                                    showingDeleteAlert = true
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .id(refreshID)
                }
            }
            .navigationTitle("저장된 번호")
            .navigationBarTitleDisplayMode(.large)
            .alert("번호 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let number = numberToDelete {
                        deleteNumber(number)
                    }
                }
            } message: {
                Text("이 번호를 삭제하시겠습니까?")
            }
            .onAppear {
                // 뷰가 나타날 때마다 새로고침
                loadSavedNumbers()
                refreshID = UUID()
                print("SavedNumbersView appeared - Total saved numbers: \(savedNumbers.count)")
                for (index, number) in savedNumbers.enumerated() {
                    print("  [\(index)] \(number.generationType): \(number.numbers)")
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))

            Text("저장된 번호가 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("통계 분석 탭에서\nAI 추천 번호를 저장해보세요")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func loadSavedNumbers() {
        savedNumbers = SavedNumbersManager.shared.loadAll()
    }

    private func deleteNumber(_ savedNumber: SavedLottoNumber) {
        withAnimation {
            SavedNumbersManager.shared.delete(savedNumber)
            loadSavedNumbers()
        }
    }
}

struct SavedNumberCard: View {
    let savedNumber: SavedLottoNumber
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: iconForGenerationType)
                        .foregroundColor(colorForGenerationType)
                    Text(savedNumber.generationType)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForGenerationType)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(colorForGenerationType.opacity(0.15))
                .cornerRadius(8)

                Spacer()

                Text(savedNumber.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 번호
            HStack(spacing: 8) {
                ForEach(savedNumber.numbers, id: \.self) { number in
                    numberBall(number: number)
                }
            }

            // 메모
            if let memo = savedNumber.memo, !memo.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }

            // 삭제 버튼
            HStack {
                Spacer()
                Button {
                    onDelete()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("삭제")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var iconForGenerationType: String {
        switch savedNumber.generationType {
        case "AI추천":
            return "sparkles"
        case "통계기반":
            return "chart.bar.fill"
        case "수동입력":
            return "hand.tap.fill"
        default:
            return "bookmark.fill"
        }
    }

    private var colorForGenerationType: Color {
        switch savedNumber.generationType {
        case "AI추천":
            return .purple
        case "통계기반":
            return .blue
        case "수동입력":
            return .green
        default:
            return .gray
        }
    }

    private func numberBall(number: Int) -> some View {
        Circle()
            .fill(ballColor(for: number))
            .frame(width: 40, height: 40)
            .overlay(
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
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
}

#Preview {
    SavedNumbersView()
}
