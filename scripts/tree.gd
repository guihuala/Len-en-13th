extends Control

signal watered

const FORMS = [
	"stage_01_potted", "stage_02_growth", "stage_03_branching",
	"stage_04_incident", "stage_05_flowering", "stage_06_nursery", "stage_07_forest"
]
const LEAF_BUD_FORM = "stage_02a_leaf_bud"
const HATCHING_FORM = "stage_02b_hatching"
const MINI_TEXTURE = preload("res://assets/art/regions/tree__mini_tabinoki.tres")
const TreeRig = preload("res://scripts/tree_rig.gd")
const BOUNDS = [Rect2(70,80,340,390),Rect2(90,90,300,380),Rect2(50,35,380,435),Rect2(5,0,470,478),Rect2(5,0,470,478),Rect2(5,0,470,478),Rect2(5,0,470,478)]
const ANCHORS = [Vector2(240,325),Vector2(240,220),Vector2(240,130),Vector2(240,105),Vector2(240,240),Vector2(240,240),Vector2(240,240)]

var water_overlay: Node2D
var action_overlay: ColorRect
var art_root: Control
var current_layer: TextureRect
var previous_layer: TextureRect
var ending_group: Control
var current_stage: int = -1
var current_variant: int = 0
var previous_stage: int = 0
var transition_active: bool = false
var transition_tween: Tween
var ending_tween: Tween
var ending_shown: bool = false
var time: float = 0
var drops: Array = []
var water_ripples: Array = []
var local_rig: Node2D
var previous_rig: Node2D
var interaction_age: float = 2.0

func _ready() -> void:
	clip_contents=true
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	focus_mode=Control.FOCUS_ALL
	gui_input.connect(_input_tree)
	art_root=Control.new()
	art_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art_root)
	previous_layer=make_layer()
	current_layer=make_layer()
	ending_group=Control.new()
	ending_group.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ending_group)
	water_overlay=Node2D.new()
	add_child(water_overlay)
	water_overlay.draw.connect(draw_water_overlay)
	action_overlay=$CultivationFX
	set_stage(GameState.stage,false)
	GameState.changed.connect(sync_growth_visual)
	sync_ending(false)

func make_layer() -> TextureRect:
	var layer=TextureRect.new()
	layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode=TextureRect.STRETCH_SCALE
	layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art_root.add_child(layer)
	return layer

