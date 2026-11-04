extends Control

var image: TextureRect
var paper_material: ShaderMaterial

func _ready() -> void:
	image=$Image
	paper_material=image.studio_material

func update_stage() -> void:
	image.update_stage()
