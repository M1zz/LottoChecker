import SwiftUI

struct LottoMainView: View {
    @State private var selectedTab = 0
    @State private var showingPurchaseHistory = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 세그먼트 컨트롤
                Picker("", selection: $selectedTab) {
                    Text("당첨번호").tag(0)
                    Text("당첨확인").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // 콘텐츠
                TabView(selection: $selectedTab) {
                    ContentView(selectedTab: $selectedTab)
                        .tag(0)

                    WinningCheckView(selectedTab: $selectedTab)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(selectedTab == 0 ? "로또 당첨번호" : "당첨 확인")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPurchaseHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingPurchaseHistory) {
                PurchaseHistoryView()
            }
        }
    }
}

#Preview {
    LottoMainView()
}
