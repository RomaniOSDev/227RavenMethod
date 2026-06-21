import SwiftUI

enum CardElevation {
    case flat
    case standard
    case raised

    var shadowOpacity: Double {
        switch self {
        case .flat: return 0
        case .standard: return 0.28
        case .raised: return 0.36
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .flat: return 0
        case .standard: return 6
        case .raised: return 10
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .flat: return 0
        case .standard: return 3
        case .raised: return 6
        }
    }
}

struct DepthCardSurface: View {
    var cornerRadius: CGFloat = 18
    var elevation: CardElevation = .standard

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        shape
            .fill(
                LinearGradient(
                    colors: [
                        Color("AppSurface"),
                        Color("AppBackground").opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color("AppTextPrimary").opacity(0.14),
                            Color("AppPrimary").opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .overlay(alignment: .top) {
                shape
                    .fill(
                        LinearGradient(
                            colors: [Color("AppTextPrimary").opacity(0.07), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
            .modifier(DepthShadowModifier(elevation: elevation))
    }
}

private struct DepthShadowModifier: ViewModifier {
    let elevation: CardElevation

    func body(content: Content) -> some View {
        if elevation == .flat {
            content
        } else {
            content
                .compositingGroup()
                .shadow(
                    color: Color("AppBackground").opacity(elevation.shadowOpacity),
                    radius: elevation.shadowRadius,
                    y: elevation.shadowY
                )
        }
    }
}

struct DepthAmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("AppBackground"), Color("AppSurface")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color("AppPrimary").opacity(0.14), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -100, y: -160)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color("AppAccent").opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: 140, y: 320)

            DepthDotPattern()
                .opacity(0.1)
        }
    }
}

private struct DepthDotPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 44
            var x: CGFloat = spacing / 2
            while x < size.width {
                var y: CGFloat = spacing / 2
                while y < size.height {
                    let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color("AppTextPrimary")))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

enum DepthGradients {
    static var primaryButton: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var chip: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var tabBar: LinearGradient {
        LinearGradient(
            colors: [Color("AppSurface"), Color("AppBackground").opacity(0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
