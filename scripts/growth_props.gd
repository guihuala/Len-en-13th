extends Control

# Positions and sizes are authored in growth_props.tscn.
@onready var audience: Control = $Audience
@onready var laptop: TextureRect = $Laptop
@onready var notice: TextureRect = $Notice
@onready var tonic: Button = $GrowthTonic

func _ready() -> void:
	fit_textures(self)
	refresh()

func fit_textures(parent: Node) -> void:
	for child in parent.get_children():
		if child is TextureRect:
			child.texture = preload("res://scripts/foreground_art.gd").fitted(child.texture)
		fit_textures(child)

func refresh() -> void:
	laptop.visible = "incident" in GameState.triggered or int(GameState.counts.get("factory", 0)) > 0
	notice.visible = "forest" in GameState.triggered or int(GameState.counts.get("grove", 0)) > 0
	audience.visible = "nursery" in GameState.triggered or int(GameState.counts.get("seed_bank", 0)) > 0
	tonic.refresh()
