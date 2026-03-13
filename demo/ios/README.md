# RaTeX iOS Demo

SwiftUI app that renders a list of LaTeX formulas using RaTeX + CoreGraphics (no WebView).

## Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 15+ |
| Rust | 1.75+ (`rustup`) |
| iOS Simulator or device | iOS 14+ |

Install Rust iOS targets once:

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

## Step 1 — Build the XCFramework

From the **repo root**:

```bash
bash platforms/ios/build-ios.sh
```

This compiles the Rust engine for all iOS targets and produces
`platforms/ios/RaTeX.xcframework`.

## Step 2 — Open in Xcode

```bash
open demo/ios/RaTeXDemo/RaTeXDemo.xcodeproj
```

Select an iPhone simulator and press **Run (⌘R)**.

> **Fonts**: During development, KaTeX fonts are loaded from
> `platforms/ios/Sources/RaTeX/Fonts/` via `#file` path resolution at runtime.
> No extra setup needed.

## Step 3 — Run on device

The demo falls back to the repo font path at runtime, which only works in the
Simulator or when running from source. For a real device build, add the `.ttf`
files from `platforms/ios/Sources/RaTeX/Fonts/` to the Xcode target membership.

> **Note**: Apps integrating via Swift Package Manager don't need any of this —
> just call `RaTeXFontLoader.loadFromPackageBundle()` once at startup and fonts
> are loaded automatically from the package bundle.

## Project structure

```
demo/ios/RaTeXDemo/
├── RaTeXDemo.xcodeproj/     # Xcode project
└── RaTeXDemo/
    ├── RaTeXDemoApp.swift   # App entry point, font loading
    └── ContentView.swift    # Formula list UI
```

The library sources live in `platforms/ios/Sources/RaTeX/` and are
referenced by the Xcode project via relative paths — no copying needed.
