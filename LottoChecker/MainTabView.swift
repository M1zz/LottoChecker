import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("당첨번호", systemImage: "star.fill")
                }

            WinningCheckView()
                .tabItem {
                    Label("당첨확인", systemImage: "checkmark.circle.fill")
                }

            RandomNumberGeneratorView()
                .tabItem {
                    Label("번호생성", systemImage: "dice.fill")
                }

            AdvancedAnalysisView()
                .tabItem {
                    Label("AI분석", systemImage: "brain.head.profile")
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
