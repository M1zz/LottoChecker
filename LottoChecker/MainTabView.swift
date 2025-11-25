import SwiftUI

struct MainTabView: View {
    @State private var showDisclaimer = false
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false

    var body: some View {
        TabView {
            RealTimeProbabilityCalculator()
                .tabItem {
                    Label("계산기", systemImage: "plus.forwardslash.minus")
                }

            EnhancedStatisticsView()
                .tabItem {
                    Label("통계 분석", systemImage: "chart.bar.fill")
                }

            LottoMainView()
                .tabItem {
                    Label("당첨번호", systemImage: "star.fill")
                }
        }
        .fullScreenCover(isPresented: $showDisclaimer) {
            DisclaimerView(isPresented: $showDisclaimer)
        }
        .onAppear {
            if !hasSeenDisclaimer {
                showDisclaimer = true
            }
        }
    }
}

#Preview {
    MainTabView()
}
