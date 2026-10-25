class_name EnterpriseData
extends RefCounted

const ENTERPRISE_PATH: String = "res://data/enterprises.json"

static func load_enterprises() -> Dictionary:
	if not FileAccess.file_exists(ENTERPRISE_PATH):
		push_error("enterprises.json not found at " + ENTERPRISE_PATH)
		return {}
	var file = FileAccess.open(ENTERPRISE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open enterprises.json")
		return {}
	var text: String = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON in enterprises.json")
		return {}
	return data
