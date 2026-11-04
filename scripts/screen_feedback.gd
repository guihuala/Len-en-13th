extends CanvasLayer

@onready var glow: ColorRect = $Glow
var fade: Tween

func trigger() -> void:
	if GameState.reduced_motion or GameState.paused:
		clear_effects()
		return
	# Cap intensity even when the player taps rapidly.
	if fade != null and fade.is_running(): return
	fade = create_tween()
	fade.tween_property(glow, "modulate:a", 0.035, 0.06).set_trans(Tween.TRANS_SINE)
	fade.tween_property(glow, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func clear_effects() -> void:
	if fade != null: fade.kill()
	glow.modulate.a = 0.0

func _process(_delta: float) -> void:
	if GameState.reduced_motion or GameState.paused: clear_effects()
