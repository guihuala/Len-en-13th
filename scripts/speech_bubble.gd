extends Panel

var remaining: float = 0.0
var reveal_tween: Tween

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	$HintLabel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	$HintLabel.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	$HintLabel.max_lines_visible=2
	$HintLabel.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	resized.connect(layout_text)
	hide()

func dismiss() -> void:
	remaining=0
	if reveal_tween!=null and reveal_tween.is_valid(): reveal_tween.kill()
	modulate.a=1
	hide()

func say(text: String, duration: float = 4.5) -> void:
	if GameState.paused or text.is_empty():
		dismiss()
		return
	var appearing: bool=not visible or remaining<=0
	$HintLabel.text=text
	tooltip_text=text
	remaining=duration
	layout_text()
	layout_text.call_deferred()
	show()
	if reveal_tween!=null and reveal_tween.is_valid(): reveal_tween.kill()
	modulate.a=1
	if appearing and not GameState.reduced_motion:
		modulate.a=0
		reveal_tween=create_tween()
		reveal_tween.tween_property(self,"modulate:a",1.0,0.16)

func replace_text(text: String) -> void:
	# Live countdowns and changing remarks keep their remaining display time.
	$HintLabel.text=text
	tooltip_text=text
	layout_text()
	layout_text.call_deferred()

func reserved_height() -> float:
	var label: Label=$HintLabel
	var font: Font=label.get_theme_font("font")
	var line_height: float=font.get_height(label.get_theme_font_size("font_size"))+label.get_theme_constant("line_spacing")
	return offset_top+line_height*2+22+14

func layout_text() -> void:
	if not is_node_ready(): return
	var label: Label=$HintLabel
	var width: float=maxf(1,size.x-28)
	label.position=Vector2(14,10)
	label.size.x=width
	var font: Font=label.get_theme_font("font")
	var font_size: int=label.get_theme_font_size("font_size")
	var text_size: Vector2=font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size)
	var line_height: float=font.get_height(font_size)+label.get_theme_constant("line_spacing")
	var height: float=minf(maxf(label.get_minimum_size().y,text_size.y),line_height*2)+22
	if not is_equal_approx(size.y,height): offset_bottom=offset_top+height
	label.size=Vector2(width,height-20)
	queue_redraw()

func _notification(what: int) -> void:
	if what==NOTIFICATION_THEME_CHANGED and is_node_ready(): layout_text.call_deferred()

func _process(delta: float) -> void:
	if GameState.paused:
		dismiss()
		return
	remaining=maxf(0,remaining-delta)
	if remaining<=0: hide()

