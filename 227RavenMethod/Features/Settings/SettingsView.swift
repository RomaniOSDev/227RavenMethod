import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var showResetAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(ignoresBottomSafeArea: false)

                ScrollView {
                    VStack(spacing: 16) {
                        statsCard

                        VStack(spacing: 0) {
                            Button {
                                FeedbackService.lightTap()
                                rateApp()
                            } label: {
                                SettingsMenuRow(title: "Rate Us", symbol: "star.fill")
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color("AppTextSecondary").opacity(0.15)).padding(.leading, 62)

                            Button {
                                openLink(.privacyPolicy)
                            } label: {
                                SettingsMenuRow(title: "Privacy", symbol: "hand.raised.fill")
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color("AppTextSecondary").opacity(0.15)).padding(.leading, 62)

                            Button {
                                openLink(.termsOfService)
                            } label: {
                                SettingsMenuRow(title: "Terms", symbol: "doc.text.fill")
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color("AppTextSecondary").opacity(0.15)).padding(.leading, 62)

                            Button {
                                FeedbackService.lightTap()
                                showResetAlert = true
                            } label: {
                                SettingsMenuRow(title: "Reset All Data", symbol: "trash.fill", destructive: true, showsChevron: false)
                            }
                            .buttonStyle(.plain)
                        }
                        .glassCard()

                        Text("Version \(appVersion)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .appScreenContentPadding()
                }
                .scrollContentBackground(.hidden)
            }
            .appNavigationChrome("Settings")
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { FeedbackService.lightTap() }
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                    FeedbackService.warning()
                }
            } message: {
                Text("This will permanently delete all your entries, favorites, and progress.")
            }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderView(title: "Statistics", subtitle: "Your activity at a glance")
            HStack(spacing: 10) {
                MetricTileView(value: "\(store.totalEntriesCreated)", title: "Entries")
                MetricTileView(value: "\(store.reviewsCompleted)", title: "Reviews")
                MetricTileView(value: "\(store.graphLinks.count)", title: "Links")
            }
            HStack(spacing: 10) {
                MetricTileView(value: "\(store.totalMinutesUsed)", title: "Minutes")
                MetricTileView(value: "\(store.streakDays)d", title: "Streak")
                MetricTileView(value: "\(store.collections.count)", title: "Sets")
            }
        }
        .padding(16)
        .glassCard(accentLeading: true)
    }

    private func openLink(_ link: AppLinks) {
        FeedbackService.lightTap()
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
