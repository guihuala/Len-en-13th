extends PanelContainer

const Motion = preload("res://scripts/motion.gd")
var remaining: float = 0

func present(message: String) -> void:
	$Result.text=message
	remaining=4
	update_visibility()

func dismiss() -> void:
	remaining=0
	hide()

func update_visibility() -> void:
	var allowed: bool=remaining>0 and not GameState.paused and GameState.pending.is_empty()
	if allowed and not visible:
		show()
		Motion.reveal(self,0.16)
	elif not allowed:
		hide()

func _process(delta: float) -> void:
	update_visibility()
	# The purchase result waits until the original story or purchase joke closes.
	if visible:
		remaining=maxf(0,remaining-delta)
		if remaining<=0: hide()
