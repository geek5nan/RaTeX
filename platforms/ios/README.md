# RaTeX — iOS Integration Guide

Native iOS rendering of LaTeX math formulas via Swift and CoreGraphics.
No WebView, no JavaScript, no DOM.

---

## How it works

```
LaTeX string
    ↓ ratex_parse_and_layout() [C ABI, static lib]
JSON DisplayList
    ↓ RaTeXEngine.parse()       [Swift JSON decode]
DisplayList
    ↓ RaTeXRenderer.draw()      [CoreGraphics]
UIView / SwiftUI View
```

---

## Out of the box

1. **Add dependency** — In Xcode: **File → Add Package Dependencies**, enter the repo URL `https://github.com/erweixin/RaTeX`, select the `RaTeX` library.
2. **Use** — Use `RaTeXView` or `RaTeXFormula`; fonts load automatically on first render.
   ```swift
   // SwiftUI
   RaTeXFormula(latex: #"\frac{-b \pm \sqrt{b^2-4ac}}{2a}"#, fontSize: 24)
   ```
   **Optional:** To preload fonts at startup (e.g. to avoid slight delay on first formula), call `RaTeXFontLoader.loadFromPackageBundle()` when the app launches.

**Local development** (when editing RaTeX source): From the repo root run `bash platforms/ios/build-ios.sh`, then in Xcode **File → Add Package Dependencies → Add Local…** and select the RaTeX repo root.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 15+ |
| Rust | 1.75+ (`rustup`) |
| iOS target | 14+ |

Install Rust iOS targets once:

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

---

## Build the XCFramework

From the repo root:

```bash
bash platforms/ios/build-ios.sh
```

This produces `platforms/ios/RaTeX.xcframework`.

---

## Add to your Xcode project

### Option A — Swift Package Manager (recommended)

**Published release** — In Xcode: **File → Add Package Dependencies**, enter
the GitHub repo URL and select the `RaTeX` product. Fonts load automatically on first render; optionally call `RaTeXFontLoader.loadFromPackageBundle()` at startup to load earlier.

**Local development** — After building the XCFramework, point Xcode to the
repo root (`File → Add Package Dependencies → Add Local…`).

### Option B — Manual

1. Drag `platforms/ios/RaTeX.xcframework` into your Xcode project.
2. In **Build Phases → Link Binary With Libraries**, ensure it is listed.
3. Copy the `platforms/ios/Sources/RaTeX/*.swift` files into your project.
4. Add the `Fonts` folder from `platforms/ios/Sources/Ratex/Fonts/` to your target’s **Copy Bundle Resources**; fonts load automatically on first render, or call `RaTeXFontLoader.loadFromBundle()` at startup.

---

## Usage

### UIKit

```swift
import RaTeX

let mathView = RaTeXView()
mathView.latex    = #"\frac{-b \pm \sqrt{b^2-4ac}}{2a}"#
mathView.fontSize = 28
mathView.onError  = { print("RaTeX error:", $0) }

// Auto-sizing
mathView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(mathView)
NSLayoutConstraint.activate([
    mathView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    mathView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
])
```

### SwiftUI

```swift
import RaTeX

struct ContentView: View {
    var body: some View {
        RaTeXFormula(
            latex: #"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#,
            fontSize: 24
        )
        .padding()
    }
}
```

### Low-level (custom drawing)

```swift
import RaTeX

let displayList = try RaTeXEngine.shared.parse(#"\sum_{n=1}^\infty \frac{1}{n^2}"#)
let renderer    = RaTeXRenderer(displayList: displayList, fontSize: 20)

// In your UIView.draw(_:) or CGContext block:
renderer.draw(in: UIGraphicsGetCurrentContext()!)
```

---

## Coordinate system

All `DisplayList` coordinates are in **em units**. `RaTeXRenderer` multiplies them
by `fontSize` (pt) to produce screen coordinates.

- X increases rightward from the left edge.
- Y increases downward from the top edge.
- Baseline is at Y = `height × fontSize`.

---

## File map

| File | Purpose |
|------|---------|
| `build-ios.sh` | Build script → `RaTeX.xcframework` |
| `Package.swift` | Swift Package manifest |
| `Sources/RaTeX/DisplayList.swift` | Codable Swift mirror of Rust types |
| `Sources/RaTeX/RaTeXEngine.swift` | Calls C ABI, decodes JSON |
| `Sources/RaTeX/RaTeXRenderer.swift` | CoreGraphics drawing loop |
| `Sources/RaTeX/RaTeXView.swift` | UIKit `UIView` + SwiftUI `View` |
