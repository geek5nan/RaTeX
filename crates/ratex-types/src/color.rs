use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Color {
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
}

impl Color {
    pub const BLACK: Color = Color {
        r: 0.0,
        g: 0.0,
        b: 0.0,
        a: 1.0,
    };

    pub const WHITE: Color = Color {
        r: 1.0,
        g: 1.0,
        b: 1.0,
        a: 1.0,
    };

    pub const fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Self { r, g, b, a }
    }

    pub const fn rgb(r: f32, g: f32, b: f32) -> Self {
        Self { r, g, b, a: 1.0 }
    }

    /// Parse a hex color string like "#ff0000" or "#f00".
    pub fn from_hex(hex: &str) -> Option<Self> {
        let hex = hex.strip_prefix('#').unwrap_or(hex);
        match hex.len() {
            3 => {
                let r = u8::from_str_radix(&hex[0..1], 16).ok()?;
                let g = u8::from_str_radix(&hex[1..2], 16).ok()?;
                let b = u8::from_str_radix(&hex[2..3], 16).ok()?;
                Some(Self::rgb(
                    (r * 17) as f32 / 255.0,
                    (g * 17) as f32 / 255.0,
                    (b * 17) as f32 / 255.0,
                ))
            }
            6 => {
                let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
                let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
                let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
                Some(Self::rgb(
                    r as f32 / 255.0,
                    g as f32 / 255.0,
                    b as f32 / 255.0,
                ))
            }
            _ => None,
        }
    }

    /// Parse a named CSS color (subset used by KaTeX).
    pub fn from_name(name: &str) -> Option<Self> {
        match name.to_lowercase().as_str() {
            "red" => Some(Self::rgb(1.0, 0.0, 0.0)),
            "green" => Some(Self::rgb(0.0, 0.502, 0.0)),
            "blue" => Some(Self::rgb(0.0, 0.0, 1.0)),
            "white" => Some(Self::WHITE),
            "black" => Some(Self::BLACK),
            "orange" => Some(Self::rgb(1.0, 0.647, 0.0)),
            "yellow" => Some(Self::rgb(1.0, 1.0, 0.0)),
            "purple" => Some(Self::rgb(0.502, 0.0, 0.502)),
            "cyan" => Some(Self::rgb(0.0, 1.0, 1.0)),
            "magenta" => Some(Self::rgb(1.0, 0.0, 1.0)),
            "gray" | "grey" => Some(Self::rgb(0.502, 0.502, 0.502)),
            "brown" => Some(Self::rgb(0.647, 0.165, 0.165)),
            "pink" => Some(Self::rgb(1.0, 0.753, 0.796)),
            "teal" => Some(Self::rgb(0.0, 0.502, 0.502)),
            _ => None,
        }
    }
}

impl Default for Color {
    fn default() -> Self {
        Self::BLACK
    }
}

impl std::fmt::Display for Color {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if (self.a - 1.0).abs() < f32::EPSILON {
            write!(
                f,
                "#{:02x}{:02x}{:02x}",
                (self.r * 255.0) as u8,
                (self.g * 255.0) as u8,
                (self.b * 255.0) as u8,
            )
        } else {
            write!(
                f,
                "rgba({}, {}, {}, {:.2})",
                (self.r * 255.0) as u8,
                (self.g * 255.0) as u8,
                (self.b * 255.0) as u8,
                self.a,
            )
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_is_black() {
        let c = Color::default();
        assert_eq!(c, Color::BLACK);
    }

    #[test]
    fn test_from_hex_6() {
        let c = Color::from_hex("#ff0000").unwrap();
        assert!((c.r - 1.0).abs() < 0.01);
        assert!(c.g.abs() < 0.01);
        assert!(c.b.abs() < 0.01);
        assert!((c.a - 1.0).abs() < 0.01);
    }

    #[test]
    fn test_from_hex_3() {
        let c = Color::from_hex("#f00").unwrap();
        assert!((c.r - 1.0).abs() < 0.01);
        assert!(c.g.abs() < 0.01);
        assert!(c.b.abs() < 0.01);
    }

    #[test]
    fn test_from_hex_no_hash() {
        let c = Color::from_hex("00ff00").unwrap();
        assert!(c.r.abs() < 0.01);
        assert!((c.g - 1.0).abs() < 0.01);
        assert!(c.b.abs() < 0.01);
    }

    #[test]
    fn test_from_name() {
        assert!(Color::from_name("red").is_some());
        assert!(Color::from_name("Blue").is_some());
        assert!(Color::from_name("nonexistent").is_none());
    }

    #[test]
    fn test_display_rgb() {
        let c = Color::rgb(1.0, 0.0, 0.0);
        assert_eq!(c.to_string(), "#ff0000");
    }

    #[test]
    fn test_display_rgba() {
        let c = Color::new(1.0, 0.0, 0.0, 0.5);
        assert_eq!(c.to_string(), "rgba(255, 0, 0, 0.50)");
    }

    #[test]
    fn test_serde_roundtrip() {
        let c = Color::rgb(0.5, 0.25, 0.75);
        let json = serde_json::to_string(&c).unwrap();
        let c2: Color = serde_json::from_str(&json).unwrap();
        assert!((c.r - c2.r).abs() < f32::EPSILON);
        assert!((c.g - c2.g).abs() < f32::EPSILON);
        assert!((c.b - c2.b).abs() < f32::EPSILON);
    }
}
