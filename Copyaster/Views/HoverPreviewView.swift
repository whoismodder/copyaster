import SwiftUI

struct HoverPreviewView: View {
    let item: ClipboardItem?

    var body: some View {
        Group {
            if let item {
                content(item)
            } else {
                Text("Clipboard vacío")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(width: 260, alignment: .leading)
    }

    @ViewBuilder
    private func content(_ item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            switch item.content {
            case .text(let s):
                Text(s.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.callout)
                    .lineLimit(4)
                    .foregroundStyle(.primary)
            case .image(let data):
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Text("Copiado \(item.timeAgo)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
