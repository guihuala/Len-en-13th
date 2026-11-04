extends Panel

func _make_custom_tooltip(for_text: String) -> Object:
	return preload("res://scripts/help_tooltip.gd").make(for_text,minf(280,get_viewport_rect().size.x-56))
