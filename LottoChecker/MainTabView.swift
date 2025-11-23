import SwiftUI

struct MainTabView: View {
    @State private var showDisclaimer = false
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false

    var body: some View {
        TabView {
            LottoMainView()
                .tabItem {
                    Label("로또", systemImage: "star.fill")
                }

            PurchaseHistoryView()
                .tabItem {
                    Label("히스토리", systemImage: "book.fill")
                }

            NumberGeneratorView()
                .tabItem {
                    Label("통계 분석", systemImage: "chart.bar.fill")
                }

            ExpectedValueView()
                .tabItem {
                    Label("확률 계산기", systemImage: "percent")
                }

            SavedNumbersView()
                .tabItem {
                    Label("저장 번호", systemImage: "bookmark.fill")
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
