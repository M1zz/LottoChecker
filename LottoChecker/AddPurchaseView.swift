import SwiftUI
import SwiftData

struct AddPurchaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LottoViewModel()

    @State private var selectedRound: Int?
    @State private var roundInput = ""
    @State private var userNumbers: [Int?] = Array(repeating: nil, count: 6)
    @State private var showingNumberInput = false
    @State private var currentInputIndex = 0
    @State private var purchaseMethod = "수동"
    @State private var showRoundError = false

    var allNumbersEntered: Bool {
        userNumbers.allSatisfy { $0 != nil }
    }

    var validNumbers: [Int] {
        userNumbers.compactMap { $0 }.sorted()
    }

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
                        // 회차 선택
                        roundSelectionCard

                        // 번호 입력
                        numberInputCard

                        // 저장 버튼
                        if allNumbersEntered && selectedRound != nil {
                            saveButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("구매 번호 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNumberInput) {
                numberPickerSheet
            }
        }
    }

    // MARK: - View Components

    private var roundSelectionCard: some View {
        VStack(spacing: 15) {
            Text("회차 선택")
                .font(.headline)
                .fontWeight(.semibold)

            Divider()

            VStack(spacing: 12) {
                if let round = selectedRound {
                    VStack(spacing: 8) {
                        Text("\(round)회")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)

                        Button {
                            selectedRound = nil
                            roundInput = ""
                            showRoundError = false
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("다시 선택")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            TextField("회차 번호 입력", text: $roundInput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.title3)
                                .multilineTextAlignment(.center)

                            Button {
                                if let round = Int(roundInput), round >= 1, round <= viewModel.latestRound {
                                    selectedRound = round
                                    showRoundError = false
                                } else {
                                    showRoundError = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("선택")
                                }
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(roundInput.isEmpty)
                        }

                        HStack {
                            Text("1회 ~ \(viewModel.latestRound)회")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button {
                                roundInput = "\(viewModel.latestRound)"
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                    Text("최신 회차")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }

                        if showRoundError {
                            Text("올바른 회차를 입력해주세요 (1 ~ \(viewModel.latestRound))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
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
                Text("번호 입력")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    userNumbers = Array(repeating: nil, count: 6)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("초기화")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()
                .padding(.vertical, 4)

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

            // 입력 방법 선택
            Picker("입력 방법", selection: $purchaseMethod) {
                Text("수동").tag("수동")
                Text("자동").tag("자동")
            }
            .pickerStyle(.segmented)

            if purchaseMethod == "자동" {
                Button {
                    generateRandomNumbers()
                } label: {
                    HStack {
                        Image(systemName: "dice.fill")
                        Text("번호 자동 생성")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var saveButton: some View {
        Button {
            savePurchase()
        } label: {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                Text("저장하기")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
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

    private func generateRandomNumbers() {
        let randomNumbers = Array(1...45).shuffled().prefix(6).map { $0 as Int? }
        userNumbers = Array(randomNumbers)
    }

    private func savePurchase() {
        guard let round = selectedRound, allNumbersEntered else { return }

        let purchase = PurchaseHistory(
            round: round,
            numbers: validNumbers,
            purchaseMethod: purchaseMethod
        )

        modelContext.insert(purchase)
        dismiss()
    }
}

#Preview {
    AddPurchaseView()
        .modelContainer(for: PurchaseHistory.self, inMemory: true)
}
