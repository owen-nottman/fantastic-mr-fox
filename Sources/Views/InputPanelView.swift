import SwiftUI

/// The floating input panel — text field, optional window attachment preview, and send button.
///
/// Layout (top to bottom):
/// 1. Window attachment row (only visible when a window is selected)
/// 2. Input row: attach button | text field | send button
struct InputPanelView: View {
    @Bindable var store: FoxStore
    @FocusState private var textFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // --- Window attachment preview ---
            if let thumbnail = store.selectedWindowThumbnail {
                HStack(spacing: 8) {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("Window attached")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        store.clearSelectedWindow()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }

            // --- Text field row ---
            HStack(spacing: 10) {
                // Attach window button — opens the window picker sheet
                Button {
                    store.openWindowPicker()
                } label: {
                    Image(systemName: "macwindow")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .help("Attach a window")
                // The window picker is a sheet on this button so it anchors near the panel
                .sheet(isPresented: $store.showWindowPicker) {
                    WindowPickerView(store: store)
                }

                // Text input
                TextField("Ask FoxBuddy...", text: $store.promptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($textFocused)
                    .onSubmit { store.submit() }

                // Send button
                Button {
                    store.submit()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(store.promptText.isEmpty ? AnyShapeStyle(.tertiary) : AnyShapeStyle(Color.accentColor))
                }
                .buttonStyle(.plain)
                .disabled(store.promptText.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 8)
        .onAppear { textFocused = true }
        .onKeyPress(.escape) {
            store.closeInputPanel()
            return .handled
        }
    }
}
