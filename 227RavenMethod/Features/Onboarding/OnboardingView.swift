import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            headline: "Your Media Hub",
            description: "Collect journals, timeline events, and favorites in one calm workspace.",
            symbol: "house.fill",
            features: [
                ("square.and.pencil", "Journals"),
                ("calendar", "Timeline"),
                ("books.vertical", "Library")
            ]
        ),
        OnboardingPage(
            headline: "Connect Everything",
            description: "Link photos to events, discover stories, and spot themes with smart insights.",
            symbol: "sparkle.magnifyingglass",
            features: [
                ("book.pages.fill", "Stories"),
                ("chart.bar.fill", "Insights"),
                ("tag.fill", "Tags")
            ]
        ),
        OnboardingPage(
            headline: "Build Your Ritual",
            description: "Track streaks, earn badges, and finish weekly reviews to stay inspired.",
            symbol: "rosette",
            features: [
                ("calendar.badge.clock", "Weekly Review"),
                ("star.fill", "Badges"),
                ("square.stack.3d.up.fill", "Collections")
            ]
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                OnboardingTopBar(
                    currentPage: currentPage,
                    totalPages: pages.count
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                OnboardingBottomBar(
                    currentPage: currentPage,
                    totalPages: pages.count,
                    actionTitle: currentPage == pages.count - 1 ? "Get Started" : "Next",
                    onAction: advance
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private func advance() {
        FeedbackService.lightTap()
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        } else {
            FeedbackService.success()
            store.completeOnboarding()
        }
    }
}

private struct OnboardingPage {
    let headline: String
    let description: String
    let symbol: String
    let features: [(symbol: String, title: String)]
}

private struct OnboardingTopBar: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Quick Tour")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            Spacer()

            Text("\(currentPage + 1)/\(totalPages)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppBackground"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(DepthGradients.chip)
                )
        }
        .padding(16)
        .glassCard(elevation: .flat)
    }
}

private struct OnboardingBottomBar: View {
    let currentPage: Int
    let totalPages: Int
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentPage
                                ? DepthGradients.primaryButton
                                : LinearGradient(
                                    colors: [
                                        Color("AppTextSecondary").opacity(0.35),
                                        Color("AppTextSecondary").opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }

            Button(action: onAction) {
                Text(actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .glassCard(accentLeading: true, elevation: .raised)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                OnboardingHeroOrb(symbolName: page.symbol)
                    .scaleEffect(appeared ? 1 : 0.82)
                    .opacity(appeared ? 1 : 0)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(page.headline)
                            .font(.title.bold())
                            .foregroundStyle(Color("AppTextPrimary"))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.35)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                            .frame(maxWidth: 72)
                    }

                    Text(page.description)
                        .font(.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(Array(page.features.enumerated()), id: \.offset) { _, feature in
                            OnboardingFeatureTile(symbol: feature.symbol, title: feature.title)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(accentLeading: true)
                .offset(y: appeared ? 0 : 18)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

private struct OnboardingHeroOrb: View {
    let symbolName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color("AppPrimary").opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.35), Color("AppAccent").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 196, height: 196)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AppSurface"), Color("AppBackground").opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 168, height: 168)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .overlay(alignment: .topLeading) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AppTextPrimary").opacity(0.12), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: 88, height: 88)
                            .offset(x: 18, y: 14)
                            .allowsHitTesting(false)
                    }

                IconBadgeView(symbolName: symbolName, size: 84)
            }
            .compositingGroup()
            .shadow(color: Color("AppBackground").opacity(0.32), radius: 10, y: 5)
        }
        .frame(height: 230)
    }
}

private struct OnboardingFeatureTile: View {
    let symbol: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            IconBadgeView(symbolName: symbol, size: 34, filled: false)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.28),
                            Color("AppSurface").opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.16), lineWidth: 1)
                )
        )
    }
}
