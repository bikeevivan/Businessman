extends Node

const MAX_SLOTS: int = 5

var save_dir: String = "user://"

func set_save_dir(dir: String) -> void:
	save_dir = dir
	if not save_dir.ends_with("/"):
		save_dir += "/"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(save_dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_dir))

func _slot_path(slot: int) -> String:
	return save_dir + "save_%d.json" % slot

func get_available_slot() -> int:
	for i in range(1, MAX_SLOTS + 1):
		if not has_save(i):
			return i
	return 1

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func save_game(slot: int = -1) -> bool:
	if slot < 1:
		slot = GameState.current_save_slot
	var data: Dictionary = {
		"money": GameState.money,
		"turn": GameState.turn,
		"inventory": GameState.inventory,
		"enterprises": GameState.enterprises,
		"ai_players": GameState.ai_players,
		"ai_count": GameState.ai_count,
		"market_lots": Market.lots,
		"market_next_lot_id": Market.next_lot_id,
		"antimonopoly_timers": GameState.antimonopoly_timers,
		"worked_this_turn": GameState.worked_this_turn,
		"production_multiplier": GameState.production_multiplier,
		"game_won": GameState.has_won,
		"owned_car": GameState.owned_car,
		"owned_property": GameState.owned_property,
		"realistic_ai": GameState.realistic_ai,
		"win_amount": GameState.win_amount,
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	var file = FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save slot %d for writing" % slot)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_game(slot: int = -1) -> bool:
	if slot < 1:
		slot = GameState.current_save_slot
	if not has_save(slot):
		return false
	var file = FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		push_error("Cannot open save slot %d for reading" % slot)
		return false
	var text: String = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid save data in slot %d" % slot)
		return false

	GameState.money = float(data.get("money", GameState.START_MONEY))
	GameState.turn = int(data.get("turn", GameState.START_TURN))
	GameState.inventory = data.get("inventory", {"raw": 0, "product": 0})

	var loaded_enterprises: Array = data.get("enterprises", [])
	for e in loaded_enterprises:
		if not e.has("owner"):
			e["owner"] = 0
	GameState.enterprises = loaded_enterprises

	GameState.ai_players = data.get("ai_players", [])
	if GameState.ai_players.is_empty():
		var stored_count: int = int(data.get("ai_count", 1))
		stored_count = clampi(stored_count, GameState.MIN_OPPONENTS, GameState.MAX_OPPONENTS)
		for i in stored_count:
			GameState.ai_players.append({
				"money": GameState.START_MONEY,
				"inventory": {"raw": 0, "product": 0},
			})
	for ai in GameState.ai_players:
		ai["car"] = int(ai.get("car", -1))
		ai["property"] = int(ai.get("property", -1))
		ai["production_multiplier"] = float(ai.get("production_multiplier", 1.0))

	Market.lots = data.get("market_lots", [])
	Market.next_lot_id = int(data.get("market_next_lot_id", 1))
	var keep: Dictionary = {}
	for lot in Market.lots:
		if int(lot["owner"]) != 0:
			var key: String = "%d_%s" % [int(lot["owner"]), str(lot["kind"])]
			if not keep.has(key) or int(lot["id"]) > int(keep[key]):
				keep[key] = int(lot["id"])
	for lot in Market.lots.duplicate():
		var owner: int = int(lot["owner"])
		if owner != 0 and int(keep["%d_%s" % [owner, str(lot["kind"])]]) != int(lot["id"]):
			Market.cancel_lot(int(lot["id"]), owner)

	var loaded_timers: Dictionary = data.get("antimonopoly_timers", {})
	GameState.antimonopoly_timers = {}
	for key in loaded_timers:
		var k: String = str(key)
		if k.length() > 0 and k[0].is_valid_int():
			GameState.antimonopoly_timers[k] = loaded_timers[key]
		else:
			GameState.antimonopoly_timers["0_%s" % k] = loaded_timers[key]

	GameState.worked_this_turn = bool(data.get("worked_this_turn", false))
	GameState.production_multiplier = float(data.get("production_multiplier", 1.0))
	GameState.has_won = bool(data.get("game_won", false))
	GameState.owned_car = int(data.get("owned_car", -1))
	GameState.owned_property = int(data.get("owned_property", -1))
	GameState.realistic_ai = bool(data.get("realistic_ai", false))
	GameState.win_amount = float(data.get("win_amount", GameState.DEFAULT_WIN_AMOUNT))
	GameState.current_save_slot = slot

	GameState.emit_all()
	Market.lots_changed.emit()
	return true

func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file = FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return {}
	return {
		"turn": int(data.get("turn", 0)),
		"money": float(data.get("money", 0)),
		"ai_count": int(data.get("ai_count", 1)),
		"realistic_ai": bool(data.get("realistic_ai", false)),
		"timestamp": int(data.get("timestamp", 0)),
	}

func delete_save(slot: int) -> void:
	var path: String = _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
