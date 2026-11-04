extends Control

# All props are fictional game UI; labels use the game's locale-aware fonts.
const UITheme = preload("res://scripts/ui_theme.gd")
const ArtCatalog = preload("res://scripts/art_catalog.gd")
const PROPS = {
	"seed":preload("res://assets/art/regions/story__suspicious_seed.tres"),
	"hat":preload("res://assets/art/regions/story__hat.tres"),
	"desktop":preload("res://assets/art/detail_regions/story__game_desktop.tres"),
	"editor":preload("res://assets/art/detail_regions/story__game_desktop.tres"),
	"paper":preload("res://assets/art/detail_regions/story__constitution.tres"),
	"card":preload("res://assets/art/detail_regions/story__anniversary.tres"),
	"bamboo":preload("res://assets/art/detail_regions/story__bamboo_shoot.tres")
}
const LAWS = "第一条：本游戏中的旅之木，不负责解释自己的生长原理。\n第二条：禁止以“优化产量”为由过度指挥旅之木。\n第三条：竹笋除外。"
var picture: TextureRect
var caption: Label
var actors: Array[TextureRect] = []
var actor_names: Array[Label] = []
var branch: Line2D
var swap_tween: Tween
var prop_tween: Tween
var screen_mask: ColorRect
var screen_actor: TextureRect
var swapped: bool = false
var mode: String = ""
var line: int = 0
var user_pointer: bool = false

func _ready() -> void:
	custom_minimum_size=Vector2(0,144)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	picture=make_picture()
	add_child(picture)
	screen_mask=ColorRect.new()
	screen_mask.color=Color("d9e4c8")
	screen_mask.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(screen_mask)
	screen_actor=make_picture()
	screen_actor.texture=ArtCatalog.detail_texture("res://assets/art/regions/tree__mini_tabinoki.tres")
	add_child(screen_actor)
	for i in range(4):
		var actor=make_picture()
		add_child(actor)
		actors.append(actor)
		var tag=Label.new()
		tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		tag.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tag.add_theme_font_size_override("font_size",UITheme.TYPE_CAPTION)
		add_child(tag)
		actor_names.append(tag)
	caption=Label.new()
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size",UITheme.TYPE_CAPTION)
	caption.add_theme_color_override("font_color",Color("382f23"))
	add_child(caption)
	branch=Line2D.new()
	branch.default_color=Color("715744")
	branch.width=12
	add_child(branch)
	resized.connect(layout_props)

func make_picture() -> TextureRect:
	var result=TextureRect.new()
	result.mouse_filter=Control.MOUSE_FILTER_IGNORE
	result.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return result

