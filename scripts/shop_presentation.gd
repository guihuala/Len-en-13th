extends RefCounted

const UITheme = preload("res://scripts/ui_theme.gd")

static func apply(button: Button, state: String, bulk: bool = false) -> void:
	# Reuse the painted nine-slice borders; only tint the existing paper surfaces.
	if button.get_meta("shop_state","")==state and button.get_meta("shop_bulk",false)==bulk: return
	button.set_meta("shop_state",state)
	button.set_meta("shop_bulk",bulk)
	button.add_theme_font_size_override("font_size",12)
	for slot in ["normal","hover","pressed","disabled"]:
		var style=UITheme.asset_style("button_primary" if state=="ready" else "button_disabled")
		if state=="ready":
			style=UITheme.asset_style({"normal":"button_primary","hover":"button_primary_hover","pressed":"button_primary_pressed","disabled":"button_primary"}[slot])
			style.modulate_color=Color.WHITE
		elif state=="short":
			style.modulate_color=Color(1.0,0.96,0.89)
		style.content_margin_top=2
		style.content_margin_bottom=2
		button.add_theme_stylebox_override(slot,style)
	var ink: Color=Color("2f402b") if state=="ready" else Color("414530")
	if state=="short": ink=Color("79503a")
	elif state=="locked": ink=Color("59624f")
	elif state=="complete": ink=Color("455a3c")
	for slot in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
		button.add_theme_color_override(slot,ink)

static func unlock_hint(item: Dictionary, target: String, full_title: bool = false) -> String:
	if GameState.clicks<3: return localized("先培养3次")
	var stage: int=int(item.get("shop_stage",0))
	if GameState.stage<stage:
		return localized("到达：%s") % localized(str(GameState.balance.stage_tabs[stage]))
	var event_id: String=str(item.get("requires_event",""))
	if not event_id.is_empty() and event_id not in GameState.triggered:
		var title: String=str(GameState.balance.stage_tabs[stage])
		if full_title:
			for event in GameState.events:
				if event.id==event_id: title=str(event.title)
		return localized("完成剧情：%s") % localized(title)
	if item.id=="planet_core":
		return localized("累计达到%s") % target
	return localized("等待剧情")

static func localized(key: String) -> String:
	# Static helpers cannot call Object.tr(); use the translation service directly.
	return str(TranslationServer.translate(key))
