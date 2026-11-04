extends RefCounted

const ArtCatalog = preload("res://scripts/art_catalog.gd")

static func apply(button: Button, key: String, label: String, caption: String = "") -> void:
	button.icon=ArtCatalog.texture("res://assets/ui/icons/"+key+".svg")
	button.set_meta("icon_key",key)
	button.expand_icon=true
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER if caption.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text=label
	button.set_meta("action_label",label)
	button.text=caption
