@tool
extends Node2D

const MANIFEST = "res://assets/tree/rig/manifest.json"
static var forms: Dictionary = {}
static var shared_textures: Dictionary = {}
var moving_parts: Array = []
var expressions: Array = []
var reaction_bubbles: Array[TextureRect] = []
var heads: Array = []
var reaction_age: float = -1.0
var reaction_rapid: bool = false
var surprise_eyes: Texture2D
var smile_face: Dictionary = {}
var surprise_face: Dictionary = {}
var reaction_count: int = 0
var reaction_duration: float = 0.85

func face_asset(asset: String) -> Dictionary:
	for parts in forms.values():
		for entry in parts:
			if entry.get("asset", "")==asset:
				return {"texture":part_texture(entry,"texture"),"rect":entry.rect}
	return {}

func react(rapid: bool = false) -> void:
	reaction_age=0.0
	reaction_rapid=rapid
	reaction_count+=1
	for group in heads:
		# Let a small head finish its own response even while clicks continue.
		if group.small and group.active: continue
		group.age=-float(group.delay)
		group.active=true
		group.rapid=rapid
		group.style=(int(group.variant)+reaction_count)%3 if group.small else 0

func advance_reaction(delta: float) -> void:
	if reaction_age<0: return
	reaction_age+=delta
	for group in heads:
		if not group.active: continue
		group.age+=delta
		if group.age>=group.duration: group.active=false
	if reaction_age>=reaction_duration: reaction_age=-1.0

func set_expression(piece: TextureRect, face: Dictionary) -> void:
	if face.is_empty(): return
	piece.texture=face.texture
	var rect: Array=face.rect
	piece.position=Vector2(rect[0],rect[1])
	piece.size=Vector2(rect[2],rect[3])

func part_texture(entry: Dictionary, key: String) -> Texture2D:
	var cache_key: String=str(entry[key])+str(entry.get(key+"_region",[]))
	if shared_textures.has(cache_key): return shared_textures[cache_key]
	var image=load(str(entry[key])) as Texture2D
	if image==null: return null
	var region: Array=entry.get(key+"_region",[])
	if region.size()!=4: return image
	var texture=AtlasTexture.new()
	texture.atlas=image
	texture.region=Rect2(region[0],region[1],region[2],region[3])
	texture.filter_clip=true
	shared_textures[cache_key]=texture
	return texture

func configure(form: String) -> bool:
	if forms.is_empty():
		var data=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if not data is Dictionary: return false
		forms=data.get("forms",{})
	if not forms.has(form): return false
	smile_face=face_asset("character_683270793c")
	surprise_face=face_asset("character_8f7b5da119")
	surprise_eyes=face_asset("character_painted_eyes_c05").get("texture")
	var eye_index: int=0
	var head: Dictionary = {}
	for entry in forms[form]:
		var texture=part_texture(entry,"texture")
		if texture==null: return false
		var piece=TextureRect.new()
		piece.name=entry.name
		piece.texture=texture
		piece.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		piece.stretch_mode=TextureRect.STRETCH_SCALE
		piece.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var rect: Array=entry.rect
		piece.position=Vector2(rect[0],rect[1])
		piece.size=Vector2(rect[2],rect[3])
		piece.pivot_offset=Vector2(entry.pivot[0],entry.pivot[1])-piece.position
		if entry.has("transform"):
			# Stage instances place one shared drawing; motion stays in its local space.
			var placement=Node2D.new()
			placement.name=piece.name+"_placement"
			var t: Array=entry.transform
			placement.transform=Transform2D(Vector2(t[0],t[1]),Vector2(t[2],t[3]),Vector2(t[4],t[5]))
			add_child(placement)
			placement.add_child(piece)
			if entry.get("asset", "")=="character_72a82db031":
				head={"parts":[],"scale":placement.transform.x.length(),"origin":placement.position,
					"phase":float(heads.size())*0.93,"active":false,"age":0.0,"delay":0.0,"duration":0.85,"variant":0,"style":0,"rapid":false,"small":false}
				heads.append(head)
			if str(entry.get("asset", "")).begins_with("character_") and entry.get("asset", "")!="character_7a4e4bcbd0" and not head.is_empty():
				head.parts.append({"node":placement,"rest":placement.transform})
		else:
			add_child(piece)
		if str(entry.get("name", "")).contains("惊叹气泡"):
			piece.visible=false
			reaction_bubbles.append(piece)
		if entry.kind=="base":
			if str(entry.get("name", "")).contains("表情"):
				expressions.append({"node":piece,"head":head,"rest":{"texture":texture,"rect":entry.rect}})
			continue
		var part={"node":piece,"kind":str(entry.kind),"open":texture,"phase":float(moving_parts.size())*0.47}
		part.head=head if str(entry.get("asset", "")).begins_with("character_") else {}
		if entry.kind=="eyes":
			part.closed=part_texture(entry,"closed_texture")
			part.eye_index=eye_index
			eye_index+=1
		moving_parts.append(part)
	var largest: float=0.0
	for group in heads: largest=maxf(largest,float(group.scale))
	var small_index: int=0
	for group in heads:
		group.small=float(group.scale)<largest*0.75
		if not group.small: continue
		group.delay=0.09+small_index*0.055
		group.variant=small_index%3
		group.duration=0.62+(small_index%3)*0.09
		reaction_duration=maxf(reaction_duration,float(group.delay)+float(group.duration))
		small_index+=1
	return true

