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

> **Fonts**: During development, KaTeX fonts are loaded directly from
> `web/fonts/` in the repo (via `#file` path resolution at runtime).
> No extra setup needed.

## Step 3 — Run on device

Add KaTeX `.ttf` files to the Xcode target membership, then fonts load
from the app bundle automatically. See `platforms/ios/README.md` for the
full integration guide.

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
