extends Node

const AI_SALARY: float = 50.0
const TRADE_RESERVE: float = 50.0
const AI_MAX_BUYS_PER_TURN: int = 6
const AI_RICH_THRESHOLD: float = 1500.0
const MARKET_ACTIONS_MIN: int = 1
const MARKET_ACTIONS_MAX: int = 3
const BUY_MAX_PER_ACTION: int = 10
const CHAIN: Array = ["raw", "factory", "sales"]

func take_turns() -> void:
	for i in GameState.ai_players.size():
		_ai_turn(i + 1)

func _ai_turn(ai_id: int) -> void:
	GameState.add_money(AI_SALARY, ai_id)
	TurnManager.produce_for_owner(ai_id)
	GameState.spend_money(GameState.TRAM_FARE, ai_id)
	_try_buy_enterprises(ai_id)
	_market_actions(ai_id)
	_ai_buy_lifestyle(ai_id)

func _ai_buy_lifestyle(ai_id: int) -> void:
	if not GameState.realistic_ai:
		return
	_ai_try_buy_lifestyle_item(ai_id, CarData.load_cars(), "car")
	_ai_try_buy_lifestyle_item(ai_id, PropertyData.load_properties(), "property")

func _ai_try_buy_lifestyle_item(ai_id: int, catalog: Array, kind: String) -> bool:
	if catalog.is_empty():
		return false
	var current: int = GameState.get_owner_car(ai_id) if kind == "car" else GameState.get_owner_property(ai_id)
	var old_price: float = 0.0
	if current >= 0 and current < catalog.size():
		old_price = float(catalog[current]["price"])
	var budget: float = GameState.get_money(ai_id) - TRADE_RESERVE
	var best: int = -1
	for i in catalog.size():
		if i <= current:
			continue
		var net_cost: float = float(catalog[i]["price"]) - old_price * 0.5
		if net_cost > budget:
			continue
		if best < 0 or i > best:
			best = i
	if best < 0:
		return false
	if kind == "car":
		return GameState.buy_car_for_owner(ai_id, best)
	return GameState.buy_property_for_owner(ai_id, best)

func _try_buy_enterprises(ai_id: int) -> void:
	var data: Dictionary = EnterpriseData.load_enterprises()
	var max_acts: int = AI_MAX_BUYS_PER_TURN
	var money: float = GameState.get_money(ai_id)
	if money > AI_RICH_THRESHOLD:
		max_acts += int(money / AI_RICH_THRESHOLD)
	var acts: int = 0
	while acts < max_acts:
		money = GameState.get_money(ai_id)
		if _ai_acquire_missing(ai_id, data, money):
			acts += 1
			continue
		if _ai_upgrade_owned(ai_id, data, money):
			acts += 1
			continue
		break

func _ai_acquire_missing(ai_id: int, data: Dictionary, money: float) -> bool:
	var budget: float = money - TRADE_RESERVE
	if budget < 0.0:
		return false
	for etype in CHAIN:
		if not GameState.get_enterprises_of_type(etype, ai_id).is_empty():
			continue
		var level_data: Dictionary = _best_affordable(data, etype, budget)
		if not level_data.is_empty():
			return GameState.buy_enterprise(etype, level_data, ai_id)
	for etype in CHAIN:
		if not GameState.get_enterprises_of_type(etype, ai_id).is_empty():
			continue
		var level_data2: Dictionary = _cheapest_affordable(data, etype, budget)
		if not level_data2.is_empty():
			return GameState.buy_enterprise(etype, level_data2, ai_id)
	return false

func _cheapest_affordable(data: Dictionary, etype: String, budget: float) -> Dictionary:
	var best: Dictionary = {}
	for level_data in data.get(etype, []):
		if not GameState.is_enterprise_available(etype, int(level_data["level"])):
			continue
		var price: float = float(level_data["price"])
		if price > budget:
			continue
		if best.is_empty() or price < float(best["price"]):
			best = level_data
	return best

func _ai_deny_player(ai_id: int, data: Dictionary) -> bool:
	var player_types: Array = []
	for etype in CHAIN:
		if GameState.get_enterprises_of_type(etype, ai_id).is_empty() and GameState.count_enterprises_of_type(etype, 0) > 0:
			player_types.append(etype)
	if player_types.is_empty():
		return false
	var budget: float = GameState.get_money(ai_id) - TRADE_RESERVE
	var best: Dictionary = {}
	var best_type: String = ""
	for etype in player_types:
		for level_data in data.get(etype, []):
			var lvl: int = int(level_data["level"])
			if not GameState.is_enterprise_available(etype, lvl):
				continue
			var price: float = float(level_data["price"])
			if price > budget:
				continue
			var prod: float = (float(level_data["prod_min"]) + float(level_data["prod_max"])) / 2.0
			var score: float = prod / maxf(price, 1.0)
			var best_score: float = 0.0
			if not best.is_empty():
				best_score = ((float(best["prod_min"]) + float(best["prod_max"])) / 2.0) / maxf(float(best["price"]), 1.0)
			if best.is_empty() or score > best_score or (is_equal_approx(score, best_score) and lvl > int(best["level"])):
				best = level_data
				best_type = etype
	if best.is_empty():
		return false
	return GameState.buy_enterprise(best_type, best, ai_id)

