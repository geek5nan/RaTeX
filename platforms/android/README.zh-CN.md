# RaTeX — Android

Android 上原生渲染 LaTeX 数学公式（Kotlin + Canvas），AAR 内含 KaTeX 字体。  
minSdk 21，targetSdk 34。

## 环境

NDK 26+、Rust，执行 `cargo install cargo-ndk` 并安装目标：  
`rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`

## 构建 so

在仓库根目录执行：`bash platforms/android/build-android.sh`  
会在 `src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/` 下生成 `libratex_ffi.so`。

## 集成方式

- **Maven：** `implementation("io.github.erweixin:ratex-android:0.0.3")`（需先发布；配好 `mavenLocal()` / `mavenCentral()` 等）。
- **模块：** 在 settings.gradle 里 include 本目录为 `:ratex-android`，app 中 `implementation(project(":ratex-android"))`。

## 字体

AAR 自带 KaTeX 字体（`assets/fonts/`）。启动时调用一次：  
`RaTeXFontLoader.loadFromAssets(context, "fonts")`

## 使用

```xml
<io.ratex.RaTeXView android:id="@+id/mathView"
    android:layout_width="wrap_content" android:layout_height="wrap_content" />
```

```kotlin
binding.mathView.latex = """\frac{-b \pm \sqrt{b^2-4ac}}{2a}"""
binding.mathView.fontSize = 24f * resources.displayMetrics.scaledDensity
```

Compose：用 `RaTeXRenderer(dl, fontSize) { RaTeXFontLoader.getTypeface(it) }` 在 `Canvas` 中绘制。

## 发布

- **本地：** 在包含本模块的工程（如 `demo/android`）下执行  
  `./gradlew :ratex-android:publishReleasePublicationToMavenLocal`。
- **远程（如 GitHub Packages）：** 在 gradle.properties 中配置 `MAVEN_REPO_URL`、`MAVEN_USER`、`MAVEN_PASSWORD`，再执行  
  `./gradlew :ratex-android:publishReleasePublicationToRemote`。
- **Maven Central：** 在 [central.sonatype.com](https://central.sonatype.com) 注册并配置命名空间与 GPG，在 gradle.properties 中配置 `SONATYPE_NEXUS_USERNAME`、`SONATYPE_NEXUS_PASSWORD`；在根工程执行  
  `./gradlew publishToSonatype closeAndReleaseSonatypeStagingRepository`。
- **CI：** 推送 tag（如 `v0.0.4`）会触发 `.github/workflows/release-android.yml` 发布到 Central。需在仓库 Secrets 中配置：`SONATYPE_NEXUS_USERNAME`、`SONATYPE_NEXUS_PASSWORD`、`GPG_PRIVATE_KEY`、`GPG_PASSPHRASE`。

## Demo

根目录执行 `bash platforms/android/build-android.sh`，用 Android Studio 打开 `demo/android` 运行即可。

**常见问题：** UnsatisfiedLinkError → 先执行 `build-android.sh`。NDK 未找到 → 安装 NDK 26+ 或设置 `ANDROID_NDK_HOME`。
