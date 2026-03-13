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
        // 生产环境推荐：通过 SPM 集成时调用 RaTeXFontLoader.loadFromPackageBundle()
        // 字体已随包内置，一行搞定，无需下面的回退逻辑。
        //
        // 本 Demo 直接引用源文件（非 SPM），故依次尝试：
        // 1. App Bundle（手动把 TTF 加入 Xcode target 时生效）
        // 2. 仓库内字体目录（开发期回退，设备/App Store 不可用）

        let bundleLoaded = RaTeXFontLoader.loadFromBundle()
        if bundleLoaded > 0 {
            print("[RaTeX] Loaded \(bundleLoaded) fonts from bundle")
            return
        }

        // 开发回退：从仓库内 platforms/ios/Sources/RaTeX/Fonts/ 加载
        let devFontsPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()           // demo/ios/RaTeXDemo/RaTeXDemo/
            .deletingLastPathComponent()           // demo/ios/RaTeXDemo/
            .deletingLastPathComponent()           // demo/ios/
            .deletingLastPathComponent()           // demo/ → repo root
            .appendingPathComponent("platforms/ios/Sources/RaTeX/Fonts")

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
