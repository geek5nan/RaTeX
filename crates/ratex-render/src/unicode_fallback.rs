//! Load a system / generic Unicode `.ttf` for glyphs missing from KaTeX fonts (browser uses
//! system fallback; we only bundle KaTeX faces).

use ab_glyph::{Font, FontRef};
use fontdb::{Database, Family, Query, Stretch, Style, Weight};
use std::sync::OnceLock;

static UNICODE_FONT: OnceLock<Option<Vec<u8>>> = OnceLock::new();

/// Raw TTF bytes suitable for [`FontRef::try_from_slice`], or `None` if no fallback was found.
pub fn unicode_fallback_font_bytes() -> Option<&'static [u8]> {
    UNICODE_FONT
        .get_or_init(load_unicode_fallback_font)
        .as_ref()
        .map(|v| v.as_slice())
}

fn font_renders_char(bytes: &[u8], ch: char) -> bool {
    let Ok(font) = FontRef::try_from_slice(bytes) else {
        return false;
    };
    let gid = font.glyph_id(ch);
    if gid.0 == 0 {
        return false;
    }
    font.outline(gid).is_some()
}

fn load_unicode_fallback_font() -> Option<Vec<u8>> {
    use std::path::Path;

    if let Ok(p) = std::env::var("RATEX_UNICODE_FONT") {
        if let Ok(bytes) = std::fs::read(Path::new(&p)) {
            if font_renders_char(&bytes, '\u{263a}') {
                return Some(bytes);
            }
        }
    }

    // Typical locations (Linux CI: DejaVu; macOS / Windows: Arial).
    #[rustfmt::skip]
    let candidates: &[&str] = &[
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/Library/Fonts/Arial.ttf",
        "/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\segoeui.ttf",
    ];

    for path in candidates {
        if let Ok(bytes) = std::fs::read(Path::new(path)) {
            if font_renders_char(&bytes, '\u{263a}') {
                return Some(bytes);
            }
        }
    }

    let mut db = Database::new();
    db.load_system_fonts();

    let query = Query {
        families: &[Family::SansSerif],
        weight: Weight::NORMAL,
        stretch: Stretch::Normal,
        style: Style::Normal,
    };

    if let Some(id) = db.query(&query) {
        if let Some(bytes) = db.with_face_data(id, |data, _| data.to_vec()) {
            if font_renders_char(&bytes, '\u{263a}') {
                return Some(bytes);
            }
        }
    }

    for face in db.faces() {
        if let Some(bytes) = db.with_face_data(face.id, |data, _| data.to_vec()) {
            if font_renders_char(&bytes, '\u{263a}') {
                return Some(bytes);
            }
        }
    }

    None
}
