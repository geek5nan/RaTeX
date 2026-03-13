import SwiftUI

@main
struct RaTeXDemoApp: App {

    init() {
        loadFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func loadFonts() {
        // 优先从 App Bundle 加载（生产环境：把 TTF 文件加入 Xcode 项目 target）
        let bundleLoaded = RaTeXFontLoader.loadFromBundle()
        if bundleLoaded > 0 {
            print("[RaTeX] Loaded \(bundleLoaded) fonts from bundle")
            return
        }

        // 开发期间回退：直接读取 web 平台的字体目录
        // 这个路径在真实设备/App Store 分发时不可用，需改为 bundle 方式
        let devFontsPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()           // demo/ios/RaTeXDemo/RaTeXDemo/
            .deletingLastPathComponent()           // demo/ios/RaTeXDemo/
            .deletingLastPathComponent()           // demo/ios/
            .deletingLastPathComponent()           // demo/ → repo root
            .appendingPathComponent("web/fonts")

        let devLoaded = RaTeXFontLoader.loadFromDirectory(devFontsPath)
        if devLoaded > 0 {
            print("[RaTeX] Loaded \(devLoaded) fonts from dev path: \(devFontsPath.path)")
        } else {
            print("[RaTeX] WARNING: No KaTeX fonts found. Glyphs may render as fallback.")
            print("[RaTeX]   Bundle path tried: \(Bundle.main.bundlePath)")
            print("[RaTeX]   Dev path tried: \(devFontsPath.path)")
        }
    }
}
