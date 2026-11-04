extends Control

# Contextual guidance only: no input lock, resource grants, or required purchase order.
const Motion = preload("res://scripts/motion.gd")
var host: Control
var coach: Panel
var heading: Label
var body: Label
var skip_button: Button
var done_button: Button
var highlight: Panel
var target: Control
var step: int = -1

func setup(view: Control) -> void:
	host=view
	# GUI hit testing follows sibling order, independently of visual z_index.
	host.move_child(self,-1)
	coach=$Coach
	heading=$Coach/Heading
	body=$Coach/Body
	skip_button=$Coach/SkipButton
	done_button=$Coach/DoneButton
	highlight=$Highlight
	skip_button.pressed.connect(GameState.finish_tutorial)
	done_button.pressed.connect(GameState.finish_tutorial)
	hide()

func current_step() -> int:
	if GameState.tutorial_done: return -1
	if GameState.clicks<3 or "sprout" not in GameState.triggered: return 0
	if int(GameState.counts.get("watering_can",0))==0: return 1
	if int(GameState.counts.get("drip_irrigation",0))==0: return 2
	return 3

func refresh() -> void:
	var old_step: int=step
	step=current_step()
	if step<0 or GameState.paused or not GameState.pending.is_empty() or not host.current_event.is_empty():
		hide()
		return
	show()
	target=host.tree
	match step:
		0:
			heading.text=tr("1/4浇三次水")
			body.text=tr("点击中央的旅之木进行培养。\n%d/3") % mini(GameState.clicks,3)
		1,2:
			var item: Dictionary=GameState.upgrades[0 if step==1 else 1]
			var cost: String=host.fmt(GameState.price(item))
			heading.text=tr("2/4买水壶" if step==1 else "3/4让它自己长")
			body.text=(tr("攒到%s生长值，购买「可疑的水壶」。\n每次浇水获得更多生长值。") if step==1 else tr("攒到%s，购买「自动滴灌」。\n不用持续点击也会增长。")) % cost
			if host.selected_shop_stage!=0:
				target=host.shop_selector
			elif GameState.growth>=GameState.price(item):
				target=host.shop_buttons[item.id]
			if host.shop_collapsed:
				target=host.ui.shop_toggle
				body.text=tr("展开道具栏继续购买。")
		3:
			heading.text=tr("4/4随便种吧")
			body.text=tr("自动设施达10／25／50组时收益翻倍。\n「凑整」批量购买；点下方药剂临时收益×3。")
			target=host.ui.burst
	skip_button.visible=step<3
	done_button.visible=step==3
	var rect: Rect2=target.get_global_rect().grow(3)
	if target==host.tree:
		# Highlight the character, leaving foreground props outside the target.
		rect=host.tree.get_global_rect().grow(-4)
	highlight.position=rect.position-global_position
	highlight.size=rect.size
	layout_coach(target.get_global_rect())
	if old_step!=step: Motion.reveal(coach,0.16)

func layout_coach(protected: Rect2) -> void:
	# Choose a fully visible position outside the current action, including its margin.
	var area: Rect2=Rect2(global_position+Vector2(12,12),size-Vector2(24,24))
	var width: float=minf(334,area.size.x)
	var font: Font=body.get_theme_font("font")
	var text_height: float=font.get_multiline_string_size(body.text,HORIZONTAL_ALIGNMENT_LEFT,width-24,body.get_theme_font_size("font_size")).y
	# Reserve a line for localized wrapping and fallback-font metrics.
	var line_reserve: float=font.get_height(body.get_theme_font_size("font_size"))+body.get_theme_constant("line_spacing")
	var height: float=maxf(124,text_height+76+line_reserve)
	coach.show()
	coach.set_anchors_preset(Control.PRESET_TOP_LEFT)
	coach.size=Vector2(width,height)
	body.max_lines_visible=-1
	body.clip_text=false
	body.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
	body.offset_bottom=height-12
	var x: float=clampf(protected.get_center().x-width*0.5,area.position.x,area.end.x-width)
	var avoid: Rect2=protected.grow(12)
	var navigation: Rect2=host.ui.shop_toggle.get_global_rect().grow(8)
	if not host.shop_collapsed:
		navigation=navigation.merge(host.shop_selector.get_global_rect().grow(8))
	var candidates: Array[Vector2]=[
		Vector2(x,avoid.position.y-height),
		Vector2(x,avoid.end.y),
		Vector2(x,navigation.position.y-height-8),
		Vector2(x,area.position.y),
		Vector2(x,area.end.y-height),
		Vector2(avoid.position.x-width,area.position.y),
		Vector2(avoid.end.x,area.position.y)
	]
	if target==host.tree:
		candidates.push_front(Vector2(x,area.end.y-height))
	for point in candidates:
		var rect: Rect2=Rect2(point,coach.size)
		if area.encloses(rect) and not rect.intersects(avoid) and not rect.intersects(navigation):
			coach.position=point-global_position
			return
	# Very narrow/short layouts prefer a compact coach in the larger vertical gap.
	var above: float=maxf(0,avoid.position.y-area.position.y)
	var below: float=maxf(0,area.end.y-avoid.end.y)
	var room: float=maxf(above,below)
	coach.position=Vector2(x,area.position.y if above>=below else avoid.end.y)-global_position
	if room>=100:
		coach.size.y=room
		body.offset_bottom=room-8
		body.max_lines_visible=maxi(1,int((room-64)/maxf(1,font.get_height(body.get_theme_font_size("font_size")))))
		body.clip_text=true
		body.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	else:
		coach.hide()
