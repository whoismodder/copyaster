import SwiftUI

struct PanelView: View {
    @Bindable var state: AppState
    var onPaste: ((ClipboardItem) -> Void)? = nil
    @Namespace private var tabAnimation
    @State private var selectedIndex: Int = 0

    private var currentItems: [ClipboardItem] {
        state.selectedTab == .recents ? state.filteredRecents : state.filteredSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            tabBar
            Divider()
            contentList
            footer
        }
        .frame(width: 340, height: 440)
        .background(.ultraThinMaterial)
        .onAppear {
            state.selectedTab = .recents
            state.searchText = ""
            selectedIndex = 0
        }
        .onKeyPress(.downArrow) { move(1); return .handled }
        .onKeyPress(.upArrow) { move(-1); return .handled }
        .onKeyPress(.escape) { NSApp.keyWindow?.close(); return .handled }
        .onKeyPress(.tab) { switchTab(); return .handled }
    }

    // MARK: - Keyboard

    private func move(_ d: Int) {
        let c = currentItems.count
        guard c > 0 else { return }
        withAnimation(.easeOut(duration: 0.12)) {
            selectedIndex = max(0, min(c - 1, selectedIndex + d))
        }
    }

    private func selectCurrent() {
        guard selectedIndex < currentItems.count else { return }
        onPaste?(currentItems[selectedIndex])
    }

    private func switchTab() {
        withAnimation(.easeInOut(duration: 0.2)) {
            state.selectedTab = state.selectedTab == .recents ? .saved : .recents
            selectedIndex = 0
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.subheadline)
            TextField("Buscar...", text: $state.searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit { selectCurrent() }
                .accessibilityLabel("Buscar clips")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .onChange(of: state.searchText) { _, _ in selectedIndex = 0 }
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 4) {
            Spacer()
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.selectedTab = tab
                        selectedIndex = 0
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(state.selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(state.selectedTab == tab ? .primary : .tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background {
                            if state.selectedTab == tab {
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                                    .matchedGeometryEffect(id: "tab", in: tabAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    private var contentList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    switch state.selectedTab {
                    case .recents: recentsList
                    case .saved: savedList
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
                .animation(.easeInOut(duration: 0.2), value: state.selectedTab)
            }
            .onChange(of: selectedIndex) { _, i in
                withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(i, anchor: .center) }
            }
        }
    }

    private var recentsList: some View {
        Group {
            if state.filteredRecents.isEmpty {
                emptyState("Sin clips recientes", icon: "doc.on.clipboard")
            } else {
                ForEach(Array(state.filteredRecents.enumerated()), id: \.element.id) { i, item in
                    let saved = state.saved.first(where: { $0.content == item.content })
                    ClipRow(
                        item: item,
                        isSavedTab: false,
                        isCurrentClip: i == 0 && state.searchText.isEmpty,
                        savedTitle: saved?.title,
                        isKeyboardSelected: i == selectedIndex,
                        onSave: { t in withAnimation { state.saveItem(item, withTitle: t) } },
                        onDelete: { withAnimation { state.deleteRecent(item) } },
                        onCopy: { onPaste?(item) }
                    )
                    .id("recent-\(item.id)")
                }
            }
        }
    }

    private var savedList: some View {
        Group {
            if state.filteredSaved.isEmpty {
                emptyState("Sin clips guardados", icon: "bookmark")
            } else {
                ForEach(Array(state.filteredSaved.enumerated()), id: \.element.id) { i, item in
                    ClipRow(
                        item: item,
                        isSavedTab: true,
                        isCurrentClip: false,
                        isKeyboardSelected: i == selectedIndex,
                        onDelete: { withAnimation { state.deleteSaved(item) } },
                        onCopy: { onPaste?(item) },
                        onUpdateTitle: { t in state.updateTitle(for: item.id, title: t ?? "") }
                    )
                    .id("saved-\(item.id)")
                }
            }
        }
    }

    private func emptyState(_ text: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.quaternary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .accessibilityHidden(true)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 0) {
            Text("Copyaster")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.quaternary)
            Spacer()
            HStack(spacing: 6) {
                pill("↑↓")
                pill("⏎ copiar")
                pill("⇥ tab")
                pill(HotkeyOption.load().rawValue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .accessibilityHidden(true)
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
