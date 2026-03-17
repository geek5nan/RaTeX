# RaTeX

**简体中文** | [English](README.md)

**纯 Rust 实现的 KaTeX 兼容数学渲染引擎 — 无 JavaScript、无 WebView、无 DOM。**

解析 LaTeX，按 TeX 规则排版，在任意平台原生渲染。**胶水层已就绪，各平台开箱即用。**

```
\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}   →   iOS · Android · Flutter · React Native · Web · PNG
```

---

## 为什么选 RaTeX？

目前主流的跨平台数学渲染方案都依赖浏览器或 JavaScript 引擎跑 LaTeX，带来的问题是：

- 隐藏的 WebView 占用 50–150 MB 内存
- 首屏公式要等 JavaScript 启动
- 无法保证离线、性能不可预期

RaTeX 完全去掉 Web 栈：一个 Rust 核心、一套显示列表，各平台原生渲染。

| | KaTeX (Web) | MathJax | **RaTeX** |
|---|---|---|---|
| 运行时 | V8 + DOM | V8 + DOM | **纯 Rust** |
| 移动端 | WebView | WebView | **原生** |
| 离线 | 视情况 | 视情况 | **支持** |
| 包体积 | ~280 kB JS | ~500 kB JS | **0 kB JS** |
| 内存模型 | GC / 堆 | GC / 堆 | **可预期** |
| 语法覆盖 | 100% | ~100% | **~99%** |

---

## 要点

- **~99%** 的 KaTeX 公式语法 — 解析与排版与 LaTeX 源码一致
- **~80%** 与 KaTeX 的视觉相似度（与 KaTeX 参考渲染的黄金测试得分）
- **单一显示列表**：扁平的、可序列化的绘图指令，供任意渲染器消费
- **C ABI**（`ratex-ffi`）供 Swift、Kotlin、Dart、Go、C++ 等 FFI 调用
- **各平台胶水层**：iOS / Android / Flutter / React Native 绑定就绪，**开箱即用**
- **WASM**（`ratex-wasm`）通过 `<ratex-formula>` Web 组件在浏览器中即插即用
- **服务端 PNG** 通过 tiny-skia — 无需浏览器

