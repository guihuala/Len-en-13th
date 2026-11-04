extends Node

# One short, bounded nudge per cultivation click; rapid clicks never add amplitude.
const DURATION: float = 0.15
const AMPLITUDE: float = 1.8
var remaining: float = 0.0
var offset: Vector2 = Vector2.ZERO

func trigger() -> void:
	if GameState.reduced_motion or GameState.paused:
		clear_effects()
		return
	remaining=DURATION
	apply_offset(Vector2(AMPLITUDE,0))

func apply_offset(value: Vector2) -> void:
	var viewport=get_viewport()
	var transform=viewport.canvas_transform
	transform.origin+=value-offset
	viewport.canvas_transform=transform
	offset=value

func clear_effects() -> void:
	remaining=0.0
	apply_offset(Vector2.ZERO)

func _process(delta: float) -> void:
	if GameState.reduced_motion or GameState.paused:
		if remaining>0 or offset!=Vector2.ZERO: clear_effects()
		return
	if remaining<=0: return
	remaining=maxf(0.0,remaining-delta)
	if remaining<=0:
		clear_effects()
		return
	var progress: float=1.0-remaining/DURATION
	var envelope: float=pow(1.0-progress,2.0)
	apply_offset(Vector2(cos(progress*TAU*2.0),sin(progress*TAU*2.0)*0.35)*AMPLITUDE*envelope)

func _exit_tree() -> void:
	clear_effects()
