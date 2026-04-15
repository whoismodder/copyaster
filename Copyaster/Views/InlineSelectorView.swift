import SwiftUI

struct InlineSelectorView: View {
    let recents: [ClipboardItem]
    let saved: [ClipboardItem]
    var selectedOverride: Int? = nil
    var onSelect: ((ClipboardItem) -> Void)?
    var onDismiss: (() -> Void)?

    @State private var selectedIndex: Int = 0

    private var sel: Int { selectedOverride ?? selectedIndex }
    private var total: Int { recents.count + saved.count }
    private var hasSep: Bool { !saved.isEmpty && !recents.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(Array(recents.enumerated()), id: \.element.id) { i, item in
                            row(item, index: i, isFirst: i == 0, isSaved: false).id(i)
                        }

                        if hasSep {
                            HStack(spacing: 8) {
                                Divider().frame(height: 1)
                                Text("Guardados")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.quaternary)
                                Divider().frame(height: 1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }

                        ForEach(Array(saved.enumerated()), id: \.element.id) { i, item in
                            let gi = recents.count + i
                            row(item, index: gi, isFirst: false, isSaved: true).id(gi)
                        }
                    }
                    .padding(6)
                }
                .onChange(of: sel) { _, v in
                    withAnimation(.easeOut(duration: 0.08)) { proxy.scrollTo(v, anchor: .center) }
                }
            }

            // Footer
            Divider()
            HStack {
                Text("Copyaster")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.quaternary)
                Spacer()
                HStack(spacing: 6) {
                    pill("↑↓")
                    pill("⏎ copiar")
                    pill("⌘V pegar")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .accessibilityHidden(true)
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: 360)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    // MARK: - Row

    private func row(_ item: ClipboardItem, index: Int, isFirst: Bool, isSaved: Bool) -> some View {
        let active = index == sel

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                // Selection indicator
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(active ? Color.primary.opacity(0.3) : .clear)
                    .frame(width: 3, height: 18)

                VStack(alignment: .leading, spacing: 2) {
                    if isSaved, let title = item.title, !title.isEmpty {
                        Text(title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    clipText(item, active: active)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if active {
                    Text("⏎")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)

            if isFirst && !isSaved {
                Text("Listo para pegar")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 21)
                    .padding(.bottom, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(active ? Color.primary.opacity(0.06) : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect?(item) }
        .onHover { h in if h && selectedOverride == nil { selectedIndex = index } }
    }

    @ViewBuilder
    private func clipText(_ item: ClipboardItem, active: Bool) -> some View {
        switch item.content {
        case .text(let s):
            Text(s.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.callout)
                .lineLimit(2)
                .foregroundStyle(active ? .primary : .secondary)
        case .image:
            Label("Imagen", systemImage: "photo")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func pill(_ t: String) -> some View {
        Text(t)
            .font(.caption2)
            .foregroundStyle(.quaternary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
