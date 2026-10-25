extends Node

signal language_changed

const SETTINGS_PATH: String = "user://settings.json"

var resolution: Vector2i = Vector2i(1280, 720)
var fullscreen: bool = false
var language: String = "ru"
var music_enabled: bool = true

func _ready() -> void:
	load_settings()
	apply()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return
	var res_str: String = str(data.get("resolution", "1280x720"))
	var parts: PackedStringArray = res_str.split("x")
	if parts.size() == 2:
		resolution = Vector2i(int(parts[0]), int(parts[1]))
	fullscreen = bool(data.get("fullscreen", false))
	language = str(data.get("language", "ru"))
	music_enabled = bool(data.get("music_enabled", true))

func save_settings() -> void:
	var data: Dictionary = {
		"resolution": "%dx%d" % [resolution.x, resolution.y],
		"fullscreen": fullscreen,
		"language": language,
		"music_enabled": music_enabled,
	}
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open settings file for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func apply() -> void:
	TranslationServer.set_locale(language)
	language_changed.emit()
	var music = get_node_or_null("/root/Music")
	if music != null:
		music.set_enabled(music_enabled)
	var win = get_window()
	if win == null:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MAXIMIZE_DISABLED, true)
	win.size = Vector2i(1280, 720)
	win.position = (DisplayServer.screen_get_size() - win.size) / 2
	if win.has_method("set_window_title"):
		win.title = "Бизнесмен"