func _ai_upgrade_owned(ai_id: int, data: Dictionary, money: float) -> bool:
	var owned: Array = GameState.get_enterprises_of_owner(ai_id)
	if owned.is_empty():
		return false
	var budget: float = money - TRADE_RESERVE
	var best_type: String = ""
	var best_new: Dictionary = {}
	var best_old_idx: int = -1
	var best_old_price: float = 0.0
	for i in owned.size():
		var e: Dictionary = owned[i]
		var etype: String = str(e["type"])
		var cur_level: int = int(e["level"])
		var cur_price: float = float(e["price"])
		var best_up: Dictionary = {}
		for level_data in data.get(etype, []):
			var lvl: int = int(level_data["level"])
			if lvl <= cur_level:
				continue
			if not GameState.is_enterprise_available(etype, lvl):
				continue
			if budget < float(level_data["price"]):
				continue
			if best_up.is_empty() or lvl > int(best_up["level"]):
				best_up = level_data
		if best_up.is_empty():
			continue
		if best_new.is_empty() or int(best_up["level"]) > int(best_new["level"]) or (int(best_up["level"]) == int(best_new["level"]) and float(best_up["price"]) < float(best_new["price"])):
			best_new = best_up
			best_type = etype
			best_old_idx = i
			best_old_price = cur_price
	if best_new.is_empty() or best_old_idx < 0:
		return false
	if not GameState.buy_enterprise(best_type, best_new, ai_id):
		return false
	GameState.sell_enterprise(best_old_idx, ai_id)
	return true

func _level_data(data: Dictionary, etype: String, level: int) -> Dictionary:
	for level_data in data.get(etype, []):
		if int(level_data["level"]) == level:
			return level_data
	return {}

func _best_affordable(data: Dictionary, etype: String, budget: float) -> Dictionary:
	var best: Dictionary = {}
	for level_data in data.get(etype, []):
		if not GameState.is_enterprise_available(etype, int(level_data["level"])):
			continue
		var price: float = float(level_data["price"])
		if price > budget:
			continue
		if best.is_empty() or int(level_data["level"]) > int(best["level"]):
			best = level_data
	return best

func _market_actions(ai_id: int) -> void:
	for lot in Market.get_lots_of_owner(ai_id):
		Market.cancel_lot(int(lot["id"]), ai_id)
	_ai_post_lot(ai_id)
	var actions: int = randi_range(MARKET_ACTIONS_MIN, MARKET_ACTIONS_MAX)
	for _a in actions:
		_ai_buy_lot(ai_id)

func _ai_post_lot(ai_id: int) -> bool:
	var raw_keep: int = _factory_raw_need(ai_id) + 5
	var raw_inv: int = GameState.get_inventory("raw", ai_id)
	if raw_inv > raw_keep:
		return _post_ai_lot(ai_id, "raw", raw_inv - raw_keep)
	var prod_inv: int = GameState.get_inventory("product", ai_id)
	if prod_inv >= 2:
		return _post_ai_lot(ai_id, "product", maxi(1, prod_inv / 2))
	return false

func _factory_raw_need(ai_id: int) -> int:
	var need: int = 0
	for e in GameState.get_enterprises_of_type("factory", ai_id):
		need += int(e["prod_max"])
	return need

func _post_ai_lot(ai_id: int, kind: String, qty: int) -> bool:
	if qty <= 0:
		return false
	var price: float = snappedf(Market.get_base_price(kind) * randf_range(0.9, 1.3), 0.5)
	return Market.post_lot(ai_id, kind, qty, price)

func _ai_buy_lot(ai_id: int) -> void:
	var kinds: Array = ["raw", "product"]
	kinds.shuffle()
	for kind in kinds:
		var lot: Dictionary = _cheapest_other_lot(ai_id, kind)
		if lot.is_empty():
			continue
		var price: float = float(lot["price"])
		var budget: float = GameState.get_money(ai_id) - TRADE_RESERVE
		var max_qty: int = mini(int(lot["qty"]), int(floor(budget / price)))
		if max_qty <= 0:
			continue
		var qty: int = randi_range(1, mini(max_qty, BUY_MAX_PER_ACTION))
		Market.buy_from_lot(int(lot["id"]), ai_id, qty)
		return

func _cheapest_other_lot(ai_id: int, kind: String) -> Dictionary:
	var best: Dictionary = {}
	for l in Market.get_lots():
		if l["kind"] != kind:
			continue
		if int(l["owner"]) == ai_id:
			continue
		if best.is_empty() or float(l["price"]) < float(best["price"]):
			best = l
	return best
