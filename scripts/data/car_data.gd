class_name CarData
extends RefCounted

const CAR_PATH: String = "res://data/cars.json"

static func load_cars() -> Array:
	if not FileAccess.file_exists(CAR_PATH):
		push_error("cars.json not found at " + CAR_PATH)
		return []
	var file = FileAccess.open(CAR_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open cars.json")
		return []
	var text: String = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON in cars.json")
		return []
	return data.get("cars", [])

static func get_car(index: int) -> Dictionary:
	var cars: Array = load_cars()
	if index < 0 or index >= cars.size():
		return {}
	return cars[index]

static func get_car_color(car: Dictionary) -> Color:
	return Color.from_string(str(car.get("color", "cccccc")), Color(0.8, 0.8, 0.85))
