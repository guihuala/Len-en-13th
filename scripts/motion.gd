extends RefCounted

static func stop(control: Control, key: String) -> void:
	var previous = control.get_meta(key) if control.has_meta(key) else null
	if previous is Tween and previous.is_valid(): previous.kill()

static func reveal(control: Control, duration: float = 0.2, delay: float = 0.0) -> void:
	stop(control,"reveal_tween")
	if GameState.reduced_motion:
		control.modulate.a=1
		return
	control.modulate.a=0
	var tween=control.create_tween()
	control.set_meta("reveal_tween",tween)
	if delay>0: tween.tween_interval(delay)
	tween.tween_property(control,"modulate:a",1.0,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

static func reveal_items(list: Control) -> void:
	var index: int=0
	for child in list.get_children():
		if child is Control and child.visible:
			reveal(child,0.18,index*0.045)
			index+=1

static func smooth_progress(bar: ProgressBar, target: float) -> void:
	var first: bool=not bar.has_meta("progress_target")
	var changed_range: bool=bar.get_meta("progress_max",-1.0)!=bar.max_value
	if not first and not changed_range and is_equal_approx(float(bar.get_meta("progress_target")),target): return
	stop(bar,"progress_tween")
	bar.set_meta("progress_target",target)
	bar.set_meta("progress_max",bar.max_value)
	if first or changed_range or GameState.reduced_motion:
		bar.value=target
		return
	var tween=bar.create_tween()
	bar.set_meta("progress_tween",tween)
	tween.tween_property(bar,"value",target,0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func tint(button: Button, color: Color, duration: float) -> void:
	stop(button,"tint_tween")
	if GameState.reduced_motion or button.disabled:
		button.self_modulate=Color.WHITE
		return
	var tween=button.create_tween()
	button.set_meta("tint_tween",tween)
	tween.tween_property(button,"self_modulate",color,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

static func settle(parent: Node) -> void:
	if parent is Control:
		if parent.has_meta("reveal_tween"):
			stop(parent,"reveal_tween")
			parent.modulate.a=1.0
		for key in ["press_tween","pulse_tween"]:
			if parent.has_meta(key):
				stop(parent,key)
				parent.scale=Vector2.ONE
		if parent.has_meta("tint_tween"):
			stop(parent,"tint_tween")
			parent.self_modulate=Color.WHITE
		if parent is ProgressBar and parent.has_meta("progress_target"):
			stop(parent,"progress_tween")
			parent.value=float(parent.get_meta("progress_target"))
	for child in parent.get_children(): settle(child)

static func bind_button(button: Button) -> void:
	if button.get_meta("motion_bound",false): return
	button.set_meta("motion_bound",true)
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
	tint(button,Color(1.025,1.035,0.97) if active else Color.WHITE,0.14)
	animate_button(button,Vector2.ONE*(1.025 if active else 1.0),0.14)

static func press(button: Button) -> void:
	tint(button,Color(0.93,0.96,0.87),0.07)
	animate_button(button,Vector2.ONE*0.955,0.07)

static func release(button: Button) -> void:
	tint(button,Color(1.025,1.035,0.97) if button.get_meta("hovered",false) else Color.WHITE,0.16)
	animate_button(button,Vector2.ONE*(1.025 if button.get_meta("hovered",false) else 1.0),0.18)

static func pulse_icon(icon: Control) -> void:
	if GameState.reduced_motion:
		stop(icon,"pulse_tween")
		icon.scale=Vector2.ONE
		return
	var old=icon.get_meta("pulse_tween") if icon.has_meta("pulse_tween") else null
	if old is Tween and old.is_valid(): old.kill()
	icon.pivot_offset=icon.size/2
	icon.scale=Vector2.ONE
	var tween=icon.create_tween()
	icon.set_meta("pulse_tween",tween)
	tween.tween_property(icon,"scale",Vector2.ONE*1.18,0.10).set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon,"scale",Vector2.ONE,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
