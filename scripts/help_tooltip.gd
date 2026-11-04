extends RefCounted

# Godot supplies the single TooltipPanel; custom content must not add another paper.
static func make(text: String, width: float = 280) -> Control:
	var margin=MarginContainer.new()
	margin.theme=preload("res://scripts/ui_theme.gd").create()
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,4)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,2)
	var label=RichTextLabel.new()
	preload("res://scripts/help_typography.gd").configure(label)
	label.text=preload("res://scripts/help_typography.gd").rich_text(text)
	label.custom_minimum_size.x=width
	label.size.x=width
	margin.add_child(label)
	return margin
