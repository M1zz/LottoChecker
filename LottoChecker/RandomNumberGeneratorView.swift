import SwiftUI

struct RandomNumberGeneratorView: View {
    @Binding var selectedTab: Int
    @State private var generatedNumbers: [Int] = []
    @State private var includeNumbers: Set<Int> = []
    @State private var excludeNumbers: Set<Int> = []
    @State private var showingNumberPicker = false
    @State private var pickerMode: PickerMode = .include
    @State private var minOddCount: Int = 0
    @State private var maxOddCount: Int = 6
    @State private var showingFilterSheet = false
    @State private var savedCombinations: [[Int]] = []
    @State private var enableOddEvenFilter: Bool = false
    @State private var enableIncludeFilter: Bool = false
    @State private var enableExcludeFilter: Bool = false

    // AI 분석 스타일 필터
    @State private var enableSumRangeFilter: Bool = false
    @State private var minSum: Int = 100
    @State private var maxSum: Int = 150
    @State private var enableSectionBalance: Bool = false
    @State private var enableConsecutiveLimit: Bool = false
    @State private var maxConsecutive: Int = 2
    @State private var showingSaveAlert = false
    @State private var savedMessage = ""

    enum PickerMode {
        case include, exclude
    }

    // UserDefaults keys
    private let includeNumbersKey = "includeNumbers"
    private let excludeNumbersKey = "excludeNumbers"
    private let minOddCountKey = "minOddCount"
    private let maxOddCountKey = "maxOddCount"
    private let enableOddEvenKey = "enableOddEven"
    private let enableIncludeKey = "enableInclude"
    private let enableExcludeKey = "enableExclude"
    private let enableSumRangeKey = "enableSumRange"
    private let minSumKey = "minSum"
    private let maxSumKey = "maxSum"
    private let enableSectionBalanceKey = "enableSectionBalance"
    private let enableConsecutiveLimitKey = "enableConsecutiveLimit"
    private let maxConsecutiveKey = "maxConsecutive"

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 15) {
                    // 생성된 번호 표시
                    if !generatedNumbers.isEmpty {
                        generatedNumbersCard
                            .padding(.horizontal, 16)

                        // AI 분석 번호 찾기 버튼
                        aiAnalysisPromptCard
                            .padding(.horizontal, 16)
                    }

                    // 필터 설정 카드
                    filterSettingsCard
                        .padding(.horizontal, 16)

                    // 생성 버튼
                    generateButton
                        .padding(.horizontal, 16)

                    // 저장된 조합
                    if !savedCombinations.isEmpty {
                        savedCombinationsCard
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .overlay(
            Group {
                if showingSaveAlert {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(savedMessage)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showingSaveAlert)
                }
            }
        )
        .sheet(isPresented: $showingNumberPicker) {
            numberPickerSheet
        }
        .sheet(isPresented: $showingFilterSheet) {
            filterDetailSheet
        }
        .onAppear {
            loadSettings()
            if generatedNumbers.isEmpty {
                generateNumbers()
            }
        }
    }

    // MARK: - View Components

    private var generatedNumbersCard: some View {
        VStack(spacing: 15) {
            Text("생성된 번호")
                .font(.headline)
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
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("다시 생성")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button {
                    saveNumber()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                        Text("저장")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            Divider()
                .padding(.vertical, 4)

            // 적용된 필터 표시
            VStack(alignment: .leading, spacing: 10) {
                Text("적용된 조건")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    if enableIncludeFilter && !includeNumbers.isEmpty {
                        filterStatusRow(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            text: "포함: \(includeNumbers.sorted().map(String.init).joined(separator: ", "))"
                        )
                    }

                    if enableExcludeFilter && !excludeNumbers.isEmpty {
                        filterStatusRow(
                            icon: "xmark.circle.fill",
                            color: .red,
                            text: "제외: \(excludeNumbers.sorted().map(String.init).joined(separator: ", "))"
                        )
                    }

                    if enableOddEvenFilter {
                        filterStatusRow(
                            icon: "chart.bar.fill",
                            color: .blue,
                            text: "홀수: \(minOddCount)~\(maxOddCount)개"
                        )
                    }

                    if enableSumRangeFilter {
                        filterStatusRow(
                            icon: "plus.forwardslash.minus",
                            color: .orange,
                            text: "합계: \(minSum)~\(maxSum)"
                        )
                    }

                    if enableSectionBalance {
                        filterStatusRow(
                            icon: "chart.bar.fill",
                            color: .purple,
                            text: "구간별 균등 분포"
                        )
                    }

                    if enableConsecutiveLimit {
                        filterStatusRow(
                            icon: "arrow.right.arrow.left",
                            color: .green,
                            text: "연속 최대 \(maxConsecutive)개"
                        )
                    }

                    if !enableIncludeFilter && !enableExcludeFilter && !enableOddEvenFilter && !enableSumRangeFilter && !enableSectionBalance && !enableConsecutiveLimit {
                        HStack {
                            Image(systemName: "dice.fill")
                                .foregroundColor(.gray)
                            Text("조건 없음 (완전 랜덤)")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

    private func filterStatusRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var aiAnalysisPromptCard: some View {
        VStack(spacing: 12) {
            Text("마음에 드는 번호가 없으세요?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                selectedTab = 1  // AI분석 탭으로 전환
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                    Text("AI분석 번호로 찾아보기")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding()
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private var filterSettingsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("필터 설정")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    resetFilters()
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

            // 포함 번호 필터
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableIncludeFilter) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("포함할 번호 지정")
                            .font(.subheadline)
                    }
                }
                .onChange(of: enableIncludeFilter) { _, newValue in
                    if !newValue {
                        includeNumbers.removeAll()
                    }
                    saveSettings()
                }

                if enableIncludeFilter {
                    HStack {
                        if !includeNumbers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(includeNumbers).sorted(), id: \.self) { number in
                                        HStack(spacing: 4) {
                                            Text("\(number)")
                                                .font(.caption)
                                            Button {
                                                includeNumbers.remove(number)
                                                saveSettings()
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption2)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Button {
                            pickerMode = .include
                            showingNumberPicker = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                }
            }

            Divider()

            // 제외 번호 필터
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableExcludeFilter) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("제외할 번호 지정")
                            .font(.subheadline)
                    }
                }
                .onChange(of: enableExcludeFilter) { _, newValue in
                    if !newValue {
                        excludeNumbers.removeAll()
                    }
                    saveSettings()
                }

                if enableExcludeFilter {
                    HStack {
                        if !excludeNumbers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(excludeNumbers).sorted(), id: \.self) { number in
                                        HStack(spacing: 4) {
                                            Text("\(number)")
                                                .font(.caption)
                                            Button {
                                                excludeNumbers.remove(number)
                                                saveSettings()
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption2)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        Button {
                            pickerMode = .exclude
                            showingNumberPicker = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
            }

            Divider()

            // 홀짝 비율 필터
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableOddEvenFilter) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        Text("홀수 개수 제한")
                            .font(.subheadline)
                    }
                }
                .onChange(of: enableOddEvenFilter) { _, _ in
                    saveSettings()
                }

                if enableOddEvenFilter {
                    VStack(spacing: 8) {
                        HStack {
                            Text("홀수 개수:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(minOddCount) ~ \(maxOddCount)개")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        Button {
                            showingFilterSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("범위 조정")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
            }

            Divider()

            // AI 스타일: 합계 범위 필터
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableSumRangeFilter) {
                    HStack {
                        Image(systemName: "plus.forwardslash.minus")
                            .foregroundColor(.orange)
                        Text("번호 합계 범위 설정")
                            .font(.subheadline)
                    }
                }
                .onChange(of: enableSumRangeFilter) { _, _ in
                    saveSettings()
                }

                if enableSumRangeFilter {
                    VStack(spacing: 8) {
                        HStack {
                            Text("합계 범위:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(minSum) ~ \(maxSum)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        HStack(spacing: 10) {
                            VStack {
                                Text("최소")
                                    .font(.caption2)
                                Stepper("\(minSum)", value: $minSum, in: 21...maxSum)
                                    .labelsHidden()
                                    .onChange(of: minSum) { _, _ in saveSettings() }
                            }
                            VStack {
                                Text("최대")
                                    .font(.caption2)
                                Stepper("\(maxSum)", value: $maxSum, in: minSum...255)
                                    .labelsHidden()
                                    .onChange(of: maxSum) { _, _ in saveSettings() }
                            }
                        }
                    }
                }
            }

            Divider()

            // AI 스타일: 구간별 균등 분포
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableSectionBalance) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.purple)
                        Text("구간별 균등 분포")
                            .font(.subheadline)
                    }
                }
                .onChange(of: enableSectionBalance) { _, _ in
                    saveSettings()
                }

                if enableSectionBalance {
                    Text("1-10, 11-20, 21-30, 31-40, 41-45 구간에서 고르게 선택")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }

            Divider()

            // AI 스타일: 연속 번호 제한
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $enableConsecutiveLimit) {
                    HStack {
                        Image(systemName: "arrow.right.arrow.left")
                            .foregroundColor(.green)
                        Text("연속 번호 제한")
                            .font(.subheadline)
                    }
                }
                .onChange(of: enableConsecutiveLimit) { _, _ in
                    saveSettings()
                }

                if enableConsecutiveLimit {
                    VStack(spacing: 8) {
                        HStack {
                            Text("최대 연속 개수:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(maxConsecutive)개")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        Stepper("", value: $maxConsecutive, in: 0...5)
                            .labelsHidden()
                            .onChange(of: maxConsecutive) { _, _ in saveSettings() }

                        Text("예: 최대 2개면 5,6,7,8 같은 연속은 불가")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
                        saveSettings()
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
                        saveSettings()
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
        var attempts = 0
        let maxAttempts = 1000

        while attempts < maxAttempts {
            var availableNumbers = Set(1...45)
            var result: [Int] = []

            // 포함 필터 적용
            if enableIncludeFilter {
                result.append(contentsOf: includeNumbers)
                availableNumbers.subtract(includeNumbers)
            }

            // 제외 필터 적용
            if enableExcludeFilter {
                availableNumbers.subtract(excludeNumbers)
            }

            // 남은 번호 생성
            let needCount = 6 - result.count

            if needCount > 0 {
                if enableSectionBalance {
                    // 구간별 균등 분포
                    result.append(contentsOf: generateBalancedNumbers(count: needCount, from: availableNumbers))
                } else {
                    let remainingNumbers = Array(availableNumbers).shuffled().prefix(needCount)
                    result.append(contentsOf: remainingNumbers)
                }
            }

            let sortedResult = result.sorted()

            // 모든 필터 조건 확인
            var valid = true

            // 홀짝 필터 확인
            if enableOddEvenFilter {
                let oddCount = sortedResult.filter { $0 % 2 == 1 }.count
                if oddCount < minOddCount || oddCount > maxOddCount {
                    valid = false
                }
            }

            // 합계 범위 필터 확인
            if enableSumRangeFilter {
                let sum = sortedResult.reduce(0, +)
                if sum < minSum || sum > maxSum {
                    valid = false
                }
            }

            // 연속 번호 제한 확인
            if enableConsecutiveLimit {
                var consecutiveCount = 0
                var maxFound = 0
                for i in 0..<(sortedResult.count - 1) {
                    if sortedResult[i + 1] == sortedResult[i] + 1 {
                        consecutiveCount += 1
                        maxFound = max(maxFound, consecutiveCount)
                    } else {
                        consecutiveCount = 0
                    }
                }
                if maxFound > maxConsecutive {
                    valid = false
                }
            }

            if valid {
                generatedNumbers = sortedResult
                return
            }

            attempts += 1
        }

        // 조건을 만족하는 조합을 찾지 못한 경우, 기본 랜덤 생성
        var availableNumbers = Set(1...45)
        var result: [Int] = []

        if enableIncludeFilter {
            result.append(contentsOf: includeNumbers)
            availableNumbers.subtract(includeNumbers)
        }
        if enableExcludeFilter {
            availableNumbers.subtract(excludeNumbers)
        }

        let needCount = 6 - result.count
        let remainingNumbers = Array(availableNumbers).shuffled().prefix(needCount)
        result.append(contentsOf: remainingNumbers)

        generatedNumbers = result.sorted()
    }

    private func generateBalancedNumbers(count: Int, from available: Set<Int>) -> [Int] {
        let sections = [
            Array(available.filter { $0 >= 1 && $0 <= 10 }),
            Array(available.filter { $0 >= 11 && $0 <= 20 }),
            Array(available.filter { $0 >= 21 && $0 <= 30 }),
            Array(available.filter { $0 >= 31 && $0 <= 40 }),
            Array(available.filter { $0 >= 41 && $0 <= 45 })
        ]

        var result: [Int] = []
        var sectionIndex = 0

        for _ in 0..<count {
            var selectedSection = sections[sectionIndex % 5].shuffled()

            // 이미 선택된 번호 제외
            selectedSection = selectedSection.filter { !result.contains($0) }

            if let number = selectedSection.first {
                result.append(number)
            } else {
                // 해당 구간에 사용 가능한 번호가 없으면 전체에서 선택
                let allAvailable = Array(available).filter { !result.contains($0) }
                if let number = allAvailable.randomElement() {
                    result.append(number)
                }
            }

            sectionIndex += 1
        }

        return result
    }

    private func resetFilters() {
        includeNumbers.removeAll()
        excludeNumbers.removeAll()
        minOddCount = 0
        maxOddCount = 6
        enableOddEvenFilter = false
        enableIncludeFilter = false
        enableExcludeFilter = false
        enableSumRangeFilter = false
        minSum = 100
        maxSum = 150
        enableSectionBalance = false
        enableConsecutiveLimit = false
        maxConsecutive = 2
        saveSettings()
    }

    // MARK: - Settings Persistence

    private func saveSettings() {
        UserDefaults.standard.set(Array(includeNumbers), forKey: includeNumbersKey)
        UserDefaults.standard.set(Array(excludeNumbers), forKey: excludeNumbersKey)
        UserDefaults.standard.set(minOddCount, forKey: minOddCountKey)
        UserDefaults.standard.set(maxOddCount, forKey: maxOddCountKey)
        UserDefaults.standard.set(enableOddEvenFilter, forKey: enableOddEvenKey)
        UserDefaults.standard.set(enableIncludeFilter, forKey: enableIncludeKey)
        UserDefaults.standard.set(enableExcludeFilter, forKey: enableExcludeKey)
        UserDefaults.standard.set(enableSumRangeFilter, forKey: enableSumRangeKey)
        UserDefaults.standard.set(minSum, forKey: minSumKey)
        UserDefaults.standard.set(maxSum, forKey: maxSumKey)
        UserDefaults.standard.set(enableSectionBalance, forKey: enableSectionBalanceKey)
        UserDefaults.standard.set(enableConsecutiveLimit, forKey: enableConsecutiveLimitKey)
        UserDefaults.standard.set(maxConsecutive, forKey: maxConsecutiveKey)
    }

    private func saveNumber() {
        savedCombinations.append(generatedNumbers)

        // UserDefaults에 저장
        let savedNumber = SavedLottoNumber(
            numbers: generatedNumbers,
            generationType: "통계기반",
            memo: nil
        )
        SavedNumbersManager.shared.save(savedNumber)

        // 피드백 표시
        savedMessage = "번호가 저장되었습니다"
        showingSaveAlert = true

        // 2초 후 피드백 숨기기
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaveAlert = false
        }
    }

    private func loadSettings() {
        if let savedInclude = UserDefaults.standard.array(forKey: includeNumbersKey) as? [Int] {
            includeNumbers = Set(savedInclude)
        }
        if let savedExclude = UserDefaults.standard.array(forKey: excludeNumbersKey) as? [Int] {
            excludeNumbers = Set(savedExclude)
        }
        minOddCount = UserDefaults.standard.integer(forKey: minOddCountKey)
        maxOddCount = UserDefaults.standard.object(forKey: maxOddCountKey) != nil ?
            UserDefaults.standard.integer(forKey: maxOddCountKey) : 6
        enableOddEvenFilter = UserDefaults.standard.bool(forKey: enableOddEvenKey)
        enableIncludeFilter = UserDefaults.standard.bool(forKey: enableIncludeKey)
        enableExcludeFilter = UserDefaults.standard.bool(forKey: enableExcludeKey)
        enableSumRangeFilter = UserDefaults.standard.bool(forKey: enableSumRangeKey)
        minSum = UserDefaults.standard.object(forKey: minSumKey) != nil ?
            UserDefaults.standard.integer(forKey: minSumKey) : 100
        maxSum = UserDefaults.standard.object(forKey: maxSumKey) != nil ?
            UserDefaults.standard.integer(forKey: maxSumKey) : 150
        enableSectionBalance = UserDefaults.standard.bool(forKey: enableSectionBalanceKey)
        enableConsecutiveLimit = UserDefaults.standard.bool(forKey: enableConsecutiveLimitKey)
        maxConsecutive = UserDefaults.standard.object(forKey: maxConsecutiveKey) != nil ?
            UserDefaults.standard.integer(forKey: maxConsecutiveKey) : 2
    }
}

#Preview {
    RandomNumberGeneratorView(selectedTab: .constant(0))
}
