extends RefCounted

static func reveal(control: Control, duration: float = 0.2) -> void:
	if GameState.reduced_motion:
		control.modulate.a=1
		return
	var previous = control.get_meta("reveal_tween") if control.has_meta("reveal_tween") else null
	if previous is Tween and previous.is_valid(): previous.kill()
	control.modulate.a=0
	var tween=control.create_tween()
	control.set_meta("reveal_tween",tween)
	tween.tween_property(control,"modulate:a",1.0,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

static func bind_button(button: Button) -> void:
	var feedback=button.get_node("ClickRipple")
	button.mouse_entered.connect(func(): hover(button,true))
	button.focus_entered.connect(func(): hover(button,true))
	button.focus_exited.connect(func(): hover(button,false))
	button.button_down.connect(func(): press(button))
	button.button_up.connect(func(): release(button))
	button.mouse_exited.connect(func(): hover(button,false))
	button.pressed.connect(func(): feedback.play())

static func animate_button(button: Button, target: Vector2, duration: float) -> void:
	if not button.is_inside_tree(): return
	var old=button.get_meta("press_tween") if button.has_meta("press_tween") else null
	if old is Tween and old.is_valid(): old.kill()
	button.pivot_offset=button.size/2
	if GameState.reduced_motion or button.disabled or button.get_meta("stable_feedback_bounds",false):
		button.scale=Vector2.ONE
		return
	var tween=button.create_tween()
	button.set_meta("press_tween",tween)
	tween.tween_property(button,"scale",target,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func hover(button: Button, active: bool) -> void:
	button.set_meta("hovered",active)
	animate_button(button,Vector2.ONE*(1.025 if active else 1.0),0.14)

static func press(button: Button) -> void:
	animate_button(button,Vector2.ONE*0.955,0.07)

static func release(button: Button) -> void:
	animate_button(button,Vector2.ONE*(1.025 if button.get_meta("hovered",false) else 1.0),0.18)

static func pulse_icon(icon: Control) -> void:
	if GameState.reduced_motion: return
	var old=icon.get_meta("pulse_tween") if icon.has_meta("pulse_tween") else null
	if old is Tween and old.is_valid(): old.kill()
	icon.pivot_offset=icon.size/2
	icon.scale=Vector2.ONE
	var tween=icon.create_tween()
	icon.set_meta("pulse_tween",tween)
	tween.tween_property(icon,"scale",Vector2.ONE*1.18,0.10).set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon,"scale",Vector2.ONE,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
