import SwiftUI

struct DisclaimerView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.red.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 경고 아이콘
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.orange)
                    .padding(.bottom, 10)

                // 제목
                Text("중요 안내사항")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                // 면책 조항 내용
                VStack(alignment: .leading, spacing: 20) {
                    DisclaimerItem(
                        icon: "function",
                        text: "이 앱은 확률 계산과 통계 분석을 위한 교육용 도구입니다.",
                        iconColor: .blue
                    )

                    DisclaimerItem(
                        icon: "info.circle.fill",
                        text: "이 앱은 로또 구매 기능을 제공하지 않습니다.",
                        iconColor: .green
                    )

                    DisclaimerItem(
                        icon: "person.fill.xmark",
                        text: "만 19세 미만은 로또를 구매할 수 없습니다.",
                        iconColor: .red
                    )

                    DisclaimerItem(
                        icon: "exclamationmark.shield.fill",
                        text: "과도한 복권 구매는 중독을 유발할 수 있습니다.",
                        iconColor: .orange
                    )
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.9))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)

                // 법적 고지
                VStack(spacing: 8) {
                    Text("청소년보호법에 따라")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("만 19세 미만 청소년은 복권 구매가 법으로 금지되어 있습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Spacer()

                // 확인 버튼
                Button {
                    hasSeenDisclaimer = true
                    isPresented = false
                } label: {
                    Text("확인했습니다")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

struct DisclaimerItem: View {
    let icon: String
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    DisclaimerView(isPresented: .constant(true))
}
