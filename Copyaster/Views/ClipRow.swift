import SwiftUI

struct ClipRow: View {
    let item: ClipboardItem
    let isSavedTab: Bool
    let isCurrentClip: Bool
    var savedTitle: String? = nil
    var isKeyboardSelected: Bool = false
    var isMultiSelected: Bool = false

    var onSave: ((String?) -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onMultiSelect: (() -> Void)? = nil
    var onUpdateTitle: ((String?) -> Void)? = nil

    @State private var isHovered = false
    @State private var isSaving = false
    @State private var editTitle: String = ""
    @State private var showSavedFeedback = false
    @State private var showNotesFeedback = false

    private static let animDuration: Double = 0.2
    private static let emojis = ["📌", "⭐", "🔑", "📋", "💡", "🔗", "📎", "🏷️", "✅", "🚀", "💬", "📝", "🎯", "⚡", "🔒", "📁"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main row
            HStack(alignment: .center, spacing: 10) {
                contentArea
                Spacer(minLength: 0)
                if !isSaving && !showSavedFeedback && !showNotesFeedback && isHovered {
                    actionArea
                }
            }

            // Subtitle: "Listo para pegar" / feedback
            if isCurrentClip && !isSavedTab && !isSaving && !showSavedFeedback && !showNotesFeedback {
                subtitleBar
            }
            if showSavedFeedback { feedbackLabel("checkmark.circle", "Guardado") }
            if showNotesFeedback { feedbackLabel("note.text", "Enviado a Notas") }

            // Save form
            if isSaving {
                saveForm
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            if NSApp.currentEvent?.modifierFlags.contains(.command) == true {
                onMultiSelect?()
            } else {
                onCopy?()
            }
        }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: Self.animDuration), value: isSaving)
        .animation(.easeInOut(duration: Self.animDuration), value: showSavedFeedback)
        .animation(.easeInOut(duration: Self.animDuration), value: showNotesFeedback)
    }

    // MARK: - Subtitle

    private var subtitleBar: some View {
        HStack(spacing: 5) {
            Text("Listo para pegar")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if let savedTitle, !savedTitle.isEmpty {
                Text("·").font(.caption2).foregroundStyle(.quaternary)
                Text(savedTitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func feedbackLabel(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption2)
        }
        .foregroundStyle(.tertiary)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Background

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(bgColor)
    }

    private var bgColor: Color {
        if isMultiSelected { return Color.accentColor.opacity(0.1) }
        if isKeyboardSelected { return Color.primary.opacity(0.08) }
        if isCurrentClip && !isSavedTab { return Color.primary.opacity(0.05) }
        if isHovered { return Color.primary.opacity(0.03) }
        return .clear
    }

    // MARK: - Content

    private var contentArea: some View {
        HStack(spacing: 8) {
            if isMultiSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .transition(.scale.combined(with: .opacity))
            }
            VStack(alignment: .leading, spacing: 3) {
            if isSavedTab, let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            contentPreview
            if !isSaving && !showSavedFeedback && !showNotesFeedback {
                Text(isSavedTab ? item.savedDateString : item.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.easeInOut(duration: 0.15), value: isMultiSelected)
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.content {
        case .text(let s):
            Text(s.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.callout)
                .lineLimit(3)
                .foregroundStyle(isSavedTab ? .secondary : .primary)
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    // MARK: - Actions (44pt hit targets)

    private var actionArea: some View {
        HStack(spacing: 4) {
            if !isSavedTab {
                actionButton(icon: "plus.circle.fill", hint: "Guardar") {
                    isSaving = true
                }
            } else {
                actionButton(icon: "pencil", hint: "Editar título") {
                    editTitle = item.title ?? ""
                    isSaving = true
                }
                actionButton(icon: "note.text", hint: "Guardar en Notas") {
                    sendToAppleNotes()
                }
            }
            actionButton(icon: "xmark.circle", hint: "Borrar") {
                withAnimation(.easeOut(duration: Self.animDuration)) { onDelete?() }
            }
        }
        .transition(.opacity.animation(.easeIn(duration: 0.12)))
    }

    private func actionButton(icon: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .frame(width: 32, height: 32)        // Visual size
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 36, height: 36)                // Hit target ≥ 36pt (macOS HIG)
        .help(hint)
    }

    // MARK: - Save form

    private var saveForm: some View {
        HStack(spacing: 8) {
            // Emoji menu
            Menu {
                ForEach(Self.emojis, id: \.self) { emoji in
                    Button(emoji) { editTitle = emoji + " " + editTitle }
                }
            } label: {
                Text("☺")
                    .font(.callout)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)

            TextField("Título...", text: $editTitle)
                .textFieldStyle(.plain)
                .font(.callout)
                .onSubmit { confirmSave() }

            Button { confirmSave() } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())

            Button { cancelSave() } label: {
                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Save logic

    private func confirmSave() {
        let title = editTitle.isEmpty ? nil : editTitle
        withAnimation { isSaving = false }

        if isSavedTab {
            onUpdateTitle?(title)
        } else {
            onSave?(title)
            withAnimation { showSavedFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showSavedFeedback = false }
            }
        }
        editTitle = ""
    }

    private func cancelSave() {
        withAnimation { isSaving = false }
        editTitle = ""
    }

    // MARK: - Apple Notes

    private func sendToAppleNotes() {
        guard let text = item.content.fullText else { return }
        let noteTitle = item.title ?? "Copyaster"

        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: "\"", with: "\\\"")
             .replacingOccurrences(of: "\n", with: "\\n")
             .replacingOccurrences(of: "\r", with: "\\r")
        }

        let script = "tell application \"Notes\" to make new note with properties {name:\"\(esc(noteTitle))\", body:\"\(esc(text))\"}"

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try? process.run()
            process.waitUntilExit()

            let success = process.terminationStatus == 0

            DispatchQueue.main.async {
                if success {
                    withAnimation { showNotesFeedback = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showNotesFeedback = false }
                    }
                }
            }
        }
    }
}
