extends TextureRect

# Kept at this path so the existing camera frames and skin remain compatible.
const UITheme = preload("res://scripts/ui_theme.gd")
const BACKGROUNDS = [
	preload("res://assets/art/backgrounds/nature_01.png"),
	preload("res://assets/art/backgrounds/nature_02.png"),
	preload("res://assets/art/backgrounds/nature_03.png"),
	preload("res://assets/art/backgrounds/nature_04.png"),
	preload("res://assets/art/backgrounds/nature_05.png"),
	preload("res://assets/art/backgrounds/nature_06.png"),
	preload("res://assets/art/backgrounds/nature_07.png")
]
var tint_tween: Tween
var scene_tween: Tween
var current_stage: int = -1
var studio_material: ShaderMaterial
var old_view: TextureRect
var clouds: Array[TextureRect] = []
var time: float = 0.0
@export var exposure: float = 1.06

func _ready() -> void:
	old_view=$OldView
	old_view.hide()
	var shader: Shader=UITheme.SKIN.get("paper_shader")
	if shader!=null:
		studio_material=ShaderMaterial.new()
		studio_material.shader=shader
		studio_material.set_shader_parameter("exposure",exposure)
		studio_material.set_shader_parameter("grain_strength",0.003)
		studio_material.set_shader_parameter("light_strength",0.006)
		material=studio_material
	else:
		material=null
	for cloud in [$Cloud1,$Cloud2,$Cloud3]: clouds.append(cloud)
	resized.connect(layout_clouds)
	GameState.changed.connect(update_stage)
	update_stage()
	layout_clouds()

func layout_clouds() -> void:
	for i in range(clouds.size()):
		clouds[i].size=Vector2(size.x*(0.30+i*0.04),size.x*(0.105+i*0.014))
		clouds[i].position=Vector2(size.x*(0.04+i*0.33),size.y*(0.10+i*0.09))

func update_stage() -> void:
	var stage: int=clampi(GameState.stage,0,BACKGROUNDS.size()-1)
	if studio_material!=null:
		studio_material.set_shader_parameter("motion_strength",0.0 if GameState.reduced_motion else 1.0)
	if current_stage==stage: return
	var initial: bool=current_stage<0
	if scene_tween!=null and scene_tween.is_valid(): scene_tween.kill()
	if tint_tween!=null and tint_tween.is_valid(): tint_tween.kill()
	if not initial:
		old_view.texture=texture
		old_view.material=studio_material.duplicate() if studio_material!=null else null
	current_stage=stage
	texture=BACKGROUNDS[stage]
	var tint: Color=UITheme.stage_color(stage)
	if studio_material==null:
		modulate=Color(exposure,exposure,exposure)*tint
	else:
		studio_material.set_shader_parameter("exposure",exposure)
		studio_material.set_shader_parameter("incident_strength",1.0 if stage>=3 else 0.0)
		studio_material.set_shader_parameter("stage_tint",tint)
	for cloud in clouds:
		cloud.texture=preload("res://assets/art/regions/backgrounds__nature__star_dust.tres") if stage>=4 else preload("res://assets/art/regions/backgrounds__nature__cloud.tres")
		cloud.modulate.a=0.40 if stage<3 else (0.16 if stage in [3,6] else 0.3)
	if initial or GameState.reduced_motion:
		old_view.hide()
	else:
		old_view.modulate.a=1.0
		old_view.show()
		scene_tween=create_tween()
		scene_tween.tween_property(old_view,"modulate:a",0.0,0.65)
		scene_tween.finished.connect(old_view.hide)

func _process(delta: float) -> void:
	if studio_material!=null:
		studio_material.set_shader_parameter("motion_strength",0.0 if GameState.reduced_motion else 1.0)
	if GameState.reduced_motion:
		if scene_tween!=null and scene_tween.is_running():
			scene_tween.kill()
			old_view.hide()
		layout_clouds()
		return
	time+=delta
	for i in range(clouds.size()):
		clouds[i].position=Vector2(size.x*(0.04+i*0.33)+sin(time*(0.10+current_stage*0.008)+i)*size.x*0.035,size.y*(0.10+i*0.09)+sin(time*0.13+i)*3)
