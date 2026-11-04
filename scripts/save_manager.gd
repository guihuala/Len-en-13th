extends RefCounted

const PATH = "user://save.json"

static func write_save(data: Dictionary) -> bool:
	var file = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(PATH + ".tmp", PATH) == OK

static func read_save() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}
