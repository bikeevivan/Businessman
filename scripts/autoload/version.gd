extends Node

const VERSION_PATH: String = "res://version.txt"
const FALLBACK: String = "0.0"

static var value: String = FALLBACK

func _ready() -> void:
	var f := FileAccess.open(VERSION_PATH, FileAccess.READ)
	if f != null:
		var raw := f.get_as_text().strip_edges()
		if raw != "":
			value = raw

func get_version() -> String:
	return value