func present(event_id: String, index: int) -> void:
	if swap_tween!=null and swap_tween.is_valid(): swap_tween.kill()
	if prop_tween!=null and prop_tween.is_valid(): prop_tween.kill()
	if mode!=event_id: swapped=false
	mode=event_id
	custom_minimum_size.y=248 if mode in ["forest","purchase_grove"] else 144
	line=index
	user_pointer=false
	picture.show()
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture=null
	picture.modulate.a=1.0
	screen_mask.hide()
	screen_actor.hide()
	caption.text=""
	caption.add_theme_color_override("font_color",Color("382f23"))
	branch.hide()
	for i in range(actors.size()):
		actors[i].hide()
		actor_names[i].hide()
	match mode:
		# The opening happens after three clicks, before buds or hats can appear.
		"sprout": picture.texture=PROPS.seed
		"research":
			picture.hide()
			custom_minimum_size.y=0
		"cloning", "purchase_dimension_box":
			picture.hide()
			for i in range(2):
				actors[i].texture=ArtCatalog.detail_texture("res://assets/art/regions/tree__mini_tabinoki.tres")
				actors[i].show()
				actor_names[i].text="A" if i==0 else "B"
				actor_names[i].show()
		"purchase_harujion":
			picture.texture=ArtCatalog.detail_texture("res://assets/items/harujion.svg")
		"incident", "purchase_factory":
			picture.texture=PROPS.desktop
			caption.text=tr("待办：黑白世界／天影战记 金章") if index<5 else tr("休息中……")
			# The painted editor is complete; reveal the actor in its inspector panel.
			screen_actor.visible=index>=2 or mode=="purchase_factory"
			# The miniature notices the player after the computer is revealed.
			screen_actor.flip_h=index>=3
		"flowering":
			picture.texture=ArtCatalog.detail_texture("res://assets/items/pollination.svg")
			picture.visible=index>=3
			branch.visible=index<4
			caption.text=tr("借来修枝 · 二创剪影") if index>=3 else ""
		"nursery", "purchase_seed_bank":
			picture.hide()
			for i in range(4):
				actors[i].texture=PROPS.bamboo if i==3 else ArtCatalog.detail_texture("res://assets/items/seed_bank.svg")
				actors[i].visible=i<3 or index>=5
			caption.text=tr("こんの木ー") if index<5 else tr("竹笋已经进场。")
		"forest", "purchase_grove":
			picture.texture=PROPS.paper
			picture.visible=mode=="purchase_grove" or index>=2
			caption.text=tr(LAWS) if picture.visible else ""
		"ending":
			picture.texture=PROPS.editor if index<3 else PROPS.card
			screen_actor.visible=index<3
			caption.text=(tr("周年贺作 · 完成！") if index==2 else "") if index<3 else tr("連縁Project 13周年おめでとう！")
			if index>=6:
				user_pointer=index==7
				caption.text=tr("制作：你") if index==7 else tr("仍然可以继续栽培。") if index==8 else tr("……所以，谁做的？")
	layout_props()
	if not GameState.reduced_motion:
		if mode=="nursery" and index==5:
			var arrival: Vector2=actors[3].position
			actors[3].position.x=size.x
			prop_tween=create_tween()
			prop_tween.tween_property(actors[3],"position",arrival,0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		elif mode=="forest" and index==2:
			picture.modulate.a=0.0
			prop_tween=create_tween()
			prop_tween.tween_property(picture,"modulate:a",1.0,0.22)
	# The two labelled originals exchange places once, including in reduced motion.
	if mode=="cloning" and index>=4 and not swapped:
		swapped=true
		if not GameState.reduced_motion:
			var a: Vector2=actors[0].position
			var b: Vector2=actors[1].position
			swap_tween=create_tween().set_parallel(true)
			swap_tween.tween_property(actors[0],"position",b,0.35).from(a)
			swap_tween.tween_property(actors[1],"position",a,0.35).from(b)
			var tag_a: Vector2=actor_names[0].position
			var tag_b: Vector2=actor_names[1].position
			swap_tween.tween_property(actor_names[0],"position",tag_b,0.35).from(tag_a)
			swap_tween.tween_property(actor_names[1],"position",tag_a,0.35).from(tag_b)
	if GameState.reduced_motion: layout_props()
	queue_redraw()

func layout_props() -> void:
	if picture==null: return
	picture.position=Vector2.ZERO
	picture.size=Vector2(size.x,size.y-44)
	caption.position=Vector2(0,size.y-44)
	caption.size=Vector2(size.x,44)
	if mode in ["forest","purchase_grove"]:
		picture.size=size
		picture.stretch_mode=TextureRect.STRETCH_SCALE
		caption.position=Vector2(14,4)
		caption.size=size-Vector2(28,8)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	else:
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if mode=="ending" and line>=3:
			picture.size=size
			picture.stretch_mode=TextureRect.STRETCH_SCALE
			caption.position=Vector2(18,8)
			caption.size=size-Vector2(36,16)
	var count: int=2 if mode in ["cloning","purchase_dimension_box"] else 4
	for i in range(actors.size()):
		var slot: int=(1-i if swapped and i<2 else i)
		actors[i].size=Vector2(size.x/count,82)
		actors[i].position=Vector2(slot*size.x/count,0)
		actor_names[i].position=Vector2(slot*size.x/count,80)
		actor_names[i].size=Vector2(size.x/count,20)
	branch.points=PackedVector2Array([Vector2(4,63),Vector2(size.x*0.5,45),Vector2(size.x-4,58)])
	if screen_actor.visible:
		# Follow the fitted desktop image, including narrow dialogue layouts.
		var fit: float=minf(picture.size.x/600.0,picture.size.y/240.0)
		var origin: Vector2=picture.position+(picture.size-Vector2(600,240)*fit)*0.5
		screen_actor.position=origin+Vector2(510,70)*fit
		screen_actor.size=Vector2(62,130)*fit
	queue_redraw()

func _draw() -> void:
	if not user_pointer: return
	var p: Vector2=get_local_mouse_position().clamp(Vector2(14,14),size-Vector2(14,14))
	draw_circle(p,11,Color("bf9580"),false,3.0)
	draw_line(p+Vector2(18,0),p+Vector2(30,0),Color("382f23"),3)

func _process(_delta: float) -> void:
	if user_pointer: queue_redraw()
	if GameState.reduced_motion and prop_tween!=null and prop_tween.is_running():
		prop_tween.kill()
		picture.modulate.a=1.0
		layout_props()
	if GameState.reduced_motion and swap_tween!=null and swap_tween.is_running():
		swap_tween.kill()
		layout_props()
