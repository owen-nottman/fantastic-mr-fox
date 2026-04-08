import SwiftUI

/// A sheet that shows all open windows as clickable thumbnail cards.
/// Mirrors the Claude desktop "Add from screen" attachment flow.
struct WindowPickerView: View {
    let store: FoxStore

    // Adaptive grid: 3 columns on wide sheets, 2 on narrow
    private let columns = [GridItem(.adaptive(minimum: 170, maximum: 210), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                Text("Select a Window")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    store.showWindowPicker = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider()

            // Content area
            Group {
                if store.isLoadingWindows {
                    loadingView
                } else if store.availableWindows.isEmpty {
                    emptyView
                } else {
                    windowGrid
                }
            }
        }
        .frame(width: 620, height: 460)
        .background(.background)
    }

    // MARK: - Sub-views

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading windows…")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "macwindow.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No windows available")
                .foregroundStyle(.secondary)
            Text("Open an app first, then try again.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var windowGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.availableWindows) { info in
                    WindowThumbnailCard(info: info) {
                        store.selectWindow(info)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Window Thumbnail Card

/// One card in the window picker grid: screenshot thumbnail + app/window name.
struct WindowThumbnailCard: View {
    let info: WindowInfo
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail — fixed height, preserves aspect ratio
                Image(nsImage: info.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 108)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
                    )

                // App name + window title
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.appName)
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if info.windowTitle != info.appName {
                        Text(info.windowTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
