extends Node

signal event_triggered(event: Dictionary)

const EVENT_CHANCE: float = 0.10

var enabled: bool = true

var _events: Array = [
	{
		"id": "find_small_wallet", "kind": "positive",
		"title": "Маленький кошелёк",
		"desc": "Вы нашли маленький кошелёк с деньгами.",
		"effect": "+$100",
	},
	{
		"id": "find_wallet", "kind": "positive",
		"title": "Кошелёк",
		"desc": "Вы нашли кошелёк с деньгами.",
		"effect": "+$200",
	},
	{
		"id": "find_big_wallet", "kind": "positive",
		"title": "Огромный кошелёк",
		"desc": "Вы нашли огромный кошелёк с деньгами.",
		"effect": "+$300",
	},
	{
		"id": "bank_error_good", "kind": "positive",
		"title": "Ошибка в банке",
		"desc": "Ошибка в банке, в итоге в вашу пользу.",
		"effect": "Деньги ×1.5",
	},
	{
		"id": "exchange_error", "kind": "positive",
		"title": "Ошибка на бирже",
		"desc": "Ошибка на бирже — склад удвоен.",
		"effect": "Сырьё и товары ×2",
	},
	{
		"id": "evening_overtime", "kind": "positive",
		"title": "Вечерние переработки",
		"desc": "Вечерние переработки, пятилетку за 2 года!",
		"effect": "Производство ×2 на 1 ход",
	},
	{
		"id": "lost_wallet", "kind": "negative",
		"title": "Потеря кошелька",
		"desc": "Вы потеряли кошелёк.",
		"effect": "Деньги ×0.9",
	},
	{
		"id": "bank_error_bad", "kind": "negative",
		"title": "Ошибка в банке",
		"desc": "Банковская ошибка не в вашу пользу.",
		"effect": "Деньги ×0.5",
	},
	{
		"id": "strikes", "kind": "negative",
		"title": "Забастовка",
		"desc": "Рабочие требуют повышения зарплаты.",
		"effect": "Производство ×0.5 на 1 ход",
	},
	{
		"id": "warehouse_raid", "kind": "negative",
		"title": "Проверка склада",
		"desc": "Проверка склада — половину запасов изъяли.",
		"effect": "Сырьё и товары ×0.5",
	},
	{
		"id": "car_broken", "kind": "negative",
		"title": "Поломка машины",
		"desc": "У вашего автомобиля сломался двигатель.",
		"effect": "Машина пропадает",
	},
]

func get_events() -> Array:
	return _events

func maybe_trigger() -> Dictionary:
	return maybe_trigger_for(0)

func maybe_trigger_for(owner_id: int) -> Dictionary:
	if not enabled:
		return {}
	if randf() >= EVENT_CHANCE:
		return {}
	return trigger_by_id(_events[randi() % _events.size()]["id"], owner_id)

func trigger_by_id(id: String, owner_id: int = 0) -> Dictionary:
	for ev in _events:
		if ev["id"] == id:
			_apply(ev, owner_id)
			if owner_id == 0:
				event_triggered.emit(ev)
			return ev
	return {}

func _apply(ev: Dictionary, owner_id: int = 0) -> void:
	match ev["id"]:
		"find_small_wallet":
			GameState.add_money(100.0, owner_id)
		"find_wallet":
			GameState.add_money(200.0, owner_id)
		"find_big_wallet":
			GameState.add_money(300.0, owner_id)
		"bank_error_good":
			GameState.add_money(GameState.get_money(owner_id) * 0.5, owner_id)
		"exchange_error":
			GameState.add_to_inventory("raw", GameState.get_inventory("raw", owner_id), owner_id)
			GameState.add_to_inventory("product", GameState.get_inventory("product", owner_id), owner_id)
		"evening_overtime":
			GameState.set_production_multiplier(owner_id, 2.0)
		"lost_wallet":
			GameState.add_money(-GameState.get_money(owner_id) * 0.1, owner_id)
		"bank_error_bad":
			GameState.add_money(-GameState.get_money(owner_id) * 0.5, owner_id)
		"strikes":
			GameState.set_production_multiplier(owner_id, 0.5)
		"warehouse_raid":
			GameState.scale_inventory(owner_id, 0.5)
		"car_broken":
			GameState.break_car(owner_id)
		_:
			pass
