extends Control

var amount: float=1.0
var origin: Vector2
var ripple: Tween

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func play() -> void:
	if GameState.reduced_motion:
		if ripple and ripple.is_valid(): ripple.kill()
		amount=1
		queue_redraw()
		return
	if ripple and ripple.is_valid(): ripple.kill()
	origin=get_local_mouse_position()
	if not Rect2(Vector2.ZERO,size).has_point(origin): origin=size/2
	amount=0
	set_process(true)
	ripple=create_tween()
	ripple.tween_property(self,"amount",1.0,0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ripple.tween_callback(queue_redraw)

func _process(_delta: float) -> void:
	var button=get_parent() as Button
	if button and (button.disabled or GameState.reduced_motion):
		var transform_tween=button.get_meta("press_tween") if button.has_meta("press_tween") else null
		if transform_tween is Tween and transform_tween.is_valid(): transform_tween.kill()
		button.scale=Vector2.ONE
	if GameState.reduced_motion:
		if ripple and ripple.is_valid(): ripple.kill()
		amount=1
	if amount<1 or GameState.reduced_motion: queue_redraw()

func _draw() -> void:
	if amount>=1: return
	var radius: float=lerpf(5.0,size.length()*0.65,amount)
	draw_circle(origin,radius,Color(0.94,0.82,0.56,(1.0-amount)*0.20))
	draw_arc(origin,radius,0,TAU,48,Color(1.0,0.93,0.72,(1.0-amount)*0.42),1.5,true)
