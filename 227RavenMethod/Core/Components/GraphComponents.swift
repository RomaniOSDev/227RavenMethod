import SwiftUI
import UIKit

struct StoredPhotoView: View {
    let data: Data?
    let styleIndex: Int
    let symbolName: String

    var body: some View {
        Group {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                MediaThumbnailView(styleIndex: styleIndex, symbolName: symbolName)
            }
        }
    }
}

struct CollectionCoverView: View {
    let styleIndex: Int
    let itemCount: Int

    var body: some View {
        ZStack {
            MediaThumbnailView(styleIndex: styleIndex, symbolName: "folder.fill")
            Canvas { context, size in
                let barWidth = size.width * 0.55
                let barHeight: CGFloat = 6
                let x = (size.width - barWidth) / 2
                let y = size.height * 0.72
                let rect = CGRect(x: x, y: y, width: barWidth * min(1, CGFloat(itemCount) / 8), height: barHeight)
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color("AppTextPrimary")))
            }
        }
    }
}

struct LinkPickerSection: View {
    let title: String
    let options: [(id: String, label: String)]
    @Binding var selectedID: String?

    var body: some View {
        if !options.isEmpty {
            Section(title) {
                Picker(title, selection: Binding(
                    get: { selectedID ?? "" },
                    set: { newValue in
                        selectedID = newValue.isEmpty ? nil : newValue
                    }
                )) {
                    Text("None").tag("")
                    ForEach(options, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .foregroundStyle(Color("AppTextPrimary"))
            }
        }
    }
}

struct HeatmapGridView: View {
    let stats: [ActivityDayStat]

    private var maxCount: Int {
        max(stats.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(stats) { stat in
                RoundedRectangle(cornerRadius: 4)
                    .fill(intensityColor(for: stat.count))
                    .frame(height: 28)
                    .overlay {
                        if stat.count > 0 {
                            Text("\(stat.count)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color("AppBackground"))
                        }
                    }
                    .accessibilityLabel(stat.date.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    private func intensityColor(for count: Int) -> Color {
        if count == 0 {
            return Color("AppSurface")
        }
        let ratio = Double(count) / Double(maxCount)
        if ratio > 0.66 {
            return Color("AppPrimary")
        }
        if ratio > 0.33 {
            return Color("AppAccent")
        }
        return Color("AppTextPrimary").opacity(0.35)
    }
}
