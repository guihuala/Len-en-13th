extends RefCounted

static func escaped(value: String) -> String:
	return value.replace("[","[lb]")

static func rich_text(text: String, flavor: String = "") -> String:
	var lines=text.split("\n",true)
	if lines.size()==1:
		return "[font_size=14][color=#45543b]"+escaped(text)+"[/color][/font_size]"
	var result: String="[font_size=20][b][color=#344b30]"+escaped(lines[0])+"[/color][/b][/font_size]\n"
	result+="[font_size=16][b][color=#526e40]"+escaped(lines[1])+"[/color][/b][/font_size]\n"
	var remaining: String="\n".join(lines.slice(2))
	if not flavor.is_empty() and remaining.begins_with(flavor):
		result+="[font_size=16][color=#514731]"+escaped(flavor)+"[/color][/font_size]"
		remaining=remaining.substr(flavor.length())
	result+="[font_size=14][color=#61674f]"+escaped(remaining)+"[/color][/font_size]"
	var footnote: String=str(TranslationServer.translate("仅按常态自动产量估算，不含手动操作和临时加速。"))
	result=result.replace(escaped(footnote),"[font_size=12][color=#716d5c]"+escaped(footnote)+"[/color][/font_size]")
	return result

static func configure(label: RichTextLabel) -> void:
	var ui=preload("res://scripts/ui_theme.gd")
	label.bbcode_enabled=true
	label.fit_content=true
	label.scroll_active=false
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("normal_font",ui.font_for_locale())
	label.add_theme_font_override("bold_font",ui.emphasis_font())
	label.add_theme_font_size_override("normal_font_size",16)
	label.add_theme_font_size_override("bold_font_size",20)
	label.add_theme_constant_override("line_separation",5)
