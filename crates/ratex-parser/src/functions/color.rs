use std::collections::HashMap;

use crate::error::{ParseError, ParseResult};
use crate::functions::{define_function_full, ArgType, FunctionContext, FunctionSpec};
use crate::parse_node::ParseNode;

pub fn register(map: &mut HashMap<&'static str, FunctionSpec>) {
    // \textcolor{color}{body}
    define_function_full(
        map,
        &["\\textcolor"],
        "color",
        2, 0,
        Some(vec![ArgType::Color, ArgType::Original]),
        false,
        true,  // allowed_in_text
        true,
        false, false,
        handle_textcolor,
    );

    // \color{color} (applies to rest of group)
    define_function_full(
        map,
        &["\\color"],
        "color",
        1, 0,
        Some(vec![ArgType::Color]),
        false,
        true,
        true,
        false, false,
        handle_color,
    );

    // \colorbox{color}{body}
    define_function_full(
        map,
        &["\\colorbox"],
        "enclose",
        2, 0,
        Some(vec![ArgType::Color, ArgType::Text]),
        false,
        true,
        true,
        false, false,
        handle_colorbox,
    );

    // \fcolorbox{bordercolor}{bgcolor}{body}
    define_function_full(
        map,
        &["\\fcolorbox"],
        "enclose",
        3, 0,
        Some(vec![ArgType::Color, ArgType::Color, ArgType::Text]),
        false,
        true,
        true,
        false, false,
        handle_fcolorbox,
    );
}

fn handle_textcolor(
    ctx: &mut FunctionContext,
    args: Vec<ParseNode>,
    _opt_args: Vec<Option<ParseNode>>,
) -> ParseResult<ParseNode> {
    let color = extract_color(&args[0])?;
    let body = ParseNode::ord_argument(args[1].clone());

    Ok(ParseNode::Color {
        mode: ctx.parser.mode,
        color,
        body,
        loc: None,
    })
}

fn handle_color(
    ctx: &mut FunctionContext,
    args: Vec<ParseNode>,
    _opt_args: Vec<Option<ParseNode>>,
) -> ParseResult<ParseNode> {
    let color = extract_color(&args[0])?;
    let break_on = ctx.break_on_token_text.clone();
    let body = ctx
        .parser
        .parse_expression(true, break_on.as_deref())?;

    Ok(ParseNode::Color {
        mode: ctx.parser.mode,
        color,
        body,
        loc: None,
    })
}

fn handle_colorbox(
    ctx: &mut FunctionContext,
    args: Vec<ParseNode>,
    _opt_args: Vec<Option<ParseNode>>,
) -> ParseResult<ParseNode> {
    let color = extract_color(&args[0])?;
    let body = args[1].clone();

    Ok(ParseNode::Enclose {
        mode: ctx.parser.mode,
        label: "\\colorbox".to_string(),
        background_color: Some(color),
        border_color: None,
        body: Box::new(body),
        loc: None,
    })
}

fn handle_fcolorbox(
    ctx: &mut FunctionContext,
    args: Vec<ParseNode>,
    _opt_args: Vec<Option<ParseNode>>,
) -> ParseResult<ParseNode> {
    let border_color = extract_color(&args[0])?;
    let bg_color = extract_color(&args[1])?;
    let body = args[2].clone();

    Ok(ParseNode::Enclose {
        mode: ctx.parser.mode,
        label: "\\fcolorbox".to_string(),
        background_color: Some(bg_color),
        border_color: Some(border_color),
        body: Box::new(body),
        loc: None,
    })
}

fn extract_color(node: &ParseNode) -> ParseResult<String> {
    if let ParseNode::ColorToken { color, .. } = node {
        Ok(color.clone())
    } else {
        Err(ParseError::msg("Expected color token"))
    }
}
