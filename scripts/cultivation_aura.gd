extends ColorRect

const TINTS = [Color("a2d9dc"), Color("d3c28f"), Color("b3d49e"), Color("bacfa0"), Color("d9ddb4"), Color("e4ce9e"), Color("e6dab1")]
const ROOT_TEXTURE = preload("res://assets/art/regions/tree__action_roots.tres")
var root_marks: Array[TextureRect] = []
var taps: Array[Vector3] = [Vector3(0.5, 0.5, 2), Vector3(0.5, 0.5, 2), Vector3(0.5, 0.5, 2), Vector3(0.5, 0.5, 2)]
var cursor: int = 0
var action_stage: int = 0
var effect_time: float = 0.0
var boost: float = 0.0

func _ready() -> void:
	for i in range(taps.size()):
		var roots=TextureRect.new()
		roots.name="AtlasRoots%d" % i
		roots.texture=ROOT_TEXTURE
		roots.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		roots.mouse_filter=Control.MOUSE_FILTER_IGNORE
		roots.hide()
		add_child(roots)
		root_marks.append(roots)

func trigger(origin: Vector2, stage: int) -> void:
	if GameState.reduced_motion or GameState.paused: return
	action_stage = clampi(stage, 0, 6)
	if action_stage in [1, 3]: origin.y = maxf(origin.y, 0.76)
	material.set_shader_parameter("action_stage", action_stage)
	taps[cursor] = Vector3(origin.x, origin.y, 0.0)
	cursor = (cursor + 1) % taps.size()
	material.set_shader_parameter("action_tint", TINTS[clampi(stage, 0, 6)])

func clear_effects() -> void:
	for roots in root_marks: roots.hide()
	for i in range(taps.size()):
		taps[i].z = 2.0
		material.set_shader_parameter("tap_%d" % i, taps[i])
	boost = 0.0
	visible = false
	material.set_shader_parameter("boost", 0.0)

func advance(delta: float) -> void:
	if GameState.reduced_motion or GameState.paused:
		clear_effects()
		visible = false
		return
	effect_time += delta
	boost = move_toward(boost, 1.0 if GameState.burst_remaining > 0 else 0.0, delta * 2.0)
	var active: bool = boost > 0.001
	for i in range(taps.size()):
		taps[i].z = minf(2.0, taps[i].z + delta / 0.85)
		active = active or taps[i].z < 1.0
		material.set_shader_parameter("tap_%d" % i, taps[i])
		var roots: TextureRect=root_marks[i]
		roots.visible=action_stage==3 and taps[i].z<1.0
		if roots.visible:
			var age: float=taps[i].z
			var aspect: float=ROOT_TEXTURE.get_height()/ROOT_TEXTURE.get_width()
			var width: float=minf(minf(size.x*0.74,220.0),size.y*0.85/aspect)*(0.94+0.06*minf(age*5.0,1.0))
			roots.size=Vector2(width,width*aspect)
			var anchor: Vector2=Vector2(taps[i].x,taps[i].y)*size-roots.size*Vector2(0.5,0.2)
			roots.position=anchor.clamp(Vector2.ZERO,(size-roots.size).max(Vector2.ZERO))
			roots.modulate.a=smoothstep(0.0,0.08,age)*(1.0-smoothstep(0.55,1.0,age))*0.9
	visible = active
	material.set_shader_parameter("area_size", size.max(Vector2.ONE))
	material.set_shader_parameter("effect_time", effect_time)
	material.set_shader_parameter("boost", boost)
