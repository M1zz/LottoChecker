import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = LottoViewModel()
    @State private var currentTime = Date()
    @Environment(\.openURL) private var openURL

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.top, 100)
                        } else if let error = viewModel.errorMessage {
                            ErrorView(
                                errorMessage: error,
                                errorSuggestion: viewModel.errorSuggestion,
                                retryAction: {
                                    Task {
                                        await viewModel.fetchLotto(round: viewModel.currentRound)
                                    }
                                }
                            )
                            .padding(.top, 50)
                        } else if let lotto = viewModel.lottoData {
                            VStack(spacing: 15) {
                                // 추첨까지 남은 시간 (발표 전)
                                countdownTimerCard

                                // 회차 정보
                                roundHeader(lotto: lotto)

                                // 당첨 번호
                                winningNumbers(lotto: lotto)

                                // 확인하러가기 버튼
                                checkNowButton

                                // 상세 정보
                                detailsCard(lotto: lotto)

                                // 네비게이션 버튼
                                navigationButtons
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .frame(width: geometry.size.width * 11 / 12)
                    .padding(.horizontal, (geometry.size.width * 1 / 24))
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var countdownTimerCard: some View {
        if let nextDrawDate = getNextDrawDate(), nextDrawDate > currentTime {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("다음 추첨까지")
                        .font(.headline)
                }

                let timeRemaining = getTimeRemaining(until: nextDrawDate)

                HStack(spacing: 15) {
                    TimeUnitView(value: timeRemaining.days, unit: "일")
                    Text(":")
                        .font(.title)
                        .foregroundColor(.gray)
                    TimeUnitView(value: timeRemaining.hours, unit: "시간")
                    Text(":")
                        .font(.title)
                        .foregroundColor(.gray)
                    TimeUnitView(value: timeRemaining.minutes, unit: "분")
                    Text(":")
                        .font(.title)
                        .foregroundColor(.gray)
                    TimeUnitView(value: timeRemaining.seconds, unit: "초")
                }

                Text(formatDrawDate(nextDrawDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.2)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }

    private var checkNowButton: some View {
        Button {
            selectedTab = 1
        } label: {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                Text("내 당첨여부 확인하러가기")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.7), Color.blue.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
    
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
        HStack(spacing: 15) {
            Button {
                Task {
                    await viewModel.loadPreviousRound()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("이전")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.currentRound > 1 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.currentRound <= 1)

            Button {
                Task {
                    await viewModel.loadNextRound()
                }
            } label: {
                HStack {
                    Text("다음")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.currentRound < viewModel.latestRound ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.currentRound >= viewModel.latestRound)
        }
    }

    // MARK: - Helper Functions

    /// 다음 토요일 20:35 (추첨 시간) 계산
    private func getNextDrawDate() -> Date? {
        let calendar = Calendar.current
        let now = currentTime

        // 한국 시간대 (KST)
        guard let koreaTimeZone = TimeZone(identifier: "Asia/Seoul") else { return nil }
        var koreaCalendar = Calendar.current
        koreaCalendar.timeZone = koreaTimeZone

        // 현재 한국 시간
        let koreaComponents = koreaCalendar.dateComponents(in: koreaTimeZone, from: now)
        guard let koreaDate = koreaCalendar.date(from: koreaComponents) else { return nil }

        // 이번 주 토요일 찾기
        var components = koreaCalendar.dateComponents([.year, .month, .day, .weekday], from: koreaDate)

        // 토요일 = 7, 일요일 = 1
        let currentWeekday = components.weekday ?? 0
        var daysUntilSaturday = 7 - currentWeekday

        if currentWeekday == 7 {
            // 오늘이 토요일인 경우
            let koreaHour = koreaComponents.hour ?? 0
            let koreaMinute = koreaComponents.minute ?? 0

            if koreaHour > 20 || (koreaHour == 20 && koreaMinute >= 35) {
                // 이미 추첨이 지났으면 다음 주 토요일
                daysUntilSaturday = 7
            } else {
                // 아직 추첨 전이면 오늘
                daysUntilSaturday = 0
            }
        }

        // 토요일 날짜 계산
        guard var nextSaturday = koreaCalendar.date(byAdding: .day, value: daysUntilSaturday, to: koreaDate) else {
            return nil
        }

        // 20:35로 설정
        var drawComponents = koreaCalendar.dateComponents([.year, .month, .day], from: nextSaturday)
        drawComponents.hour = 20
        drawComponents.minute = 35
        drawComponents.second = 0
        drawComponents.timeZone = koreaTimeZone

        return koreaCalendar.date(from: drawComponents)
    }

    private func getTimeRemaining(until date: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: currentTime, to: date)

        return (
            days: max(0, components.day ?? 0),
            hours: max(0, components.hour ?? 0),
            minutes: max(0, components.minute ?? 0),
            seconds: max(0, components.second ?? 0)
        )
    }

    private func formatDrawDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E) HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date) + " 추첨"
    }
}

struct TimeUnitView: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .frame(minWidth: 50)

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
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

// MARK: - Error View Component
struct ErrorView: View {
    let errorMessage: String
    let errorSuggestion: String?
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            // 에러 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.1), Color.orange.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "wifi.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }

            // 에러 메시지
            VStack(spacing: 12) {
                Text(errorMessage)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if let suggestion = errorSuggestion {
                    Text(suggestion)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            // 재시도 버튼
            Button {
                retryAction()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 200)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 30)
    }
}

#Preview {
    ContentView(selectedTab: .constant(0))
}
