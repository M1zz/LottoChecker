import SwiftUI

struct RandomNumberGeneratorView: View {
    @State private var generatedNumbers: [Int] = []
    @State private var includeNumbers: Set<Int> = []
    @State private var excludeNumbers: Set<Int> = []
    @State private var showingNumberPicker = false
    @State private var pickerMode: PickerMode = .include
    @State private var minOddCount: Int = 0
    @State private var maxOddCount: Int = 6
    @State private var showingFilterSheet = false
    @State private var savedCombinations: [[Int]] = []

    enum PickerMode {
        case include, exclude
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // 생성된 번호 표시
                        if !generatedNumbers.isEmpty {
                            generatedNumbersCard
                        }

                        // 필터 설정 카드
                        filterSettingsCard

                        // 생성 버튼
                        generateButton

                        // 저장된 조합
                        if !savedCombinations.isEmpty {
                            savedCombinationsCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("로또 번호 생성기")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingNumberPicker) {
                numberPickerSheet
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterDetailSheet
            }
        }
    }

    // MARK: - View Components

    private var generatedNumbersCard: some View {
        VStack(spacing: 15) {
            Text("생성된 번호")
                .font(.title3)
                .fontWeight(.semibold)

            HStack(spacing: 10) {
                ForEach(generatedNumbers, id: \.self) { number in
                    numberBall(number: number)
                }
            }

            HStack(spacing: 10) {
                Button {
                    generateNumbers()
                } label: {
                    Label("다시 생성", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                Button {
                    savedCombinations.append(generatedNumbers)
                } label: {
                    Label("저장", systemImage: "bookmark.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var filterSettingsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("필터 설정")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            // 포함 번호
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("포함할 번호")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        pickerMode = .include
                        showingNumberPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                if !includeNumbers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(includeNumbers).sorted(), id: \.self) { number in
                                HStack(spacing: 4) {
                                    Text("\(number)")
                                        .font(.subheadline)
                                    Button {
                                        includeNumbers.remove(number)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                } else {
                    Text("없음")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // 제외 번호
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("제외할 번호")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        pickerMode = .exclude
                        showingNumberPicker = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                if !excludeNumbers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(excludeNumbers).sorted(), id: \.self) { number in
                                HStack(spacing: 4) {
                                    Text("\(number)")
                                        .font(.subheadline)
                                    Button {
                                        excludeNumbers.remove(number)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                } else {
                    Text("없음")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // 홀짝 비율
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("홀수 개수")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(minOddCount) ~ \(maxOddCount)개")
                        .fontWeight(.semibold)
                }

                Button {
                    showingFilterSheet = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("상세 필터")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }

            // 초기화 버튼
            Button {
                resetFilters()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("필터 초기화")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var generateButton: some View {
        Button {
            generateNumbers()
        } label: {
            HStack {
                Image(systemName: "dice.fill")
                Text("번호 생성하기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }

    private var savedCombinationsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("저장된 조합 (\(savedCombinations.count))")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    savedCombinations.removeAll()
                } label: {
                    Text("전체 삭제")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Divider()

            ForEach(Array(savedCombinations.enumerated()), id: \.offset) { index, numbers in
                HStack {
                    ForEach(numbers, id: \.self) { number in
                        numberBall(number: number, size: 35)
                    }
                    Spacer()
                    Button {
                        savedCombinations.remove(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 5)

                if index < savedCombinations.count - 1 {
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
                        let isSelected = pickerMode == .include ?
                            includeNumbers.contains(number) :
                            excludeNumbers.contains(number)
                        let isDisabled = pickerMode == .include ?
                            excludeNumbers.contains(number) :
                            includeNumbers.contains(number)

                        Button {
                            if pickerMode == .include {
                                if includeNumbers.contains(number) {
                                    includeNumbers.remove(number)
                                } else {
                                    includeNumbers.insert(number)
                                }
                            } else {
                                if excludeNumbers.contains(number) {
                                    excludeNumbers.remove(number)
                                } else {
                                    excludeNumbers.insert(number)
                                }
                            }
                        } label: {
                            Text("\(number)")
                                .font(.headline)
                                .frame(width: 50, height: 50)
                                .background(
                                    isDisabled ? Color.gray.opacity(0.3) :
                                    isSelected ? (pickerMode == .include ? Color.green : Color.red) :
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
            .navigationTitle(pickerMode == .include ? "포함할 번호 선택" : "제외할 번호 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        showingNumberPicker = false
                    }
                }
            }
        }
    }

    private var filterDetailSheet: some View {
        NavigationView {
            Form {
                Section("홀수 개수 범위") {
                    Stepper("최소: \(minOddCount)개", value: $minOddCount, in: 0...maxOddCount)
                    Stepper("최대: \(maxOddCount)개", value: $maxOddCount, in: minOddCount...6)
                }

                Section {
                    Text("홀수와 짝수의 비율을 조정하여 원하는 조합을 생성할 수 있습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("상세 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        showingFilterSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func numberBall(number: Int, size: CGFloat = 45) -> some View {
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
        case 1...10:
            return Color(red: 0.984, green: 0.769, blue: 0.0) // #FBC400 - 진한 노란색
        case 11...20:
            return Color(red: 0.412, green: 0.784, blue: 0.949) // #69C8F2 - 하늘색
        case 21...30:
            return Color(red: 1.0, green: 0.447, blue: 0.447) // #FF7272 - 연한 빨간색
        case 31...40:
            return Color(red: 0.667, green: 0.698, blue: 0.741) // #AAB2BD - 회색
        default:
            return Color(red: 0.69, green: 0.847, blue: 0.251) // #B0D840 - 연두색
        }
    }

    private func generateNumbers() {
        var availableNumbers = Set(1...45)

        // 제외 번호 제거
        availableNumbers.subtract(excludeNumbers)

        var result: [Int] = []

        // 포함 번호 먼저 추가
        result.append(contentsOf: includeNumbers)
        availableNumbers.subtract(includeNumbers)

        // 남은 번호 생성
        let needCount = 6 - result.count

        if needCount > 0 {
            var attempts = 0
            let maxAttempts = 100

            while attempts < maxAttempts {
                var tempResult = result
                let remainingNumbers = Array(availableNumbers).shuffled().prefix(needCount)
                tempResult.append(contentsOf: remainingNumbers)

                let oddCount = tempResult.filter { $0 % 2 == 1 }.count

                if oddCount >= minOddCount && oddCount <= maxOddCount {
                    result = tempResult
                    break
                }

                attempts += 1
            }

            // 조건을 만족하는 조합을 찾지 못한 경우
            if result.count < 6 {
                let remainingNumbers = Array(availableNumbers).shuffled().prefix(needCount)
                result.append(contentsOf: remainingNumbers)
            }
        }

        generatedNumbers = result.sorted()
    }

    private func resetFilters() {
        includeNumbers.removeAll()
        excludeNumbers.removeAll()
        minOddCount = 0
        maxOddCount = 6
    }
}

#Preview {
    RandomNumberGeneratorView()
}