**[→ 在线演示](https://erweixin.github.io/RaTeX/demo/index.html)** — 输入 LaTeX，对比 RaTeX (Rust/WASM) 与 KaTeX 
**[→ 支持表](https://erweixin.github.io/RaTeX/demo/support_table.html)** — 916 条测试公式的 RaTeX vs KaTeX 对比

---

## 平台支持

| 平台 | 方式 | 状态 |
|---|---|---|
| **Web** | WASM → Canvas 2D · `<ratex-formula>` Web 组件 | 可用 |
| **服务端 / CI** | tiny-skia → PNG 光栅化 | 可用 |
| **iOS** | Swift/ObjC 绑定 C ABI · XCFramework | 开箱即用 |
| **Android** | JNI → Kotlin/Java · AAR | 开箱即用 |
| **React Native** | 通过 C ABI 的 Native 模块 | in progress |
| **Flutter** | Dart FFI 调用 C ABI | 开箱即用 |

> Rust 核心与各平台胶水层均已就绪，可直接集成使用。

---

## 架构

### 流水线概览

LaTeX 公式渲染经历四个阶段：**词法** → **解析** → **排版** → **显示列表**。显示列表是一组带绝对坐标的绘图指令（字形、线段、矩形、路径）；由原生 UI（iOS/Android/Flutter/RN）或服务端光栅器（tiny-skia → PNG）消费。

```mermaid
flowchart LR
    subgraph input[" "]
        A[LaTeX string]
    end
    subgraph core["Rust core"]
        B[ratex-lexer<br/>Tokenization]
        C[ratex-parser<br/>AST]
        D[ratex-layout<br/>LayoutBox tree]
        E[to_display_list<br/>DisplayList]
    end
    subgraph output[" "]
        F[Native render<br/>iOS / Android / Flutter / RN]
        G[ratex-render<br/>PNG]
    end
    A --> B --> C --> D --> E
    E --> F
    E --> G
```

### 数据流（详）

```mermaid
flowchart TB
    subgraph types["ratex-types"]
        T1[Color, PathCommand<br/>DisplayItem, DisplayList<br/>MathStyle]
    end
    subgraph font["ratex-font"]
        F1[KaTeX font metrics<br/>symbol tables]
    end
    LEX[ratex-lexer<br/>Token stream] --> PARSE[ratex-parser<br/>ParseNode AST]
    F1 -.-> LEX
    F1 -.-> PARSE
    PARSE --> LAYOUT[ratex-layout<br/>layout → LayoutBox]
    F1 -.-> LAYOUT
    LAYOUT --> TODISP[to_display_list<br/>LayoutBox → DisplayList]
    TODISP --> DL[DisplayList]
    T1 -.-> DL
    DL --> FFI[ratex-ffi<br/>C ABI]
    DL --> RENDER[ratex-render<br/>tiny-skia → PNG]
    DL --> WASM[ratex-wasm<br/>JSON for web]
```

- **ratex-lexer**：将 LaTeX 源码转为 token 流（命令、括号、符号等）。
- **ratex-parser**：构建 **ParseNode** AST（兼容 KaTeX），含宏展开与函数分发。
- **ratex-layout**：根据 AST 生成 **LayoutBox** 树（横/竖盒、字形、分数线、分式等），使用 TeX 风格度量与规则；**to_display_list** 将 LayoutBox 树转为扁平 **DisplayList**。
- **DisplayList**：可序列化的 `DisplayItem` 列表（GlyphPath、Line、Rect、Path）。由以下模块消费：
  - **ratex-ffi**：通过 C ABI 暴露流水线，供 iOS/Android/RN/Flutter 原生渲染。
  - **ratex-render**：用 tiny-skia 将显示列表光栅化为 PNG（服务端）。
  - **ratex-wasm**：在浏览器中暴露同一流水线；返回 DisplayList 的 JSON，供 Canvas 2D（或其他）渲染。

### Crate 职责

| Crate | 职责 |
|--------|------|
| `ratex-types` | 共享类型：`Color`、`PathCommand`、`DisplayItem`、`DisplayList`、`MathStyle`。 |
| `ratex-font` | 字体度量与符号表（兼容 KaTeX 字体）。 |
| `ratex-lexer` | LaTeX 词法 → token 流。 |
| `ratex-parser` | LaTeX 解析 → ParseNode AST（兼容 KaTeX 语法）。 |
| `ratex-layout` | 数学排版：AST → LayoutBox 树 → **to_display_list** → DisplayList。 |
| `ratex-render` | 仅服务端：DisplayList 光栅化为 PNG（tiny-skia + ab_glyph）。 |
| `ratex-ffi` | C ABI：完整流水线 → DisplayList，供 iOS、Android、RN、Flutter 原生渲染。 |
| `ratex-wasm` | WebAssembly：解析 + 排版 → DisplayList 的 JSON，供浏览器渲染。 |

### 文本流水线（小结）

```
LaTeX 公式字符串
        ↓
ratex-lexer   → 词法
        ↓
ratex-parser  → ParseNode AST
        ↓
ratex-layout  → LayoutBox 树 → to_display_list → DisplayList
        ↓
ratex-ffi     → 显示列表（iOS / Android / RN / Flutter → 原生渲染）
        或
ratex-render  → 服务端光栅化为 PNG（tiny-skia）
        或
ratex-wasm    → DisplayList JSON（Web）
```

## 快速开始

**环境要求：** Rust 1.70+（[rustup](https://rustup.rs)）

```bash
git clone https://github.com/erweixin/RaTeX.git
cd RaTeX
cargo build --release
```

### 渲染为 PNG

```bash
echo '\frac{1}{2} + \sqrt{x}' | cargo run --release -p ratex-render

# 指定字体与输出目录
echo '\sum_{i=1}^n i = \frac{n(n+1)}{2}' | cargo run --release -p ratex-render -- \
  --font-dir /path/to/katex/fonts \
  --output-dir ./out
```

### 在浏览器中使用（WASM）

```html
<!-- 1. 字体 -->
<link rel="stylesheet" href="node_modules/ratex-web/fonts.css" />

<!-- 2. 注册 Web 组件 -->
<script type="module" src="node_modules/ratex-web/dist/ratex-formula.js"></script>

<!-- 3. 使用 -->
<ratex-formula latex="\frac{-b \pm \sqrt{b^2-4ac}}{2a}" font-size="48"></ratex-formula>
```

完整 WASM + Web 渲染说明见 [`platforms/web/README.md`](platforms/web/README.md)。

### 各平台胶水层（开箱即用）

| 平台 | 文档 |
|------|------|
| iOS | [`platforms/ios/README.md`](platforms/ios/README.md) — XCFramework + Swift/CoreGraphics |
| Android | [`platforms/android/README.md`](platforms/android/README.md) — AAR + Kotlin/Canvas |
| Flutter | [`platforms/flutter/README.md`](platforms/flutter/README.md) — Dart FFI |
| Web | [`platforms/web/README.md`](platforms/web/README.md) — WASM + Web 组件 |

### 运行测试

```bash
cargo test --all
```

---

## Crate 一览

| Crate | 职责 |
|-------|------|
| `ratex-types` | 共享类型：DisplayItem、DisplayList、Color、MathStyle |
| `ratex-font` | 兼容 KaTeX 的字体度量与符号表 |
| `ratex-lexer` | LaTeX → token 流 |
| `ratex-parser` | token 流 → ParseNode AST（兼容 KaTeX） |
| `ratex-layout` | AST → LayoutBox 树 → DisplayList |
| `ratex-ffi` | C ABI：向各原生平台暴露完整流水线 |
| `ratex-wasm` | WASM：流水线 → DisplayList JSON（浏览器） |
| `ratex-render` | 服务端：DisplayList → PNG（tiny-skia） |

---

## KaTeX 兼容性

- **公式支持（~99%）：** 同一 LaTeX 源码可在浏览器中用 KaTeX、在设备上用 RaTeX 渲染，我们持续补齐剩余差异。
- **视觉相似度（~80%）：** 黄金测试将 RaTeX 渲染的 PNG 与 KaTeX 参考 PNG 对比，使用墨迹覆盖度（像素 IoU、召回、宽高比与宽度相似度）。80% 为视觉相似度分数，而非支持的公式比例（约 99%）。

---

## 致谢：KaTeX

RaTeX 深受 [KaTeX](https://katex.org/) 启发。KaTeX 是 Web 上快速、严谨的 LaTeX 数学渲染的事实标准；其解析器、符号表与排版语义遵循 Donald Knuth 的 TeX 规范。我们使用 KaTeX 的字体度量和黄金输出来验证 RaTeX，并追求**语法与视觉兼容**，使同一 LaTeX 源码在浏览器中用 KaTeX、在原生平台用 RaTeX 都能一致渲染。感谢 KaTeX 项目与贡献者的开放与文档 — 没有它，本引擎无法存在。

---

## 许可证

MIT — Copyright (c) erweixin.
