extends "res://scripts/tooltip_button.gd"

var collapsed: bool=false
var fold: float=1.0
var fold_tween: Tween

func _ready() -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	add_theme_color_override("font_hover_color",Color("7d6037"))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func set_collapsed(value: bool) -> void:
	if collapsed==value: return
	collapsed=value
	if fold_tween!=null and fold_tween.is_valid(): fold_tween.kill()
	var target: float=-1.0 if collapsed else 1.0
	if GameState.reduced_motion:
		set_fold(target)
		return
	fold_tween=create_tween()
	fold_tween.tween_method(set_fold,fold,target,0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_fold(value: float) -> void:
	fold=value
	queue_redraw()

func _process(_delta: float) -> void:
	if GameState.reduced_motion and fold_tween!=null and fold_tween.is_running():
		fold_tween.kill()
		set_fold(-1.0 if collapsed else 1.0)

func _draw() -> void:
	var center: Vector2=size*0.5
	var direction: float=fold
	var color: Color=get_theme_color("font_hover_color" if is_hovered() or has_focus() else "font_color")
	var points: PackedVector2Array=PackedVector2Array([
		center+Vector2(-8,-4*direction),
		center+Vector2(0,4*direction),
		center+Vector2(8,-4*direction)
	])
	draw_polyline(points,color,3.0 if has_focus() else 2.5,true)
