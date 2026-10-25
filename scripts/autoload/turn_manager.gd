extends Node

signal turn_started(turn_number: int)

func end_turn() -> void:
	_advance_turn(true)

func work_turn() -> void:
	_advance_turn(false)

func _advance_turn(with_production: bool) -> void:
	RandomEvents.maybe_trigger()
	if GameState.realistic_ai:
		for ai_id in range(1, GameState.ai_count + 1):
			RandomEvents.maybe_trigger_for(ai_id)

	if with_production:
		produce_for_owner(0)

	AIManager.take_turns()

	_check_antimonopoly()
	SaveManager.save_game()

	GameState.turn += 1
	GameState.worked_this_turn = false
	turn_started.emit(GameState.turn)
	GameState.turn_changed.emit()

func produce_for_owner(owner_id: int) -> void:
	var mult: float = GameState.take_production_multiplier(owner_id)

	for e in GameState.get_enterprises_of_type("raw", owner_id):
		var prod: int = maxi(0, roundi(randi_range(int(e["prod_min"]), int(e["prod_max"])) * mult))
		GameState.add_to_inventory("raw", prod, owner_id)

	for e in GameState.get_enterprises_of_type("factory", owner_id):
		var capacity: int = maxi(0, roundi(randi_range(int(e["prod_min"]), int(e["prod_max"])) * mult))
		var available: int = GameState.get_inventory("raw", owner_id)
		var can_produce: int = mini(capacity, available)
		if can_produce > 0:
			GameState.consume_from_inventory("raw", can_produce, owner_id)
			GameState.add_to_inventory("product", can_produce, owner_id)

	var price: float = Market.get_base_price("product")
	price *= GameState.get_owner_income_multiplier(owner_id)
	for e in GameState.get_enterprises_of_type("sales", owner_id):
		var capacity: int = maxi(0, roundi(randi_range(int(e["prod_min"]), int(e["prod_max"])) * mult))
		var can_sell: int = mini(capacity, GameState.get_inventory("product", owner_id))
		if can_sell > 0:
			GameState.consume_from_inventory("product", can_sell, owner_id)
			GameState.add_money(can_sell * price, owner_id)

func _check_antimonopoly() -> void:
	for owner_id in GameState.get_owner_ids():
		for etype in ["raw", "factory", "sales"]:
			var key: String = "%d_%s" % [owner_id, etype]
			var owned: Array = GameState.get_enterprises_of_type(etype, owner_id)
			if owned.size() >= 2:
				GameState.antimonopoly_timers[key] = int(GameState.antimonopoly_timers.get(key, 0)) + 1
				if int(GameState.antimonopoly_timers[key]) >= 2:
					var total_price: float = 0.0
					for e in owned:
						total_price += float(e["price"])
					var fine: float = 0.15 * total_price
					GameState.spend_money(fine, owner_id)
					GameState.antimonopoly_timers[key] = 0
					if owner_id == 0:
						GameState.antimonopoly_fine.emit(fine, etype)
			else:
				GameState.antimonopoly_timers[key] = 0
