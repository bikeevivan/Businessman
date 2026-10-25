extends Node

signal money_changed
signal turn_changed
signal inventory_changed
signal enterprises_changed
signal antimonopoly_fine(fine_amount: float, enterprise_type: String)
signal opponents_changed
signal game_won
signal car_changed
signal property_changed

const START_MONEY: float = 500.0
const START_TURN: int = 1
const MIN_OPPONENTS: int = 1
const MAX_OPPONENTS: int = 8
const DEFAULT_WIN_AMOUNT: float = 1000000.0
const MIN_WIN_AMOUNT: float = 50000.0
const MAX_WIN_AMOUNT: float = 1000000.0
const TRAM_FARE: float = 30.0

const AI_COLORS: Array = [
	Color(0.95, 0.35, 0.35),
	Color(0.95, 0.65, 0.25),
	Color(0.9, 0.85, 0.3),
	Color(0.45, 0.85, 0.45),
	Color(0.35, 0.8, 0.85),
	Color(0.4, 0.55, 0.95),
	Color(0.75, 0.45, 0.95),
	Color(0.95, 0.45, 0.75),
]

var money: float = START_MONEY
var turn: int = START_TURN
var inventory: Dictionary = {"raw": 0, "product": 0}
var enterprises: Array = []
var worked_this_turn: bool = false
var antimonopoly_timers: Dictionary = {}
var current_save_slot: int = 1
var production_multiplier: float = 1.0
var has_won: bool = false
var owned_car: int = -1
var owned_property: int = -1
var realistic_ai: bool = false
var win_amount: float = DEFAULT_WIN_AMOUNT

var ai_players: Array = [
	{"money": START_MONEY, "inventory": {"raw": 0, "product": 0}},
]

var ai_count: int:
	get:
		return ai_players.size()

func reset_for_new_game(opponents: int, custom_win_amount: float = -1.0, realistic: bool = false) -> void:
	var count: int = clampi(opponents, MIN_OPPONENTS, MAX_OPPONENTS)
	if custom_win_amount > 0.0:
		win_amount = clampf(custom_win_amount, MIN_WIN_AMOUNT, MAX_WIN_AMOUNT)
	else:
		win_amount = DEFAULT_WIN_AMOUNT
	money = START_MONEY
	turn = START_TURN
	inventory = {"raw": 0, "product": 0}
	enterprises = []
	worked_this_turn = false
	antimonopoly_timers = {}
	production_multiplier = 1.0
	has_won = false
	owned_car = -1
	owned_property = -1
	realistic_ai = realistic
	ai_players = []
	for i in count:
		ai_players.append({
			"money": START_MONEY,
			"inventory": {"raw": 0, "product": 0},
			"car": -1,
			"property": -1,
			"production_multiplier": 1.0,
		})
	emit_all()

func reset() -> void:
	reset_for_new_game(ai_count)

func emit_all() -> void:
	money_changed.emit()
	turn_changed.emit()
	inventory_changed.emit()
	enterprises_changed.emit()
	opponents_changed.emit()
	car_changed.emit()
	property_changed.emit()

func own_car() -> bool:
	return owned_car >= 0

func own_property() -> bool:
	return owned_property >= 0

func get_prestige() -> int:
	var car: Dictionary = CarData.get_car(owned_car)
	return int(car.get("prestige", 0))

func get_sales_multiplier() -> float:
	return 1.0 + float(get_prestige()) / 100.0

func get_total_prestige() -> int:
	return get_prestige() + get_property_prestige()

func get_income_multiplier() -> float:
	return 1.0 + float(get_total_prestige()) / 100.0

func get_owner_car(owner_id: int) -> int:
	if owner_id == 0:
		return owned_car
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return -1
	return int(ai_players[idx].get("car", -1))

func get_owner_property(owner_id: int) -> int:
	if owner_id == 0:
		return owned_property
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return -1
	return int(ai_players[idx].get("property", -1))

func get_owner_prestige(owner_id: int) -> int:
	var car: Dictionary = CarData.get_car(get_owner_car(owner_id))
	var prop: Dictionary = PropertyData.get_property(get_owner_property(owner_id))
	return int(car.get("prestige", 0)) + int(prop.get("prestige", 0))

func get_owner_income_multiplier(owner_id: int) -> float:
	return 1.0 + float(get_owner_prestige(owner_id)) / 100.0

func get_production_multiplier_for(owner_id: int) -> float:
	if owner_id == 0:
		return production_multiplier
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return 1.0
	return float(ai_players[idx].get("production_multiplier", 1.0))

