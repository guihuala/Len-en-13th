extends ColorRect

const TINTS = [Color("a2d9dc"), Color("d3c28f"), Color("b3d49e"), Color("bacfa0"), Color("d9ddb4"), Color("e4ce9e"), Color("e6dab1")]
var taps: Array[Vector3] = [Vector3(0.5, 0.5, 2), Vector3(0.5, 0.5, 2), Vector3(0.5, 0.5, 2), Vector3(0.5, 0.5, 2)]
var cursor: int = 0
var action_stage: int = 0
var effect_time: float = 0.0
var boost: float = 0.0

func trigger(origin: Vector2, stage: int) -> void:
	if GameState.reduced_motion or GameState.paused: return
	action_stage = clampi(stage, 0, 6)
	if action_stage in [1, 3]: origin.y = maxf(origin.y, 0.76)
	material.set_shader_parameter("action_stage", action_stage)
	taps[cursor] = Vector3(origin.x, origin.y, 0.0)
	cursor = (cursor + 1) % taps.size()
	material.set_shader_parameter("action_tint", TINTS[clampi(stage, 0, 6)])

func clear_effects() -> void:
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
	visible = active
	material.set_shader_parameter("area_size", size.max(Vector2.ONE))
	material.set_shader_parameter("effect_time", effect_time)
	material.set_shader_parameter("boost", boost)
