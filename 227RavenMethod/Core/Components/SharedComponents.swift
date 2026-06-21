import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct SuccessCheckmarkOverlay: View {
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            if isShowing {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color("AppAccent"))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
    }
}

struct AppBackgroundView: View {
    var ignoresBottomSafeArea: Bool = true

    var body: some View {
        DepthAmbientBackground()
            .ignoresSafeArea(
                edges: ignoresBottomSafeArea ? .all : [.top, .horizontal]
            )
    }
}

extension View {
    func appNavigationChrome(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func appScreenContentPadding() -> some View {
        padding(.horizontal, 16)
            .padding(.bottom, 16)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Color("AppBackground"))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                DepthGradients.primaryButton
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AppTextPrimary").opacity(0.18), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
            .compositingGroup()
            .shadow(color: Color("AppBackground").opacity(0.32), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    FeedbackService.lightTap()
                }
            }
    }
}

struct SurfaceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .glassCard()
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCardModifier())
    }
}

struct MediaThumbnailView: View {
    let styleIndex: Int
    let symbolName: String

    private var gradientColors: [Color] {
        let palettes: [[Color]] = [
            [Color("AppPrimary"), Color("AppAccent")],
            [Color("AppAccent"), Color("AppSurface")],
            [Color("AppPrimary"), Color("AppBackground")],
            [Color("AppSurface"), Color("AppPrimary")],
            [Color("AppAccent"), Color("AppBackground")],
            [Color("AppBackground"), Color("AppAccent")],
            [Color("AppPrimary"), Color("AppSurface")],
            [Color("AppSurface"), Color("AppAccent")],
            [Color("AppAccent"), Color("AppPrimary")],
            [Color("AppBackground"), Color("AppPrimary")],
            [Color("AppPrimary"), Color("AppBackground")],
            [Color("AppSurface"), Color("AppBackground")]
        ]
        return palettes[styleIndex % palettes.count]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct AchievementBannerView: View {
    let achievement: AchievementDefinition

    var body: some View {
        HStack(spacing: 14) {
            IconBadgeView(symbolName: achievement.symbolName, size: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(achievement.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            Spacer()
        }
        .padding(16)
        .glassCard(accentLeading: true)
        .padding(.horizontal, 16)
    }
}

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            FeedbackService.lightTap()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(DepthGradients.primaryButton)
                    .frame(width: 58, height: 58)
                    .overlay(alignment: .topLeading) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AppTextPrimary").opacity(0.2), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: 30, height: 30)
                            .offset(x: 8, y: 6)
                            .allowsHitTesting(false)
                    }
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppBackground"))
            }
            .compositingGroup()
            .shadow(color: Color("AppBackground").opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