func take_production_multiplier(owner_id: int) -> float:
	var mult: float = get_production_multiplier_for(owner_id)
	set_production_multiplier(owner_id, 1.0)
	return mult

func set_production_multiplier(owner_id: int, value: float) -> void:
	if owner_id == 0:
		production_multiplier = value
		return
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return
	ai_players[idx]["production_multiplier"] = value

func scale_inventory(owner_id: int, factor: float) -> void:
	if owner_id == 0:
		inventory["raw"] = int(floor(float(inventory.get("raw", 0)) * factor))
		inventory["product"] = int(floor(float(inventory.get("product", 0)) * factor))
		inventory_changed.emit()
		return
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return
	var inv: Dictionary = ai_players[idx]["inventory"]
	inv["raw"] = int(floor(float(inv.get("raw", 0)) * factor))
	inv["product"] = int(floor(float(inv.get("product", 0)) * factor))

func break_car(owner_id: int = 0) -> void:
	if owner_id == 0:
		if owned_car >= 0:
			owned_car = -1
			car_changed.emit()
		return
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return
	ai_players[idx]["car"] = -1

func buy_car_for_owner(owner_id: int, index: int) -> bool:
	if owner_id == 0:
		return buy_car(index)
	var cars: Array = CarData.load_cars()
	if index < 0 or index >= cars.size():
		return false
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return false
	var current: int = int(ai_players[idx].get("car", -1))
	if index == current:
		return false
	var price: float = float(cars[index]["price"])
	if not spend_money(price, owner_id):
		return false
	if current >= 0 and current < cars.size():
		add_money(float(cars[current]["price"]) * 0.5, owner_id)
	ai_players[idx]["car"] = index
	return true

func buy_property_for_owner(owner_id: int, index: int) -> bool:
	if owner_id == 0:
		return buy_property(index)
	var properties: Array = PropertyData.load_properties()
	if index < 0 or index >= properties.size():
		return false
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return false
	var current: int = int(ai_players[idx].get("property", -1))
	if index == current:
		return false
	var price: float = float(properties[index]["price"])
	if not spend_money(price, owner_id):
		return false
	if current >= 0 and current < properties.size():
		add_money(float(properties[current]["price"]) * 0.5, owner_id)
	ai_players[idx]["property"] = index
	return true

func get_passive_income() -> float:
	var raw_cap: float = 0.0
	for e in get_enterprises_of_type("raw", 0):
		raw_cap += (float(e["prod_min"]) + float(e["prod_max"])) / 2.0
	var factory_cap: float = 0.0
	for e in get_enterprises_of_type("factory", 0):
		factory_cap += (float(e["prod_min"]) + float(e["prod_max"])) / 2.0
	var sales_cap: float = 0.0
	for e in get_enterprises_of_type("sales", 0):
		sales_cap += (float(e["prod_min"]) + float(e["prod_max"])) / 2.0
	var chain: float = minf(raw_cap, factory_cap)
	chain = minf(chain, sales_cap)
	var price: float = Market.get_base_price("product") * get_income_multiplier()
	return chain * price

func buy_car(index: int) -> bool:
	var cars: Array = CarData.load_cars()
	if index < 0 or index >= cars.size():
		return false
	if index == owned_car:
		return false
	var price: float = float(cars[index]["price"])
	if not spend_money(price, 0):
		return false
	if owned_car >= 0 and owned_car < cars.size():
		add_money(float(cars[owned_car]["price"]) * 0.5, 0)
	owned_car = index
	car_changed.emit()
	return true

func get_property_prestige() -> int:
	var prop: Dictionary = PropertyData.get_property(owned_property)
	return int(prop.get("prestige", 0))

func buy_property(index: int) -> bool:
	var properties: Array = PropertyData.load_properties()
	if index < 0 or index >= properties.size():
		return false
	if index == owned_property:
		return false
	var price: float = float(properties[index]["price"])
	if not spend_money(price, 0):
		return false
	if owned_property >= 0 and owned_property < properties.size():
		add_money(float(properties[owned_property]["price"]) * 0.5, 0)
	owned_property = index
	property_changed.emit()
	return true

func get_owner_ids() -> Array:
	var ids: Array = [0]
	for i in ai_players.size():
		ids.append(i + 1)
	return ids

