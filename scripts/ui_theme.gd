extends RefCounted

const INK = Color("25292c")
const SKIN = preload("res://assets/ui/default_skin.tres")

const TYPE_CAPTION = 14
const TYPE_BODY = 16
const TYPE_HEADING = 20
const TYPE_NUMBER = 28
const STYLES = {
	"panel_paper":preload("res://assets/ui/styles/panel_paper.tres"),
	"panel_dialog":preload("res://assets/ui/styles/panel_dialog.tres"),
	"panel_garden":preload("res://assets/ui/styles/panel_garden.tres"),
	"item_card":preload("res://assets/ui/styles/item_card.tres"),
	"button_secondary":preload("res://assets/ui/styles/button_secondary.tres"),
	"button_hover":preload("res://assets/ui/styles/button_hover.tres"),
	"button_pressed":preload("res://assets/ui/styles/button_pressed.tres"),
	"button_disabled":preload("res://assets/ui/styles/button_disabled.tres"),
	"button_primary":preload("res://assets/ui/styles/button_primary.tres"),
	"button_primary_hover":preload("res://assets/ui/styles/button_primary_hover.tres"),
	"button_primary_pressed":preload("res://assets/ui/styles/button_primary_pressed.tres"),
	"focus_ring":preload("res://assets/ui/styles/focus_ring.tres"),
	"progress_track":preload("res://assets/ui/styles/progress_track.tres"),
	"progress_fill":preload("res://assets/ui/styles/progress_fill.tres"),
	"outer_frame":preload("res://assets/ui/styles/outer_frame.tres"),
	"label_tag":preload("res://assets/ui/styles/label_tag.tres"),
	"panel_drawer":preload("res://assets/ui/styles/panel_drawer.tres"),
	"panel_wood":preload("res://assets/ui/styles/panel_wood.tres"),
	"plain":preload("res://assets/ui/styles/plain.tres"),
	"speech":preload("res://assets/ui/styles/speech.tres"),
}

static func asset_style(slot: String) -> StyleBox:
	return STYLES.get(slot,STYLES.panel_paper).duplicate()

static func tab_style(active: bool = false, hovered: bool = false) -> StyleBox:
	var box=asset_style("button_primary" if active else ("button_hover" if hovered else "plain"))
	box.content_margin_left=8
	box.content_margin_right=8
	return box

static func panel_style(bg: Color, border: Color = Color("b8c2ae"), _radius: int = 8) -> StyleBox:
	# Legacy color-based callers resolve to the shared atlas surfaces.
	var slot: String="panel_paper"
	if bg.a<0.01: slot="focus_ring"
	elif bg==INK: slot="button_primary"
	elif bg==Color("39433b"): slot="button_primary_hover"
	elif bg==Color("171c1a"): slot="button_primary_pressed"
	elif bg==Color("e5eadf"): slot="panel_garden"
	elif bg==Color("f7f8f3") or (bg==Color("f3f5ef") and border==INK): slot="panel_dialog"
	elif bg==Color("e1e8d7"): slot="button_secondary"
	elif bg==Color("cdddb7"): slot="button_hover"
	elif bg==Color("b4cb95"): slot="button_pressed"
	elif bg==Color("e5e7e0"): slot="button_disabled"
	return asset_style(slot)

static func create() -> Theme:
	var t=Theme.new()
	t.default_font=font_for_locale()
	t.default_font_size=16
	t.set_color("font_color","Label",SKIN.text_primary)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var slot: String={"normal":"button_secondary","hover":"button_hover","pressed":"button_pressed","focus":"focus_ring","disabled":"button_disabled"}[state]
		t.set_stylebox(state,"Button",asset_style(slot))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		t.set_color(state,"Button",SKIN.text_primary)
	for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color","icon_hover_pressed_color"]:
		t.set_color(state,"Button",SKIN.text_primary)
	t.set_color("icon_disabled_color","Button",Color("72796d"))
	t.set_color("font_disabled_color","Button",Color("72796d"))
	t.set_stylebox("focus","OptionButton",asset_style("focus_ring"))
	t.set_stylebox("panel","Panel",asset_style("panel_paper"))
	t.set_stylebox("panel","TooltipPanel",asset_style("panel_dialog"))
	t.set_font("font","TooltipLabel",font_for_locale())
	t.set_font_size("font_size","TooltipLabel",16)
	t.set_color("font_color","TooltipLabel",SKIN.text_primary)
	t.set_stylebox("panel","PopupMenu",asset_style("panel_paper"))
	t.set_stylebox("hover","PopupMenu",asset_style("button_primary"))
	t.set_color("font_color","PopupMenu",SKIN.text_primary)
	t.set_color("font_hover_color","PopupMenu",SKIN.text_on_primary)
	t.set_stylebox("scroll","VScrollBar",asset_style("button_disabled"))
	t.set_stylebox("grabber","VScrollBar",asset_style("button_secondary"))
	t.set_stylebox("grabber_highlight","VScrollBar",asset_style("button_hover"))
	t.set_stylebox("grabber_pressed","VScrollBar",asset_style("button_pressed"))
	return t

static func text_color(original: Color) -> Color:
	if original==INK: return SKIN.text_primary
	if original==Color("475148"): return SKIN.text_muted
	if original==Color("f4f5ef"): return SKIN.text_on_primary
	if original==Color("9b424b"): return SKIN.text_accent
	return original

static func font_for_locale() -> Font:
	return preload("res://assets/fonts/rounded_ja.tres") if TranslationServer.get_locale().begins_with("ja") else preload("res://assets/fonts/rounded_zh.tres")

static func stage_color(stage: int) -> Color:
	var colors: PackedColorArray=SKIN.get("stage_colors")
	if colors.is_empty(): return Color.WHITE
	return colors[clampi(stage,0,colors.size()-1)]

static func garden_style(_stage: int) -> StyleBox:
	# The desk keeps one material identity; stage colors belong to the landscape.
	return asset_style("panel_garden")

static func emphasis_font() -> Font:
	var font=font_for_locale().duplicate()
	font.variation_embolden=0.35
	return font

static func data_font() -> Font:
	return preload("res://assets/fonts/NotoSansJP-Regular.otf") if TranslationServer.get_locale().begins_with("ja") else preload("res://assets/fonts/NotoSansSC-Regular.otf")
