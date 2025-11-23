import SwiftUI

struct NumberGeneratorView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 세그먼트 컨트롤
                Picker("", selection: $selectedTab) {
                    Text("번호생성").tag(0)
                    Text("AI분석").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // 콘텐츠
                TabView(selection: $selectedTab) {
                    RandomNumberGeneratorView(selectedTab: $selectedTab)
                        .tag(0)

                    AdvancedAnalysisView(isActive: Binding(
                        get: { selectedTab == 1 },
                        set: { _ in }
                    ))
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(selectedTab == 0 ? "로또 번호 생성기" : "AI 분석")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    NumberGeneratorView()
}
