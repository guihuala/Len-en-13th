extends "res://scripts/tooltip_button.gd"

var collapsed: bool=false

func _ready() -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	add_theme_color_override("font_hover_color",Color("7d6037"))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func set_collapsed(value: bool) -> void:
	collapsed=value
	queue_redraw()

func _draw() -> void:
	var center: Vector2=size*0.5
	var direction: float=-1.0 if collapsed else 1.0
	var color: Color=get_theme_color("font_hover_color" if is_hovered() or has_focus() else "font_color")
	var points: PackedVector2Array=PackedVector2Array([
		center+Vector2(-8,-4*direction),
		center+Vector2(0,4*direction),
		center+Vector2(8,-4*direction)
	])
	draw_polyline(points,color,3.0 if has_focus() else 2.5,true)
