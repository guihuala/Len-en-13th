extends Resource

@export_group("Backgrounds")
@export var menu_background: Texture2D
@export var game_background: Texture2D
@export_group("Shaders")
@export var paper_shader: Shader

@export_group("Text Colors")
@export var text_primary: Color = Color("382f23")
@export var text_muted: Color = Color("66563e")
@export var text_on_primary: Color = Color("2f402b")
@export var text_accent: Color = Color("964f37")

@export_group("Growth Backgrounds")
# Compost, sprout, forming, expansion, continents, orbit, planetary life.
@export var stage_colors: PackedColorArray = PackedColorArray([
	Color("e6e9e1"), Color("dbe3d2"), Color("cedbc1"),
	Color("c8cdd5"), Color("e2d2d5"), Color("cfded9"), Color("b7cbbf")
])
