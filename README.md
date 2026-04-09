# 🦊 FoxBuddy

A Clippy-style fox mascot that floats on your desktop, watches your screen,
and reacts with speech bubbles powered by Claude vision — without ever
switching apps or stealing focus.

## The problem it solves

You want to ask Claude about what's on your screen right now, but
Option+Option opens the Claude desktop app and yanks you away from
whatever you were doing. FoxBuddy stays in-place: press Option+F from
anywhere, the fox enters capture mode, you pick what to share, type your
question, and a speech bubble appears — all without leaving your current app.

## How it works

```
Option+F  →  capture mode  →  pick region / window / full screen
          →  type a message (optional)  →  Claude vision API  →  speech bubble
```

The fox lives in your menu bar and floats above all windows on every Space,
including full-screen apps. It never activates or steals keyboard focus.

### Capture modes

| Mode | How to trigger | Framework |
|---|---|---|
| **Drag a region** | Click & drag a rectangle on screen | ScreenCaptureKit |
| **Click a window** | Click any visible window in the picker | ScreenCaptureKit (`SCShareableContent`) |
| **Full screen** | Press Escape / tap fox without selecting | `CGDisplayCreateImage` (fast path) |

This mirrors the capture experience in the Claude desktop app's opt+opt quick entry:
drag a region or click a window, then type your question alongside the screenshot.

---

## Project Structure

```
FoxBuddy/
├── Package.swift
└── Sources/
    ├── App/
    │   ├── FoxBuddyApp.swift            @main entry — menu bar only, no Dock icon
    │   └── AppDelegate.swift            wires overlay + hotkey + permissions
    ├── Models/
    │   ├── FoxState.swift               idle / capturing / thinking / speaking / error
    │   ├── ClaudeMessage.swift          Encodable request + Decodable response types
    │   ├── SpeechBubble.swift           bubble model with auto-dismiss timer
    │   └── CaptureMode.swift            CaptureResult type (image + frame)
    ├── Services/
    │   ├── ClaudeAPIService.swift       vision API call → response string
    │   ├── ScreenCaptureService.swift   SCK window/region capture + CGDisplay full screen
    │   ├── HotkeyService.swift          Carbon global hotkey (Option+F)
    │   └── PermissionService.swift      triggers Screen Recording dialog on launch
    ├── Stores/
    │   └── FoxStore.swift               @Observable state machine, owns trigger flow
    ├── Views/
    │   ├── OverlayWindowController.swift  NSPanel — floating, non-activating
    │   ├── FoxOverlayView.swift           root SwiftUI (fox + bubble)
    │   ├── FoxMascotView.swift            fox emoji/animation + tap-to-trigger
    │   ├── CaptureOverlayView.swift       full-screen drag-to-select + window picker
    │   ├── MessageInputView.swift         text field + send button, anchored to capture
    │   └── SpeechBubbleView.swift         rounded callout bubble with tail, tap-to-dismiss
    ├── Utilities/
    │   └── NSImage+PNG.swift             NSImage → compressed PNG Data for API
    └── Resources/
        ├── Info.plist                    LSUIElement=true hides from Dock
        └── Animations/                  drop fox-idle.mov, fox-thinking.mov here
```

---

## Setup

### 1. Clone & open

```bash
git clone <your-repo>
cd FoxBuddy
open Package.swift
```

### 2. Set your API key

```bash
# ~/.zshrc or ~/.zprofile
export ANTHROPIC_API_KEY=sk-ant-api03-...
```

For Xcode runs: Edit Scheme → Run → Arguments → Environment Variables → add `ANTHROPIC_API_KEY`.

### 3. Build & run

```bash
swift build && swift run
```

### 4. Grant permissions

System Settings → Privacy & Security:
- **Screen Recording** — required for all capture modes
- **Accessibility** — required for the window picker UI

### 5. Use it

1. Press **Option+F** from any app — the screen dims and enters capture mode
2. **Drag** to select a region, or **click** any window to capture it
   (Press Escape or tap the fox to skip selection and use full-screen)
3. A message input bar appears anchored to your selection
4. Type your question (or leave blank to let the fox react freely)
5. Press Return — the fox thinks, then pops up a speech bubble
6. Tap the bubble or wait 8s to dismiss

---

## Message input + capture flow

The message input bar works like the Claude desktop app's quick entry overlay:
the screenshot is attached automatically, and you type your question alongside it.

```swift
// FoxStore.swift — the trigger flow
func trigger() async {
    state = .capturing

    // 1. Show capture overlay (CaptureOverlayView) — dims screen,
    //    lets user drag a region or click a window via SCShareableContent
    let captureResult = await CaptureOverlayController.present()

    // 2. Show message input bar anchored to the captured region
    let message = await MessageInputController.present(near: captureResult.frame)

    state = .thinking

    // 3. Send screenshot + message to Claude
    let response = try await ClaudeAPIService.shared.ask(
        prompt: message,
        image: captureResult.image
    )

    state = .speaking(response)
}
```

### ScreenCaptureKit window picker

