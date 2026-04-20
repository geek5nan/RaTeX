/// RaTeX Rust Benchmark — latex → display list pipeline.
///
/// Measures parse + layout + to_display_list with batched timing
/// for accurate sub-microsecond measurements.
///
/// Usage:
///   cargo run --release --bin benchmark -- \
///     --input tools/benchmark/formulas.json \
///     --output artifacts/benchmark/rust_results.json

use ratex_layout::{layout, to_display_list, LayoutOptions};
use ratex_parser::parser::parse;
use std::time::Instant;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let input_path = get_arg(&args, "--input").unwrap_or_else(|| "tools/benchmark/formulas.json".to_string());
    let output_path = get_arg(&args, "--output").unwrap_or_else(|| "artifacts/benchmark/rust_results.json".to_string());
    let warmup_count: usize = get_arg(&args, "--warmup").and_then(|s| s.parse().ok()).unwrap_or(10);
    let sample_count: usize = get_arg(&args, "--samples").and_then(|s| s.parse().ok()).unwrap_or(100);
    let min_batch_ms: u64 = get_arg(&args, "--min-batch-ms").and_then(|s| s.parse().ok()).unwrap_or(1);

    let input_text = std::fs::read_to_string(&input_path)
        .unwrap_or_else(|e| panic!("Cannot read {}: {}", input_path, e));
    let formulas: Vec<FormulaInput> = serde_json::from_str(&input_text)
        .unwrap_or_else(|e| panic!("Cannot parse {}: {}", input_path, e));

    eprintln!("RaTeX Rust Benchmark");
    eprintln!("  formulas: {}", formulas.len());
    eprintln!("  warmup: {}, samples: {}, min_batch_ms: {}",
             warmup_count, sample_count, min_batch_ms);

    // Warmup: run all formulas untimed to stabilize caches
    eprintln!("Warming up ({} passes over all formulas)...", warmup_count);
    for _ in 0..warmup_count {
        for f in &formulas {
            let _ = run_pipeline(&f.formula);
        }
    }

    // Calibrate batch size using the first formula
    let batch_size = calibrate_batch_size(&formulas[0].formula, min_batch_ms);
    eprintln!("Calibrated batch_size: {} (target ≥{}ms per sample)", batch_size, min_batch_ms);

    // Measure each formula
    let mut results = Vec::new();
    for f in &formulas {
        eprint!("  id={:>4} ", f.id);

        // Recalibrate per formula for better accuracy on very different costs
        let bs = calibrate_batch_size(&f.formula, min_batch_ms);

        let mut timings_ns: Vec<u64> = Vec::with_capacity(sample_count);
        let mut parse_ns: Vec<u64> = Vec::with_capacity(sample_count);
        let mut layout_ns: Vec<u64> = Vec::with_capacity(sample_count);
        let mut to_display_ns: Vec<u64> = Vec::with_capacity(sample_count);

        for _ in 0..sample_count {
            let (total, p, l, d) = measure_batch(&f.formula, bs);
            timings_ns.push(total);
            parse_ns.push(p);
            layout_ns.push(l);
            to_display_ns.push(d);
        }

        let stats = compute_stats(&timings_ns);
        let parse_stats = compute_stats(&parse_ns);
        let layout_stats = compute_stats(&layout_ns);
        let to_display_stats = compute_stats(&to_display_ns);

        eprintln!("median={:.1}µs  p95={:.1}µs  (batch={})",
                 stats.median_ns as f64 / 1000.0,
                 stats.p95_ns as f64 / 1000.0,
                 bs);

        results.push(serde_json::json!({
            "id": f.id,
            "formula": f.formula,
            "tier": f.tier,
            "batch_size": bs,
            "warmup_count": warmup_count,
            "sample_count": sample_count,
            "stats": {
                "median_ns": stats.median_ns,
                "p95_ns": stats.p95_ns,
                "min_ns": stats.min_ns,
                "max_ns": stats.max_ns,
                "mean_ns": stats.mean_ns,
            },
            "stages": {
                "parse": {
                    "median_ns": parse_stats.median_ns,
                    "p95_ns": parse_stats.p95_ns,
                },
                "layout": {
                    "median_ns": layout_stats.median_ns,
                    "p95_ns": layout_stats.p95_ns,
                },
                "to_display": {
                    "median_ns": to_display_stats.median_ns,
                    "p95_ns": to_display_stats.p95_ns,
                },
            },
        }));
    }

    let output = serde_json::json!({
        "engine": "rust",
        "build": "release",
        "timestamp": chrono_lite_now(),
        "warmup_count": warmup_count,
        "sample_count": sample_count,
        "min_batch_ms": min_batch_ms,
        "formulas": results,
    });

    if let Some(parent) = std::path::Path::new(&output_path).parent() {
        std::fs::create_dir_all(parent).ok();
    }
    std::fs::write(&output_path, serde_json::to_string_pretty(&output).unwrap())
        .unwrap_or_else(|e| panic!("Cannot write {}: {}", output_path, e));

    eprintln!("\nResults written to {}", output_path);
}

