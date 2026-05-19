import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                KeepersView()
                    .tag(1)
                DiveMapView(keeperID: nil)
                    .tag(2)
                AnalyticsView()
                    .tag(3)
                TrainingView()
                    .tag(4)
            }
            .ignoresSafeArea(edges: .bottom)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Dashboard"),
        ("person.3.fill", "Keepers"),
        ("target", "Dive Map"),
        ("chart.bar.fill", "Analytics"),
        ("figure.run", "Training")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                tabButton(index: i)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, max(28, 16))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.bgNight.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.accentGreen.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 16, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func tabButton(index: Int) -> some View {
        let isSelected = selectedTab == index
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentGreen.opacity(0.15))
                            .frame(width: 44, height: 34)
                    }
                    Image(systemName: tabs[index].icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .accentGreen : .textSecondary.opacity(0.6))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                Text(tabs[index].label)
                    .font(AppFont.caption(10))
                    .foregroundColor(isSelected ? .accentGreen : .textSecondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
