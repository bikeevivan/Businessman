extends Node

const MUSIC_PATH: String = "res://assets/audio/tycoon_theme.mp3"

var enabled: bool = true
var _player: AudioStreamPlayer

func _ready() -> void:
	var settings = get_node_or_null("/root/Settings")
	if settings != null:
		enabled = bool(settings.music_enabled)
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	# Lower volume to avoid a click/pop when the track restarts via the finished signal.
	_player.volume_db = -9.0
	add_child(_player)
	_player.finished.connect(_on_finished)
	if ResourceLoader.exists(MUSIC_PATH):
		_player.stream = load(MUSIC_PATH)
	else:
		push_warning("Music file not found: %s" % MUSIC_PATH)
	if enabled and DisplayServer.get_name() != "headless":
		_play()

func _play() -> void:
	if _player == null or _player.stream == null:
		return
	_player.play()

func _on_finished() -> void:
	if enabled:
		_play()

func set_enabled(value: bool) -> void:
	enabled = value
	if _player == null:
		return
	if value and not _player.playing:
		_play()
	elif not value and _player.playing:
		_player.stop()

func _exit_tree() -> void:
	if _player != null:
		_player.stop()
		_player.stream = null
