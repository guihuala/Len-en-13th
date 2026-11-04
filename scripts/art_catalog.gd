extends RefCounted

const PATH = "res://assets/art/catalog.json"
static var catalog: Dictionary = {}

static func texture(source: String) -> Texture2D:
	if catalog.is_empty() and FileAccess.file_exists(PATH):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary: catalog=parsed
	return load(str(catalog.get(source,source))) as Texture2D

# Enlarged story props use the untouched 2× painted source sheets.
# Small shop icons continue to use the compact atlases.
static func detail_texture(source: String) -> Texture2D:
	var original=texture(source)
	if original==null: return null
	var detail_path: String="res://assets/art/detail_regions/"+original.resource_path.get_file()
	if ResourceLoader.exists(detail_path): return load(detail_path) as Texture2D
	return original
