class_name UIBackground

const PATHS: Dictionary = {
	"menu": "res://assets/bg/bg_menu.png",
	"exchange": "res://assets/bg/bg_exchange.png",
	"cars": "res://assets/png/back_showroom_.png",
	"enterprises": "res://assets/bg/bg_enterprises.png",
	"properties": "res://assets/png/back_city.png",
}

static func add(parent: Control, key: String, tint: Color = Color(0.03, 0.05, 0.09, 0.18)) -> void:
	var path: String = PATHS.get(key, "")
	if path != "" and ResourceLoader.exists(path):
		var tex = TextureRect.new()
		tex.texture = load(path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(tex)

	var overlay = ColorRect.new()
	overlay.color = tint
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