func get_owner_color(owner_id: int) -> Color:
	if owner_id == 0:
		return Color(0.15, 0.32, 0.6)
	var idx: int = (owner_id - 1) % AI_COLORS.size()
	return AI_COLORS[idx]

func get_money(owner_id: int) -> float:
	if owner_id == 0:
		return money
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return 0.0
	return float(ai_players[idx]["money"])

func add_money(amount: float, owner_id: int = 0) -> void:
	if owner_id == 0:
		money += amount
		money_changed.emit()
		if not has_won and money >= win_amount:
			has_won = true
			game_won.emit()
	else:
		var idx: int = owner_id - 1
		if idx < 0 or idx >= ai_players.size():
			return
		ai_players[idx]["money"] = float(ai_players[idx]["money"]) + amount

func spend_money(amount: float, owner_id: int = 0) -> bool:
	if owner_id == 0:
		if money < amount:
			return false
		money -= amount
		money_changed.emit()
		return true
	else:
		var idx: int = owner_id - 1
		if idx < 0 or idx >= ai_players.size():
			return false
		if float(ai_players[idx]["money"]) < amount:
			return false
		ai_players[idx]["money"] = float(ai_players[idx]["money"]) - amount
		return true

func get_inventory(kind: String, owner_id: int = 0) -> int:
	if owner_id == 0:
		return int(inventory.get(kind, 0))
	var idx: int = owner_id - 1
	if idx < 0 or idx >= ai_players.size():
		return 0
	return int(ai_players[idx]["inventory"].get(kind, 0))

func add_to_inventory(kind: String, amount: int, owner_id: int = 0) -> void:
	if owner_id == 0:
		inventory[kind] = int(inventory.get(kind, 0)) + amount
		inventory_changed.emit()
	else:
		var idx: int = owner_id - 1
		if idx < 0 or idx >= ai_players.size():
			return
		var inv: Dictionary = ai_players[idx]["inventory"]
		inv[kind] = int(inv.get(kind, 0)) + amount

func consume_from_inventory(kind: String, amount: int, owner_id: int = 0) -> int:
	if owner_id == 0:
		var available: int = int(inventory.get(kind, 0))
		var consumed: int = mini(available, amount)
		inventory[kind] = available - consumed
		inventory_changed.emit()
		return consumed
	else:
		var idx: int = owner_id - 1
		if idx < 0 or idx >= ai_players.size():
			return 0
		var inv: Dictionary = ai_players[idx]["inventory"]
		var available: int = int(inv.get(kind, 0))
		var consumed: int = mini(available, amount)
		inv[kind] = available - consumed
		return consumed

func get_enterprise_owner(etype: String, level: int) -> int:
	for e in enterprises:
		if e["type"] == etype and int(e["level"]) == level:
			return int(e.get("owner", 0))
	return -1

func is_enterprise_available(etype: String, level: int) -> bool:
	return get_enterprise_owner(etype, level) == -1

func buy_enterprise(etype: String, level_data: Dictionary, owner_id: int = 0) -> bool:
	var level: int = int(level_data.get("level", 1))
	if not is_enterprise_available(etype, level):
		return false
	var price: float = float(level_data.get("price", 0))
	if not spend_money(price, owner_id):
		return false
	enterprises.append({
		"type": etype,
		"level": level,
		"price": price,
		"prod_min": int(level_data.get("prod_min", 0)),
		"prod_max": int(level_data.get("prod_max", 0)),
		"owner": owner_id,
	})
	enterprises_changed.emit()
	return true

func sell_enterprise(index: int, owner_id: int = 0) -> float:
	var owner_ents: Array = get_enterprises_of_owner(owner_id)
	if index < 0 or index >= owner_ents.size():
		return 0.0
	var target: Dictionary = owner_ents[index]
	var global_idx: int = enterprises.find(target)
	if global_idx < 0:
		return 0.0
	var sell_price: float = float(target["price"]) * 0.7
	enterprises.remove_at(global_idx)
	add_money(sell_price, owner_id)
	enterprises_changed.emit()
	return sell_price

func get_enterprises_of_owner(owner_id: int) -> Array:
	return enterprises.filter(func(e): return int(e.get("owner", 0)) == owner_id)

func get_enterprises_of_type(etype: String, owner_id: int = 0) -> Array:
	return enterprises.filter(func(e):
		return e["type"] == etype and int(e.get("owner", 0)) == owner_id
	)

func count_enterprises_of_type(etype: String, owner_id: int = 0) -> int:
	return get_enterprises_of_type(etype, owner_id).size()
