extends "res://scripts/tooltip_button.gd"

@onready var artwork: TextureRect = $Artwork
@onready var title_label: Label = $Caption/Title
@onready var status_label: Label = $Status
var time: float = 0.0
var active: bool = false
var available: bool = false
var artwork_rest: Vector2

func _ready() -> void:
	artwork.texture = preload("res://scripts/foreground_art.gd").fitted(artwork.texture)
	artwork_rest = artwork.position
	refresh()

func refresh() -> void:
	visible=GameState.burst_unlocked()
	active=GameState.burst_remaining>0
	available=GameState.burst_ready()
	disabled=GameState.paused or not available
	var hint: String
	if active:
		hint=tr("加速中 · 还剩 %s 秒") % str(int(ceil(GameState.burst_remaining)))
	elif available:
		hint=tr("点击生长药剂，临时收益 ×3")
	else:
		var cooldown: int=int(ceil(maxf(0,float(GameState.balance.get("burst",{}).get("cooldown",0))-GameState.burst_charge)))
		hint=tr("%s 秒后可用") % str(cooldown)
	title_label.text=tr("加速 ×%s") % str(int(GameState.balance.burst.multiplier))
	if active:
		status_label.text=tr("剩余 %s 秒") % str(int(ceil(GameState.burst_remaining)))
	elif available:
		status_label.text=""
	else:
		status_label.text=tr("冷却 %s 秒") % str(int(ceil(maxf(0,float(GameState.balance.burst.cooldown)-GameState.burst_charge))))
	status_label.visible=not available
	tooltip_text=tr("生长药剂")+"\n"+hint
	set_meta("action_label",tooltip_text)
	artwork.modulate=Color.WHITE if available or active else Color(0.58,0.60,0.53,0.85)
	queue_redraw()

func _process(delta: float) -> void:
	if not GameState.reduced_motion and not GameState.paused:
		time += delta
		artwork.position.y = artwork_rest.y + (sin(time * 2.2) * 1.5 if available or active else 0.0)
		artwork.pivot_offset = artwork.size * 0.5
		artwork.rotation = sin(time * 1.7) * 0.035 if active else 0.0
	else:
		artwork.position = artwork_rest
		artwork.rotation = 0.0
	if visible: queue_redraw()

func _draw() -> void:
	if not available and not active: return
	var center: Vector2=artwork.position+artwork.size*0.5
	var radius: float=artwork.size.x*0.5
	var pulse: float=0.5 if GameState.reduced_motion or GameState.paused else 0.5+sin(time*3)*0.5
	draw_circle(center,radius+2,Color(0.89,0.79,0.39,0.10+pulse*0.06))
	draw_arc(center,radius+1,-PI*0.5,TAU*(clampf(GameState.burst_remaining/float(GameState.balance.burst.duration),0,1) if active else 1)-PI*0.5,48,Color(0.92,0.83,0.48,0.7),1.5,true)
	if available:
		for index in range(2):
			var point: Vector2 = center + Vector2(-radius if index == 0 else radius, -16 if index == 0 else -7)
			var sparkle: float = 0.6 + 0.4 * sin(time * 2.8 + index * PI) if not GameState.reduced_motion and not GameState.paused else 0.8
			draw_line(point-Vector2(3 * sparkle,0),point+Vector2(3 * sparkle,0),Color(0.95,0.88,0.57,0.7),1.5,true)
			draw_line(point-Vector2(0,3 * sparkle),point+Vector2(0,3 * sparkle),Color(0.95,0.88,0.57,0.7),1.5,true)
