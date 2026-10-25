class_name PropertyData
extends RefCounted

const PROPERTY_PATH: String = "res://data/properties.json"

static func load_properties() -> Array:
	if not FileAccess.file_exists(PROPERTY_PATH):
		push_error("properties.json not found at " + PROPERTY_PATH)
		return []
	var file = FileAccess.open(PROPERTY_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open properties.json")
		return []
	var text: String = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON in properties.json")
		return []
	return data.get("properties", [])

static func get_property(index: int) -> Dictionary:
	var properties: Array = load_properties()
	if index < 0 or index >= properties.size():
		return {}
	return properties[index]

static func get_property_color(prop: Dictionary) -> Color:
	return Color.from_string(str(prop.get("color", "cccccc")), Color(0.8, 0.8, 0.85))
