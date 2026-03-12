# RaTeX Project Structure

Current layout as of the codebase. RA (Rust) + TeX.

---

## Root Layout

```
RaTeX/
├── Cargo.toml                    # Workspace root
├── README.md
├── LICENSE                       # MIT
├── .gitignore
├── .github/
│   └── workflows/
│       └── ci.yml                # Build + Clippy + Test
│
├── crates/                       # Rust crates
│   ├── ratex-types/              # Shared types (DisplayList, Color, etc.)
│   ├── ratex-font/               # Font metrics + symbol tables (KaTeX-compatible)
│   ├── ratex-lexer/               # LaTeX → token stream
│   ├── ratex-parser/             # Token stream → ParseNode AST
│   ├── ratex-layout/             # AST → LayoutBox → DisplayList
│   ├── ratex-ffi/                # C ABI export (iOS/Android/Flutter/RN) — stub
│   ├── ratex-render/             # DisplayList → PNG (tiny-skia, server-side)
│   └── ratex-wasm/               # WASM: LaTeX → DisplayList JSON (browser)
│
├── platforms/
│   ├── ios/                      # Swift (binding layer in progress)
│   ├── android/                  # Android (binding layer in progress)
│   ├── flutter/                  # Flutter (binding layer in progress)
│   └── web/                      # WASM + TypeScript web-render (working)
│
├── tools/                        # Dev / comparison scripts
│   ├── convert_metrics.py        # KaTeX fontMetricsData.js → Rust
│   ├── convert_symbols.py        # KaTeX symbols.js → Rust
│   ├── golden_compare/           # Golden PNG comparison (compare_golden.py)
│   ├── layout_compare/            # Layout box vs KaTeX (katex_layout.mjs + compare_layouts.py)
│   ├── lexer_compare/             # Token output vs KaTeX lexer
│   └── parser_compare/            # Parser comparison
│
├── tests/
│   └── golden/                   # Golden test assets
│       ├── fixtures/              # KaTeX reference PNGs (per test case)
│       ├── output/                # RaTeX-rendered PNGs (from ratex-render)
│       └── test_cases.txt         # One LaTeX formula per line
│
├── scripts/
│   └── update_golden_output.sh    # Renders all test_cases.txt → output/
│
└── demo/                         # Web demo (support table, index)
```

---

## Cargo.toml (Workspace)

```toml
[workspace]
resolver = "2"
members = [
    "crates/ratex-types",
    "crates/ratex-font",
    "crates/ratex-lexer",
    "crates/ratex-parser",
    "crates/ratex-layout",
    "crates/ratex-ffi",
    "crates/ratex-render",
    "crates/ratex-wasm",
]

[workspace.package]
version = "0.0.2"
edition = "2021"
authors = ["RaTeX Contributors"]
license = "MIT"

[workspace.dependencies]
ratex-types  = { path = "crates/ratex-types" }
ratex-font   = { path = "crates/ratex-font" }
ratex-lexer  = { path = "crates/ratex-lexer" }
ratex-parser = { path = "crates/ratex-parser" }
ratex-layout = { path = "crates/ratex-layout" }

phf        = { version = "0.11", features = ["macros"] }
thiserror  = "1.0"
serde      = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

---

## Crates (summary)

| Crate | Role |
|-------|------|
| **ratex-types** | `DisplayList`, `DisplayItem` (GlyphPath, Line, Rect, Path), `Color`, `PathCommand`, `MathStyle` |
| **ratex-font** | KaTeX font metrics, symbol tables; `data/metrics_data.rs`, `data/symbols_data.rs` (generated) |
| **ratex-lexer** | LaTeX string → token stream |
| **ratex-parser** | Token stream → ParseNode AST (macro expansion, functions) |
| **ratex-layout** | AST → LayoutBox tree → `to_display_list` → DisplayList |
| **ratex-ffi** | C ABI for native platforms (currently stub) |
| **ratex-render** | DisplayList → PNG via tiny-skia + ab_glyph (server/CI) |
| **ratex-wasm** | WASM: parse + layout → DisplayList JSON for browser |

---

## ratex-types — DisplayItem (actual shape)

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum DisplayItem {
    GlyphPath {
        x: f64, y: f64,
        scale: f64,
        font: String,
        char_code: u32,
        commands: Vec<PathCommand>,
        color: Color,
    },
    Line { x: f64, y: f64, width: f64, thickness: f64, color: Color },
    Rect { x: f64, y: f64, width: f64, height: f64, color: Color },
    Path {
        x: f64, y: f64,
        commands: Vec<PathCommand>,
        fill: bool,
        color: Color,
    },
}
```

---

## ratex-font layout

```
crates/ratex-font/
├── Cargo.toml
└── src/
    ├── lib.rs
    ├── font_id.rs       # FontId enum
    ├── metrics.rs       # CharMetrics, math constants
    ├── symbols.rs       # Symbol lookup
    └── data/            # Generated (do not edit by hand)
        ├── mod.rs
        ├── metrics_data.rs
        └── symbols_data.rs
```

---

## ratex-ffi

Currently a stub: `crates/ratex-ffi/src/lib.rs` only. C ABI entrypoints for iOS/Android/Flutter/RN will be added here.

---

## ratex-render layout

```
crates/ratex-render/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   ├── main.rs          # CLI binary (stdin → PNGs)
│   └── renderer.rs      # DisplayList → tiny-skia rasterize
└── tests/
    └── golden_test.rs   # Compares output/ vs fixtures/ (ink score)
```

---

## ratex-wasm

WASM crate; exports `renderLatex(latex: string) => string` (DisplayList JSON). Consumed by `platforms/web` (TypeScript + Canvas 2D).

---

## Dependency graph

```
ratex-types (base types)
    ↑
ratex-font (metrics + symbols)
    ↑
ratex-lexer
    ↑
ratex-parser
    ↑
ratex-layout
    ↑
    ├── ratex-ffi    (C ABI for native)
    ├── ratex-render (PNG)
    └── ratex-wasm   (browser JSON)
    ↑
platforms/ (ios, android, flutter, web)
```

---

## Golden test workflow

1. **Reference PNGs**: `tests/golden/fixtures/` (from KaTeX, one per line in `test_cases.txt`).
2. **RaTeX output**: `scripts/update_golden_output.sh` runs `ratex-render` to produce `tests/golden/output/*.png`.
3. **Comparison**: `tools/golden_compare/compare_golden.py` (or Rust test `crates/ratex-render/tests/golden_test.rs`) compares output vs fixtures (e.g. ink-coverage threshold).

See also `docs/LOW_SCORE_CASES.md` for low-scoring cases and `docs/KATEX_SVG_PATH_PLAN.md` for stretchy SVG path improvements.
