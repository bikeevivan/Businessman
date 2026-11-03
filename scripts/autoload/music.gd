extends Node

const MUSIC_PATH: String = "res://assets/audio/tycoon_theme.mp3"
const LOOP_PAUSE_SEC: float = 2.5

var enabled: bool = true
var _player: AudioStreamPlayer
var _pause_timer: Timer

func _ready() -> void:
	var settings = get_node_or_null("/root/Settings")
	if settings != null:
		enabled = bool(settings.music_enabled)

	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = -9.0
	add_child(_player)
	_player.finished.connect(_on_finished)

	_pause_timer = Timer.new()
	_pause_timer.one_shot = true
	_pause_timer.wait_time = LOOP_PAUSE_SEC
	add_child(_pause_timer)
	_pause_timer.timeout.connect(_on_pause_timer_timeout)

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
	if not enabled or _pause_timer == null:
		return
	_pause_timer.start(LOOP_PAUSE_SEC)

func _on_pause_timer_timeout() -> void:
	if enabled:
		_play()

func set_enabled(value: bool) -> void:
	enabled = value
	if _player == null:
		return
	if value:
		if _pause_timer != null:
			_pause_timer.stop()
		if not _player.playing:
			_play()
	else:
		_player.stop()
		if _pause_timer != null:
			_pause_timer.stop()

func _exit_tree() -> void:
	if _player != null:
		_player.stop()
		_player.stream = null
	if _pause_timer != null:
		_pause_timer.stop()
