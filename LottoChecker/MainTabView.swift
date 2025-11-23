import SwiftUI

struct MainTabView: View {
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
                    Label("생성·분석", systemImage: "wand.and.stars")
                }

            ExpectedValueView()
                .tabItem {
                    Label("시뮬레이션", systemImage: "play.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