`SCShareableContent` enumerates all on-screen windows without needing the
user to alt-tab or name an app. This is the same API that powers the
Claude desktop app's "click a window" capture mode.

```swift
// ScreenCaptureService.swift — window list + per-window capture
import ScreenCaptureKit

func availableWindows() async throws -> [SCWindow] {
    let content = try await SCShareableContent.excludingDesktopWindows(
        false, onScreenWindowsOnly: true
    )
    return content.windows.filter { $0.title != nil }
}

func capture(window: SCWindow) async throws -> NSImage {
    let filter  = SCContentFilter(desktopIndependentWindow: window)
    let config  = SCScreenshotConfiguration()
    config.scalesToFit = false
    let cgImage = try await SCScreenshotManager.captureImage(
        contentFilter: filter, configuration: config
    )
    return NSImage(cgImage: cgImage, size: .zero)
}
```

### Region capture overlay

`CaptureOverlayView` is a full-screen transparent `NSPanel` (non-activating,
above all windows) that draws a dimmed overlay and tracks a drag gesture to
produce the selected rect — just like macOS's own ⇧⌘4 crosshair tool.

```swift
// CaptureOverlayView.swift (sketch)
// On mouseDown: record startPoint
// On mouseDragged: draw selection rect, update live preview
// On mouseUp: call SCScreenshotManager with an SCContentFilter(display:,
//             contentRect:, contentScale:) covering the dragged rect
```

### Claude API call with a message

```swift
// ClaudeAPIService.swift
func analyze(image: NSImage, message: String?) async throws -> String {
    let userText = message?.isEmpty == false
        ? message!
        : "What's happening on my screen? React as FoxBuddy."

    let body: [String: Any] = [
        "model": model,  // e.g. "claude-sonnet-4-6"
        "max_tokens": 300,
        "system": systemPrompt,
        "messages": [[
            "role": "user",
            "content": [
                ["type": "image",
                 "source": ["type": "base64",
                            "media_type": "image/png",
                            "data": image.pngBase64()]],
                ["type": "text", "text": userText]
            ]
        ]]
    ]
    // ... URLSession call, decode response
}
```

---

## Customization

### Change the hotkey

In `HotkeyService.swift`, change `kVK_ANSI_F` and `optionKey`.

### Change the fox's personality

In `ClaudeAPIService.swift`, edit `systemPrompt`.

### Choose a model

FoxBuddy defaults to **`claude-sonnet-4-6`**, which balances speed and
intelligence — ideal for a low-latency overlay. Edit the `model` constant
in `ClaudeAPIService.swift`:

| Model | API string | Best for |
|---|---|---|
| Sonnet 4.6 *(default)* | `claude-sonnet-4-6` | Fast, balanced, recommended |
| Opus 4.6 | `claude-opus-4-6` | Maximum capability, higher cost |
| Haiku 4.5 | `claude-haiku-4-5-20251001` | Fastest & cheapest, simpler reactions |

All current Claude models support vision (image input) with no extra configuration.
See [Anthropic's models overview](https://docs.anthropic.com/en/docs/about-claude/models/overview) for the latest list.

### Skip the message input

To go back to the original one-shot behaviour (screenshot → bubble, no typing),
remove the `MessageInputController.present()` call in `FoxStore.trigger()` and pass
`message: nil` directly to the API.

### Add a real fox animation (masko.ai)

1. Export your fox from masko.ai as transparent HEVC `.mov`
2. Drop `fox-idle.mov`, `fox-thinking.mov`, `fox-speaking.mov` into `Resources/Animations/`
3. Run `swift build` — FoxMascotView detects the files automatically and switches from emoji to video

---

## Architecture notes

**Why ScreenCaptureKit for window/region capture?**
SCK's `SCShareableContent` enumerates live windows by title and app, and
`SCContentFilter` lets you crop to an exact display rect or a single window —
the same approach the Claude desktop app uses for its opt+opt window picker.
`CGDisplayCreateImage` is kept as the fast-path for full-screen fallback (~5ms,
no async setup).

**Why `orderFront` not `makeKeyAndOrderFront`?**
`makeKeyAndOrderFront` steals keyboard focus — exactly the problem with Option+Option.
`orderFront(nil)` + `.nonactivatingPanel` makes the fox and capture overlay
visible without activating them.

**Why Carbon hotkeys?**
`NSEvent` global monitors need Accessibility permission. Carbon's `RegisterEventHotKey`
fires from any foreground app with no extra entitlement.

**Message input without focus stealing**
`MessageInputView` is hosted in the same non-activating `NSPanel` as the fox.
To accept keyboard input without making the panel key, call
`panel.makeFirstResponder(textField)` after `orderFront` — this works because
the panel is already on screen; it doesn't need to become the key window.

---

## Requirements

- macOS 14.0+ (Sonoma)
- Swift 5.9+ / Xcode 15+
- `ANTHROPIC_API_KEY` environment variable set
- Screen Recording permission (for all capture modes)
- Accessibility permission (for window picker UI)

## License

MIT