func _input_tree(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		watered.emit()
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		watered.emit()
		accept_event()

func fit_into(area: Rect2) -> void:
	position=area.position
	size=area.size
	scale=Vector2.ONE
	if current_layer==null: return
	if current_stage!=GameState.stage or current_variant!=variant_for_stage(GameState.stage): set_stage(GameState.stage)
	layout_layers()
	sync_ending()

func layer_rect(stage: int) -> Rect2:
	var bounds: Rect2=BOUNDS[stage]
	# Reserve a little space so transition / watering squash stays within the panel.
	var factor: float=minf(size.x/bounds.size.x,size.y/bounds.size.y)*0.94
	return Rect2(size/2-bounds.get_center()*factor,Vector2(480,480)*factor)

func layout_layers() -> void:
	if current_stage<0: return
	art_root.size=size
	art_root.pivot_offset=size/2 if current_stage>=4 else Vector2(size.x*0.5,size.y*0.90)
	place_layer(current_layer,current_stage)
	place_layer(previous_layer,previous_stage)
	if local_rig!=null: local_rig.scale=current_layer.size/480.0
	if previous_rig!=null: previous_rig.scale=previous_layer.size/480.0
	ending_group.size=size

func place_layer(layer: TextureRect, stage: int) -> void:
	var rect=layer_rect(stage)
	layer.position=rect.position
	layer.size=rect.size
	layer.pivot_offset=rect.size*Vector2(0.5,0.5 if stage>=4 else 0.91)

func variant_for_stage(stage: int) -> int:
	if stage!=1: return 0
	var start: float=float(GameState.THRESHOLDS[1])
	var end: float=float(GameState.THRESHOLDS[2])
	var progress: float=clampf((GameState.lifetime-start)/maxf(end-start,1.0),0.0,1.0)
	return 2 if progress>=0.70 else (1 if progress>=0.35 else 0)

func sync_growth_visual() -> void:
	set_stage(GameState.stage)

func form_for_stage(stage: int, variant: int) -> String:
	if stage==1:
		if variant==1: return LEAF_BUD_FORM
		if variant==2: return HATCHING_FORM
	return FORMS[stage]

func set_stage(stage: int, animate: bool = true) -> void:
	stage=clampi(stage,0,FORMS.size()-1)
	var variant: int=variant_for_stage(stage)
	if stage==current_stage and variant==current_variant: return
	if transition_tween!=null and transition_tween.is_valid(): transition_tween.kill()
	var old_stage: int=current_stage
	# Old actions should not float over the next form after a chapter change.
	drops.clear()
	water_ripples.clear()
	if action_overlay!=null: action_overlay.clear_effects()
	var old_alpha: float=current_layer.modulate.a
	clear_previous_rig()
	if old_stage>=0:
		previous_layer.set_meta("form",current_layer.get_meta("form"))
		previous_stage=old_stage
		if local_rig!=null:
			# Keep the preceding hand-painted form throughout the fade.
			current_layer.remove_child(local_rig)
			previous_layer.add_child(local_rig)
			previous_rig=local_rig
			local_rig=null
			previous_layer.self_modulate.a=0
	current_stage=stage
	current_variant=variant
	current_layer.set_meta("form",form_for_stage(stage,variant))
	if local_rig!=null:
		current_layer.remove_child(local_rig)
		local_rig.queue_free()
	local_rig=TreeRig.new()
	current_layer.add_child(local_rig)
	if local_rig.configure(form_for_stage(stage,variant)):
		current_layer.self_modulate.a=0
		local_rig.pose(time,GameState.reduced_motion)
	else:
		local_rig.queue_free()
		local_rig=null
		push_error("Unable to load hand-painted tree form: "+form_for_stage(stage,variant))
	current_layer.rotation=0
	previous_layer.rotation=0
	current_layer.scale=Vector2.ONE
	previous_layer.scale=Vector2.ONE
	layout_layers()
	if not animate or old_stage<0 or GameState.reduced_motion:
		previous_layer.hide()
		clear_previous_rig()
		current_layer.modulate.a=1
		transition_active=false
		return
	transition_active=true
	previous_layer.show()
	previous_layer.modulate.a=old_alpha
	current_layer.modulate.a=0
	var duration: float=0.55 if old_stage==stage else 0.40
	transition_tween=create_tween().set_parallel(true)
	transition_tween.tween_property(previous_layer,"modulate:a",0.0,duration*0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(current_layer,"modulate:a",1.0,duration*0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	transition_tween.finished.connect(finish_transition)

func clear_previous_rig() -> void:
	if previous_rig!=null:
		previous_layer.remove_child(previous_rig)
		previous_rig.queue_free()
		previous_rig=null
	previous_layer.self_modulate.a=1

func finish_transition() -> void:
	previous_layer.hide()
	clear_previous_rig()
	current_layer.modulate.a=1
	current_layer.scale=Vector2.ONE
	transition_active=false

func sync_ending(_animate: bool = true) -> void:
	# Returning from the fictional broadcast keeps the existing cultivation view.
	ending_group.hide()

func feedback_local_position() -> Vector2:
	var anchor: Vector2=Vector2(240,195) if current_stage==1 and current_variant==2 else ANCHORS[current_stage]
	return get_global_transform().affine_inverse()*(current_layer.get_global_transform()*(anchor*current_layer.size/480.0))

func get_feedback_position() -> Vector2:
	return get_global_transform()*feedback_local_position()

func splash(action_stage: int = -1) -> void:
	if local_rig!=null:
		local_rig.react(interaction_age<0.45)
		local_rig.pose(time,GameState.reduced_motion)
	interaction_age=0.0
	if GameState.reduced_motion: return
	var origin=feedback_local_position()
	var effect_stage: int=current_stage if action_stage<0 else clampi(action_stage,0,6)
	action_overlay.trigger(origin / size.max(Vector2.ONE), effect_stage)

func _process(delta: float) -> void:
	if action_overlay!=null: action_overlay.advance(delta)
	interaction_age=minf(interaction_age+delta,2.0)
	if local_rig!=null: local_rig.advance_reaction(delta)
	if GameState.reduced_motion:
		if transition_active:
			if transition_tween!=null and transition_tween.is_valid(): transition_tween.kill()
			finish_transition()
		art_root.rotation=0
		art_root.scale=Vector2.ONE
		art_root.position=Vector2.ZERO
		drops.clear()
		water_ripples.clear()
	else:
		time+=delta
		animate_stage()
	if local_rig!=null: local_rig.pose(time,GameState.reduced_motion)
	for d in drops:
		d.life-=delta
		if d.landed: continue
		# Integrate acceleration analytically so arcs do not change with frame rate.
		d.p+=d.v*delta+Vector2(0,0.5*float(d.gravity)*delta*delta)
		d.v.y+=delta*float(d.gravity)
		if d.v.y>0 and d.p.y>=float(d.floor):
			d.p.y=d.floor
			d.landed=true
			d.life=minf(float(d.life),0.14)
	drops=drops.filter(func(d): return d.life>0)
	for ripple in water_ripples: ripple.age+=delta
	water_ripples=water_ripples.filter(func(r): return r.age<0.62)
	queue_redraw()
	water_overlay.queue_redraw()

func animate_stage() -> void:
	# Ground, trunk, foliage and globe remain fixed; the rig moves heads only.
	art_root.rotation=0
	art_root.scale=Vector2.ONE
	art_root.position=Vector2.ZERO

func _draw() -> void:
	if not GameState.reduced_motion and current_stage>0:
		draw_stage_particles()

func draw_water_overlay() -> void:
	# Flies and water sit above the painted form instead of disappearing behind it.
	if current_stage==0 and not GameState.reduced_motion: draw_flies()
	for ripple in water_ripples:
		for ring in range(2):
			var age: float=float(ripple.age)-ring*0.085
			if age<0 or age>0.45: continue
			var progress: float=age/0.45
			var alpha: float=pow(1.0-progress,2)*0.48
			var radius: float=lerpf(10,58,1.0-pow(1.0-progress,2))*float(ripple.scale)
			water_overlay.draw_set_transform(ripple.p,0,Vector2(1,0.38))
			water_overlay.draw_arc(Vector2.ZERO,radius,0,TAU,48,Color(0.33,0.72,0.86,alpha),1.6*float(ripple.scale),true)
	water_overlay.draw_set_transform(Vector2.ZERO)
	for d in drops:
		var alpha: float=minf(1.0,float(d.life)/0.22)
		var radius: float=float(d.radius)*lerpf(0.65,1.0,float(d.life)/float(d.duration))
		if d.landed:
			var spread: float=1.0-float(d.life)/0.14
			water_overlay.draw_set_transform(d.p,0,Vector2(1,0.3))
			water_overlay.draw_arc(Vector2.ZERO,radius*(1.0+spread*2.0),0,TAU,20,Color(0.48,0.76,0.81,alpha*0.55),0.9,true)
			continue
		var velocity: Vector2=d.v
		var stretch: float=clampf(velocity.length()/160.0,0.85,1.8)
		water_overlay.draw_set_transform(d.p,velocity.angle()-PI*0.5,Vector2(1,stretch))
		# Rounded head and tapered tail follow the flight direction.
		water_overlay.draw_colored_polygon(PackedVector2Array([
			Vector2(0,-radius*2.1),Vector2(radius*0.8,-radius*0.35),
			Vector2(radius,radius*0.35),Vector2(radius*0.65,radius*0.95),
			Vector2(0,radius*1.15),Vector2(-radius*0.65,radius*0.95),
			Vector2(-radius,radius*0.35),Vector2(-radius*0.8,-radius*0.35)
		]),Color(0.36,0.67,0.77,alpha*0.85))
		water_overlay.draw_line(Vector2(-radius*0.35,0),Vector2(-radius*0.25,radius*0.5),Color(0.9,0.98,0.96,alpha*0.9),maxf(0.7,radius*0.3),true)
	water_overlay.draw_set_transform(Vector2.ZERO)

func fly_position(index: int, at_time: float) -> Vector2:
	var phase: float=at_time*(0.72+index*0.13)+index*1.87
	# Each fly accelerates, hovers and changes direction on its own route.
	var orbit: Vector2=Vector2(sin(phase+sin(phase*0.73)*0.8)*(72+index*10),cos(phase*1.31+index)*26)
	orbit+=Vector2(sin(at_time*4.1+index*2.3),cos(at_time*3.3+index))*3.5
	var scatter: float=sin(clampf(interaction_age/0.8,0,1)*PI)*24.0
	orbit+=Vector2(orbit.x,-32).normalized()*scatter
	return current_layer.position+(Vector2(240,275)+orbit)*current_layer.size/480.0

func draw_flies() -> void:
	var unit: float=clampf(minf(size.x,size.y)/280.0,0.65,1.2)
	for i in range(4):
		var point: Vector2=fly_position(i,time)
		var direction: Vector2=fly_position(i,time+0.025)-point
		var facing: float=clampf(direction.angle(),-PI,PI)
		var wing: float=0.55+absf(sin(time*(42+i*3)+i))*0.65
		water_overlay.draw_set_transform(point,facing,Vector2.ONE*unit)
		for side in [-1,1]:
			water_overlay.draw_set_transform(point+Vector2(0,side*1.6).rotated(facing)*unit,facing+side*0.35,Vector2(1.7,wing)*unit)
			water_overlay.draw_circle(Vector2.ZERO,1.8,Color(0.91,0.94,0.84,0.58))
		water_overlay.draw_set_transform(point,facing,Vector2(1.35,0.85)*unit)
		water_overlay.draw_circle(Vector2.ZERO,1.65,Color("625943"))
		water_overlay.draw_circle(Vector2(1.4,0),1.05,Color("403e32"))
	water_overlay.draw_set_transform(Vector2.ZERO)

func draw_stage_particles() -> void:
	for i in range(5):
		var phase: float=time*(0.35+current_stage*0.03)+i*1.47
		var point: Vector2=Vector2(size.x*(0.12+i*0.18)+sin(phase)*7,size.y*(0.15+fmod(i*0.21,0.58))+cos(phase*0.8)*6)
		match current_stage:
			1:
				var alpha: float=0.35+sin(phase*2)*0.25
				draw_line(point-Vector2(3,0),point+Vector2(3,0),Color(0.83,0.95,0.78,alpha),1.3)
				draw_line(point-Vector2(0,3),point+Vector2(0,3),Color(0.83,0.95,0.78,alpha),1.3)
			2:
				point.y=fmod(time*10+i*size.y/5.0,size.y)
				draw_set_transform(point,sin(phase)*0.8)
				var edge_fade: float=clampf(minf(point.y,size.y-point.y)/18.0,0,1)
				draw_colored_polygon(PackedVector2Array([Vector2(0,-5),Vector2(2.5,-2),Vector2(3,1),Vector2(0,5),Vector2(-2.5,2),Vector2(-3,-1)]),Color(0.62,0.74,0.42,edge_fade*0.8))
				draw_line(Vector2(0,-3),Vector2(0,3),Color(0.4,0.55,0.29,edge_fade*0.6),0.7,true)
			3:
				if i<2:
					var wave: float=fmod(time*0.5+i*0.5,1.0)
					draw_arc(Vector2(size.x*0.5,size.y*0.87),size.x*(0.16+wave*0.20),0,PI,24,Color(0.70,0.82,0.51,(1.0-wave)*0.3),1.5)
			4:
				point.y=fmod(time*14+i*size.y/5.0,size.y)
				draw_set_transform(point,phase,Vector2(1,0.55))
				draw_circle(Vector2.ZERO,4,Color(0.78,0.90,0.52,clampf(minf(point.y,size.y-point.y)/18.0,0,1)*0.65))
			5:
				point.y=size.y*0.83-fmod(time*9+i*23,size.y*0.65)
				draw_circle(point,2.4,Color(0.85,0.92,0.57,0.45+sin(phase)*0.25))
			6:
				var alpha: float=0.45+sin(phase*2)*0.35
				draw_circle(point,5,Color(0.98,0.92,0.55,alpha*0.10))
				draw_circle(point,1.8,Color(0.98,0.92,0.55,alpha))
		draw_set_transform(Vector2.ZERO)
