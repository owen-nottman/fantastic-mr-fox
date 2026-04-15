import SwiftUI
import AppKit

// MARK: - Animated GIF via NSImageView

/// Wraps an NSImageView so SwiftUI can display looping animated GIFs.
struct AnimatedGIFView: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView(image: image)
        view.animates = true
        view.imageScaling = .scaleProportionallyUpOrDown
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if nsView.image !== image {
            nsView.image = image
        }
    }
}

// MARK: - GIF loader

/// Preloads fox GIF frames from Resources/Animations/ at launch.
/// File names use underscores: fox_idle.gif, fox_thinking.gif, fox_speaking.gif.
final class FoxGIFLibrary {
    static let shared = FoxGIFLibrary()
    private init() {}

    let idle      = NSImage.foxGIF(named: "fox_idle")
    let thinking  = NSImage.foxGIF(named: "fox_thinking")
    let speaking  = NSImage.foxGIF(named: "fox_speaking")
    let sleeping  = NSImage.foxGIF(named: "fox_sleeping")
    let stretching = NSImage.foxGIF(named: "fox_stretch")

    var hasGIFs: Bool { idle != nil }

    func image(for state: FoxState) -> NSImage? {
        switch state {
        case .idle, .capturing, .awaitingInput, .error: return idle
        case .sleeping:                                  return sleeping ?? idle
        case .stretching:                                return stretching ?? idle
        case .thinking:                                  return thinking ?? idle
        case .speaking:                                  return speaking ?? idle
        }
    }
}

private extension NSImage {
    static func foxGIF(named name: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "gif",
                                          subdirectory: "Animations") else { return nil }
        return NSImage(contentsOf: url)
    }
}

// MARK: - FoxMascotView

/// The fox that floats on-screen.
/// Shows an animated GIF if fox_idle.gif is present in Resources/Animations/,
/// otherwise renders the fox emoji with hover + bounce animations.
struct FoxMascotView: View {
    let store: KitStore

    @State private var isHovered = false

    private let gifs = FoxGIFLibrary.shared

    var body: some View {
        Group {
            if gifs.hasGIFs, let image = gifs.image(for: store.foxState) {
                AnimatedGIFView(image: image)
                    .frame(width: 180, height: 180)
            } else {
                Text("🦊")
                    .font(.system(size: 52))
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            }
        }
        .scaleEffect(isHovered ? 1.12 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { store.trigger() }
        .help("Tap or press ⌥F to ask Kit")
    }
}
