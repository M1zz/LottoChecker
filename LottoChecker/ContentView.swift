import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LottoViewModel()
    @State private var showingRoundInput = false
    @State private var inputRound = ""
    
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
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.top, 100)
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 15) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                Button("다시 시도") {
                                    Task {
                                        await viewModel.fetchLotto(round: viewModel.currentRound)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 100)
                        } else if let lotto = viewModel.lottoData {
                            VStack(spacing: 25) {
                                // 회차 정보
                                roundHeader(lotto: lotto)
                                
                                // 당첨 번호
                                winningNumbers(lotto: lotto)
                                
                                // 상세 정보
                                detailsCard(lotto: lotto)
                                
                                // 네비게이션 버튼
                                navigationButtons
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("로또 당첨번호")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRoundInput = true
                    } label: {
                        Image(systemName: "number.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingRoundInput) {
                roundInputSheet
            }
        }
    }
    
    // MARK: - View Components
    
    private func roundHeader(lotto: LottoResponse) -> some View {
        VStack(spacing: 8) {
            Text("\(lotto.drwNo)회")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)
            
            Text(lotto.formattedDate)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private func winningNumbers(lotto: LottoResponse) -> some View {
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
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func numberBall(number: Int, isBonus: Bool = false) -> some View {
        Circle()
            .fill(ballColor(for: number, isBonus: isBonus))
            .frame(width: 45, height: 45)
            .overlay(
                Text("\(number)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
    
    private func ballColor(for number: Int, isBonus: Bool) -> Color {
        if isBonus {
            return Color(red: 1.0, green: 0.6, blue: 0.0) // 주황색
        }

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
    
    private func detailsCard(lotto: LottoResponse) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("당첨 정보")
                .font(.title3)
                .fontWeight(.semibold)
            
            Divider()
            
            DetailRow(title: "1등 당첨자", value: "\(lotto.firstPrzwnerCo)명")
            DetailRow(title: "1등 당첨금", value: "\(lotto.formattedFirstPrize)원")
            DetailRow(title: "총 판매금액", value: "\(lotto.formattedTotalAmount)원")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await viewModel.loadPreviousRound()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("이전 회차")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.currentRound > 1 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .disabled(viewModel.currentRound <= 1)
            
            Button {
                Task {
                    await viewModel.loadNextRound()
                }
            } label: {
                HStack {
                    Text("다음 회차")
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.currentRound < viewModel.latestRound ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .disabled(viewModel.currentRound >= viewModel.latestRound)
        }
        .padding(.horizontal)
    }
    
    private var roundInputSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("회차를 입력하세요")
                    .font(.headline)
                
                TextField("회차 번호", text: $inputRound)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Text("1회 ~ \(viewModel.latestRound)회")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("조회") {
                    if let round = Int(inputRound), round >= 1, round <= viewModel.latestRound {
                        Task {
                            await viewModel.fetchLotto(round: round)
                            showingRoundInput = false
                            inputRound = ""
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputRound.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("회차 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showingRoundInput = false
                        inputRound = ""
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ContentView()
}