func head_response(group: Dictionary) -> Dictionary:
	if group.is_empty() or not group.active or group.age<0:
		return {"active":false,"startled":false,"squint":false,"age":0.0,"strength":0.0,"style":0}
	var age: float=group.age
	var style: int=group.style
	var startled: bool=group.rapid and age<(0.12 if group.small else 0.20) and style!=2
	var squint: bool=age<0.48
	if group.small:
		match style:
			0: squint=age<0.34
			1: squint=age>0.18 and age<0.30
			2: squint=age<0.10 or (age>0.23 and age<0.35)
	return {"active":true,"startled":startled,"squint":squint,"age":age,
		"strength":pow(maxf(0.0,1.0-age/float(group.duration)),2),"style":style}

func pose(clock: float, still: bool) -> void:
	for bubble in reaction_bubbles:
		bubble.visible=reaction_age>=0.0 and reaction_age<0.65 and not GameState.paused
		if not bubble.visible: continue
		bubble.modulate.a=1.0 if still else minf(reaction_age/0.045,1.0)*clampf((0.65-reaction_age)/0.18,0.0,1.0)
	for expression in expressions:
		var response=head_response(expression.head)
		set_expression(expression.node,(surprise_face if response.startled else smile_face) if response.active else expression.rest)
	for group in heads:
		var response=head_response(group)
		var nod: float=0.0
		var tilt: float=0.0 if still else deg_to_rad(1.2)*sin(clock*1.35+float(group.phase))
		if response.active and not still:
			var tempo: float=0.42+float(response.style)*0.065
			nod=sin(float(response.age)*PI/tempo)*(2.4-float(response.style)*0.35)*float(response.strength)*float(group.scale)
			if group.small and response.style==2:
				tilt+=deg_to_rad(2.0)*sin(float(response.age)*PI/0.4)*float(response.strength)
		var turn=Transform2D(tilt,Vector2.ZERO)
		var pivot: Vector2=group.origin+Vector2(0,60.0*float(group.scale))
		for part in group.parts:
			part.node.transform=turn*part.rest
			part.node.position=pivot+turn.basis_xform(part.rest.origin-pivot)+Vector2(0,nod)
	for part in moving_parts:
		var piece: TextureRect=part.node
		piece.rotation=0
		piece.scale=Vector2.ONE
		if part.kind=="eyes":
			var response=head_response(part.head)
			var period: float=4.1+float(int(part.eye_index)%3)*0.31
			var blink: bool=not still and fmod(clock+float(part.eye_index)*0.43,period)>period-0.14
			if response.active and not still:
				piece.texture=surprise_eyes if response.startled else (part.closed if response.squint else part.open)
			else:
				piece.texture=part.closed if blink else part.open
