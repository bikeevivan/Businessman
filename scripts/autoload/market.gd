extends Node

signal lots_changed

const BASE_PRICE: Dictionary = {"raw": 10.0, "product": 20.0}

var lots: Array = []
var next_lot_id: int = 1

func reset() -> void:
	lots = []
	next_lot_id = 1
	lots_changed.emit()

func get_base_price(kind: String) -> float:
	return float(BASE_PRICE.get(kind, 10.0))

func get_price(kind: String) -> float:
	return get_base_price(kind)

func get_lots() -> Array:
	return lots

func get_lots_of_kind(kind: String) -> Array:
	return lots.filter(func(l): return l["kind"] == kind)

func get_lots_of_owner(owner_id: int) -> Array:
	return lots.filter(func(l): return int(l["owner"]) == owner_id)

func get_best_price(kind: String) -> float:
	var best: float = 0.0
	for l in lots:
		if l["kind"] == kind:
			var p: float = float(l["price"])
			if best == 0.0 or p < best:
				best = p
	if best == 0.0:
		return get_base_price(kind)
	return best

func post_lot(owner_id: int, kind: String, qty: int, price: float) -> bool:
	if qty <= 0 or price <= 0.0:
		return false
	var available: int = GameState.get_inventory(kind, owner_id)
	qty = mini(qty, available)
	if qty <= 0:
		return false
	GameState.consume_from_inventory(kind, qty, owner_id)
	lots.append({
		"id": next_lot_id,
		"owner": owner_id,
		"kind": kind,
		"qty": qty,
		"price": price,
	})
	next_lot_id += 1
	lots_changed.emit()
	return true

func cancel_lot(lot_id: int, owner_id: int) -> bool:
	for i in lots.size():
		if int(lots[i]["id"]) == lot_id:
			if int(lots[i]["owner"]) != owner_id:
				return false
			var l: Dictionary = lots[i]
			GameState.add_to_inventory(l["kind"], int(l["qty"]), owner_id)
			lots.remove_at(i)
			lots_changed.emit()
			return true
	return false

func buy_from_lot(lot_id: int, buyer_id: int, qty: int) -> Dictionary:
	for i in lots.size():
		if int(lots[i]["id"]) == lot_id:
			var l: Dictionary = lots[i]
			if int(l["owner"]) == buyer_id:
				return {"ok": false, "reason": "own"}
			var want: int = mini(qty, int(l["qty"]))
			if want <= 0:
				return {"ok": false, "reason": "qty"}
			var price: float = float(l["price"])
			var total: float = price * want
			if not GameState.spend_money(total, buyer_id):
				return {"ok": false, "reason": "money"}
			GameState.add_to_inventory(l["kind"], want, buyer_id)
			GameState.add_money(total, int(l["owner"]))
			l["qty"] = int(l["qty"]) - want
			var filled: bool = int(l["qty"]) <= 0
			if filled:
				lots.remove_at(i)
			lots_changed.emit()
			return {"ok": true, "qty": want, "total": total, "price": price, "filled": filled}
	return {"ok": false, "reason": "missing"}
