// Batch bitmap renderer: reads a JSON formula list, renders each to PNG.
//
// Usage:
//   cargo run --bin render-bitmap-batch -- \
//     --input tools/bitmap_diff/formulas.json \
//     --output artifacts/bitmap_diff/rust \
//     --font-size 32 --padding 16

use std::io::Write;
use std::path::PathBuf;

use ratex_layout::{layout, to_display_list, LayoutOptions};
use ratex_parser::parser::parse;
use ratex_render::{render_to_png, RenderOptions};
use ratex_types::math_style::MathStyle;

#[derive(serde::Deserialize)]
#[allow(dead_code)]
struct FormulaEntry {
    id: u32,
    formula: String,
    #[serde(default)]
    expected_error: bool,
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    let input_path = get_arg(&args, "--input")
        .unwrap_or_else(|| "tools/bitmap_diff/formulas.json".to_string());

    let output_dir = get_arg(&args, "--output")
        .unwrap_or_else(|| "artifacts/bitmap_diff/rust".to_string());

    let font_size = get_arg(&args, "--font-size")
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(32.0);

    let scale = get_arg(&args, "--scale")
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(1.0);

    let padding = get_arg(&args, "--padding")
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(16.0);

    let font_dir = get_arg(&args, "--font-dir")
        .unwrap_or_else(default_font_dir);

    std::fs::create_dir_all(&output_dir).expect("Failed to create output dir");

    let input_data = std::fs::read_to_string(&input_path)
        .unwrap_or_else(|e| panic!("Failed to read {}: {}", input_path, e));

    let formulas: Vec<FormulaEntry> = serde_json::from_str(&input_data)
        .unwrap_or_else(|e| panic!("Failed to parse input JSON: {}", e));

    let options = RenderOptions {
        font_size,
        padding,
        font_dir,
        device_pixel_ratio: scale,
    };

    let layout_opts = LayoutOptions::default().with_style(MathStyle::Display);

    let mut ok_count = 0u32;
    let mut err_count = 0u32;

    for entry in &formulas {
        let filename = format!("{:04}", entry.id);
        match render_formula(&entry.formula, &layout_opts, &options) {
            Ok(png_data) => {
                let path = PathBuf::from(&output_dir).join(format!("{}.png", filename));
                std::fs::write(&path, &png_data)
                    .unwrap_or_else(|e| eprintln!("WRITE_ERR {:4} — {}", entry.id, e));
                ok_count += 1;
            }
            Err(e) => {
                let error_json = serde_json::json!({
                    "id": entry.id,
                    "formula": entry.formula,
                    "error": e,
                });
                let path = PathBuf::from(&output_dir).join(format!("{}.error.json", filename));
                let mut f = std::fs::File::create(&path)
                    .unwrap_or_else(|e2| panic!("Failed to create error file: {}", e2));
                serde_json::to_writer_pretty(&mut f, &error_json).ok();
                f.write_all(b"\n").ok();
                err_count += 1;
            }
        }
    }

    println!(
        "Rust batch render: {} total, {} OK, {} errors → {}/",
        formulas.len(),
        ok_count,
        err_count,
        output_dir,
    );
}

fn render_formula(
    expr: &str,
    layout_opts: &LayoutOptions,
    render_opts: &RenderOptions,
) -> Result<Vec<u8>, String> {
    let ast = parse(expr).map_err(|e| format!("Parse error: {}", e))?;
    let lbox = layout(&ast, layout_opts);
    let display_list = to_display_list(&lbox);
    render_to_png(&display_list, render_opts)
}

fn get_arg(args: &[String], flag: &str) -> Option<String> {
    args.iter()
        .position(|a| a == flag)
        .and_then(|i| args.get(i + 1))
        .cloned()
}

fn default_font_dir() -> String {
    const MARKER: &str = "KaTeX_Main-Regular.ttf";
    let candidates = [
        "fonts",
        "../fonts",
        "../../fonts",
        "../../../fonts",
    ];
    for c in &candidates {
        let p = std::path::Path::new(c);
        if p.join(MARKER).is_file() {
            return c.to_string();
        }
    }
    "fonts".to_string()
}