#[derive(serde::Deserialize)]
struct FormulaInput {
    id: u32,
    formula: String,
    #[serde(default)]
    tier: String,
}

struct Stats {
    median_ns: u64,
    p95_ns: u64,
    min_ns: u64,
    max_ns: u64,
    mean_ns: u64,
}

fn run_pipeline(formula: &str) -> Result<(), String> {
    let ast = parse(formula).map_err(|e| e.to_string())?;
    let opts = LayoutOptions::default();
    let lbox = layout(&ast, &opts);
    let _dl = to_display_list(&lbox);
    Ok(())
}

/// Measure one batch of `batch_size` iterations, return per-call timings (total, parse, layout, to_display).
fn measure_batch(formula: &str, batch_size: usize) -> (u64, u64, u64, u64) {
    let mut total_parse = 0u64;
    let mut total_layout = 0u64;
    let mut total_to_display = 0u64;

    let start = Instant::now();

    for _ in 0..batch_size {
        let t0 = Instant::now();
        let ast = match parse(formula) {
            Ok(a) => a,
            Err(_) => {
                let elapsed = t0.elapsed().as_nanos() as u64;
                total_parse += elapsed;
                continue;
            }
        };
        let t1 = Instant::now();
        total_parse += (t1 - t0).as_nanos() as u64;

        let opts = LayoutOptions::default();
        let lbox = layout(&ast, &opts);
        let t2 = Instant::now();
        total_layout += (t2 - t1).as_nanos() as u64;

        let _dl = to_display_list(&lbox);
        let t3 = Instant::now();
        total_to_display += (t3 - t2).as_nanos() as u64;
    }

    let total_ns = start.elapsed().as_nanos() as u64;
    let bs = batch_size as u64;
    (total_ns / bs, total_parse / bs, total_layout / bs, total_to_display / bs)
}

/// Auto-calibrate batch size so each sample takes at least `min_ms` milliseconds.
fn calibrate_batch_size(formula: &str, min_ms: u64) -> usize {
    let mut bs = 1usize;
    loop {
        let start = Instant::now();
        for _ in 0..bs {
            let _ = run_pipeline(formula);
        }
        let elapsed_ms = start.elapsed().as_millis() as u64;
        if elapsed_ms >= min_ms {
            return bs;
        }
        // Double and try again
        bs = if elapsed_ms == 0 { bs * 10 } else { bs * 2 };
        if bs > 100_000 { return bs; }
    }
}

fn compute_stats(values: &[u64]) -> Stats {
    let mut sorted = values.to_vec();
    sorted.sort_unstable();
    let n = sorted.len();
    let sum: u64 = sorted.iter().sum();
    Stats {
        median_ns: sorted[n / 2],
        p95_ns: sorted[(n as f64 * 0.95) as usize],
        min_ns: sorted[0],
        max_ns: sorted[n - 1],
        mean_ns: sum / n as u64,
    }
}

fn get_arg(args: &[String], flag: &str) -> Option<String> {
    args.iter().position(|a| a == flag).and_then(|i| args.get(i + 1).cloned())
}

fn chrono_lite_now() -> String {
    use std::time::SystemTime;
    let d = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap();
    format!("{}s_since_epoch", d.as_secs())
}
