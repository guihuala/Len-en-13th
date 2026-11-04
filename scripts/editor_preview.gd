@tool
extends Control

# The editor assembles the same PNG parts as the game's initial growth form.
const TreeRig = preload("res://scripts/tree_rig.gd")
var rig: Node2D

func _ready() -> void:
	visible=Engine.is_editor_hint()
	if not Engine.is_editor_hint(): return
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	rig=TreeRig.new()
	add_child(rig)
	if not rig.configure("stage_01_potted"):
		push_error("Unable to load hand-painted editor preview")
		return
	rig.pose(0,true)
	resized.connect(layout_preview)
	layout_preview()

func layout_preview() -> void:
	if not is_instance_valid(rig): return
	var bounds=Rect2(70,80,340,390)
	var factor: float=minf(size.x/bounds.size.x,size.y/bounds.size.y)*0.94
	rig.position=size/2-bounds.get_center()*factor
	rig.scale=Vector2.ONE*factor
