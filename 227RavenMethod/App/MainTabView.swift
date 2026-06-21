import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color("AppPrimary").opacity(0.35), Color("AppPrimary").opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            HStack(spacing: 4) {
                ForEach(MainTab.allCases) { tab in
                    Button {
                        FeedbackService.lightTap()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.symbolName)
                                .font(.system(size: selectedTab == tab ? 17 : 15, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(
                            selectedTab == tab
                                ? Color("AppBackground")
                                : Color("AppTextPrimary").opacity(0.72)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    selectedTab == tab
                                        ? DepthGradients.primaryButton
                                        : LinearGradient(
                                            colors: [Color.clear, Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                )
                                .overlay(alignment: .top) {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color("AppTextPrimary").opacity(0.16), Color.clear],
                                                    startPoint: .top,
                                                    endPoint: .center
                                                )
                                            )
                                            .allowsHitTesting(false)
                                    }
                                }
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(
            DepthGradients.tabBar
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color("AppTextPrimary").opacity(0.06), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 18)
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView(selectedTab: $selectedTab)
                    case .discover:
                        DiscoverHubView()
                    case .library:
                        LibraryHubView()
                    case .achievements:
                        AchievementsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .overlay(alignment: .top) {
            if store.bannerManager.isVisible, let achievement = store.bannerManager.currentBanner {
                AchievementBannerView(achievement: achievement)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: store.bannerManager.isVisible)
    }
}

enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case discover
    case library
    case achievements
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .discover: return "Discover"
        case .library: return "Library"
        case .achievements: return "Badges"
        case .settings: return "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .home: return "house.fill"
        case .discover: return "sparkle.magnifyingglass"
        case .library: return "books.vertical"
        case .achievements: return "rosette"
        case .settings: return "gearshape"
        }
    }
}
