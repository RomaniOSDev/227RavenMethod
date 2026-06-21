import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStorage.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSuccessCheckmark = false

    var body: some View {
        ZStack {
            Group {
                if store.hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)

            SuccessCheckmarkOverlay(isShowing: $showSuccessCheckmark)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            store.beginSessionIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                store.beginSessionIfNeeded()
            case .background:
                store.endSession()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}
