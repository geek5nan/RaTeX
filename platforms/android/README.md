# RaTeX — Android

Native LaTeX math on Android (Kotlin + Canvas). AAR includes KaTeX fonts.  
minSdk 21, targetSdk 34.

## Prerequisites

NDK 26+, Rust + `cargo install cargo-ndk`, and targets:  
`rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`

## Build native lib

From repo root: `bash platforms/android/build-android.sh`  
→ outputs `src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/libratex_ffi.so`

## Add to project

- **Maven:** `implementation("io.github.erweixin:ratex-android:0.0.3")` (after publishing; use `mavenLocal()` / `mavenCentral()` as needed).
- **Module:** include this folder as `:ratex-android` in settings.gradle and `implementation(project(":ratex-android"))` in app.

## Fonts

AAR has KaTeX in `assets/fonts/`. Once at startup:  
`RaTeXFontLoader.loadFromAssets(context, "fonts")`

## Usage

```xml
<io.ratex.RaTeXView android:id="@+id/mathView"
    android:layout_width="wrap_content" android:layout_height="wrap_content" />
```

```kotlin
binding.mathView.latex = """\frac{-b \pm \sqrt{b^2-4ac}}{2a}"""
binding.mathView.fontSize = 24f * resources.displayMetrics.scaledDensity
```

Compose: `RaTeXRenderer(dl, fontSize) { RaTeXFontLoader.getTypeface(it) }` and draw in `Canvas`.

## Publish

- **Local:** `./gradlew :ratex-android:publishReleasePublicationToMavenLocal` (from a build that includes this module, e.g. `demo/android`).
- **Remote (e.g. GitHub Packages):** set `MAVEN_REPO_URL`, `MAVEN_USER`, `MAVEN_PASSWORD` in gradle.properties, then `./gradlew :ratex-android:publishReleasePublicationToRemote`.
- **Maven Central:** configure [central.sonatype.com](https://central.sonatype.com) + GPG + `SONATYPE_NEXUS_USERNAME` / `SONATYPE_NEXUS_PASSWORD` in gradle.properties; from root use `./gradlew publishToSonatype closeAndReleaseSonatypeStagingRepository`.
- **CI:** push tag `v0.0.4` → `.github/workflows/release-android.yml` publishes to Central. Set repo secrets: `SONATYPE_NEXUS_USERNAME`, `SONATYPE_NEXUS_PASSWORD`, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`.

## Demo

From root: `bash platforms/android/build-android.sh`, then open `demo/android` in Android Studio and run.

**Troubleshooting:** UnsatisfiedLinkError → run `build-android.sh`. NDK not found → install NDK 26+ or set `ANDROID_NDK_HOME`.
