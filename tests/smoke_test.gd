extends Node

var failures: Array = []

func _ready() -> void:
	_cleanup_saves()
	RandomEvents.enabled = false
	_test_initial_state()
	_test_enterprise_data()
	_test_unique_ownership()
	_test_buy_sell_enterprise()
	_test_production_chain()
	_test_antimonopoly()
	_test_market_lots()
	_test_ai_players()
	_test_long_game_lots()
	_test_win_condition()
	_test_cars()
	_test_properties()
	_test_random_events()
	_test_save_load()
	_test_save_delete()

	if failures.is_empty():
		print("SMOKE TEST: ALL PASSED")
		get_tree().quit(0)
	else:
		print("SMOKE TEST: %d FAILURES" % failures.size())
		for f in failures:
			print("  FAIL: ", f)
		get_tree().quit(1)

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func _cleanup_saves() -> void:
	SaveManager.set_save_dir("user://smoke_test_saves")
	for slot in range(1, SaveManager.MAX_SLOTS + 1):
		SaveManager.delete_save(slot)

func _test_initial_state() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	check(GameState.money == 500.0, "start money == 500 (got %s)" % GameState.money)
	check(GameState.turn == 1, "start turn == 1 (got %d)" % GameState.turn)
	check(GameState.inventory["raw"] == 0, "start raw == 0")
	check(GameState.enterprises.is_empty(), "start enterprises empty")
	check(GameState.ai_count == 1, "ai_count == 1 after reset_for_new_game(1)")
	check(GameState.owned_car == -1, "start without a car")
	check(GameState.owned_property == -1, "start without property")

func _test_enterprise_data() -> void:
	var data = EnterpriseData.load_enterprises()
	check(not data.is_empty(), "enterprises.json loaded")
	check(data.get("raw", []).size() == 10, "raw has 10 levels")
	check(data.get("factory", []).size() == 10, "factory has 10 levels")
	check(data.get("sales", []).size() == 10, "sales has 10 levels")
	var l1: Dictionary = data["raw"][0]
	check(int(l1["price"]) == 400, "raw L1 price == 400")
	check(int(l1["prod_min"]) == 14 and int(l1["prod_max"]) == 15, "raw L1 prod 14-15")
	var l10: Dictionary = data["raw"][9]
	check(int(l10["prod_min"]) == 135 and int(l10["prod_max"]) == 150, "raw L10 prod 135-150")

func _test_unique_ownership() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	var data = EnterpriseData.load_enterprises()
	GameState.money = 5000.0
	GameState.ai_players[0]["money"] = 5000.0

	check(GameState.is_enterprise_available("raw", 1), "raw L1 available at start")
	check(GameState.get_enterprise_owner("raw", 1) == -1, "owner -1 when unowned")

	var ok = GameState.buy_enterprise("raw", data["raw"][0], 0)
	check(ok, "player buys raw L1")
	check(GameState.get_enterprise_owner("raw", 1) == 0, "raw L1 owner == player")
	check(not GameState.is_enterprise_available("raw", 1), "raw L1 no longer available")

	var ai_ok = GameState.buy_enterprise("raw", data["raw"][0], 1)
	check(not ai_ok, "AI cannot buy a level already owned by player")

	var ai_ok2 = GameState.buy_enterprise("raw", data["raw"][1], 1)
	check(ai_ok2, "AI can buy a different level")
	check(GameState.get_enterprise_owner("raw", 2) == 1, "raw L2 owner == ai 1")
	check(GameState.get_enterprises_of_owner(0).size() == 1, "player owns 1")
	check(GameState.get_enterprises_of_owner(1).size() == 1, "ai 1 owns 1")

func _test_buy_sell_enterprise() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	var data = EnterpriseData.load_enterprises()

	var ok = GameState.buy_enterprise("raw", data["raw"][0])
	check(ok, "buy raw L1 succeeds")
	check(GameState.money == 100.0, "money 500-400==100 (got %s)" % GameState.money)
	check(GameState.enterprises.size() == 1, "1 enterprise owned")

	ok = GameState.buy_enterprise("raw", data["raw"][1])
	check(not ok, "cannot buy L2 with $100")

	GameState.money = 500.0
	GameState.money_changed.emit()
	var sell_price = GameState.sell_enterprise(0)
	check(absf(sell_price - 280.0) < 0.01, "sell price == 400*0.7==280 (got %s)" % sell_price)
	check(GameState.money == 780.0, "money 500+280==780 (got %s)" % GameState.money)
	check(GameState.enterprises.is_empty(), "no enterprises after sell")
	check(GameState.is_enterprise_available("raw", 1), "raw L1 available again after sell")

func _test_production_chain() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	var data = EnterpriseData.load_enterprises()

	GameState.money = 2000.0
	GameState.money_changed.emit()
	GameState.buy_enterprise("raw", data["raw"][0])
	GameState.buy_enterprise("factory", data["factory"][0])
	GameState.buy_enterprise("sales", data["sales"][0])
	check(GameState.enterprises.size() == 3, "3 enterprises bought (got %d)" % GameState.enterprises.size())
	GameState.money = 0.0
	GameState.money_changed.emit()

	var money_before = GameState.money
	TurnManager.end_turn()

	var raw_left = GameState.inventory["raw"]
	var prod_left = GameState.inventory["product"]
	check(raw_left >= 0, "raw non-negative")
	check(prod_left >= 0, "product non-negative")
	check(GameState.money > money_before, "sales earned money (%s -> %s)" % [money_before, GameState.money])
	check(GameState.turn == 2, "turn advanced to 2")

func _test_antimonopoly() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	var data = EnterpriseData.load_enterprises()

	GameState.money = 2000.0
	GameState.money_changed.emit()
	GameState.buy_enterprise("raw", data["raw"][0])
	GameState.buy_enterprise("raw", data["raw"][1])
	check(GameState.get_enterprises_of_type("raw").size() == 2, "2 raw enterprises owned")

	var money_before = GameState.money
	TurnManager.end_turn()
	check(GameState.antimonopoly_timers["0_raw"] == 1, "timer==1 after turn 1 (got %s)" % GameState.antimonopoly_timers.get("0_raw", "missing"))
	check(GameState.money == money_before, "no fine after 1st turn")

	TurnManager.end_turn()
	check(GameState.antimonopoly_timers["0_raw"] == 0, "timer reset after fine (got %s)" % GameState.antimonopoly_timers.get("0_raw", "missing"))
	var expected_fine = 0.15 * (400 + 640)
	check(absf((money_before - GameState.money) - expected_fine) < 1.0, "fine == 0.15*(400+640)==156 (got %s)" % (money_before - GameState.money))

func _test_market_lots() -> void:
	GameState.reset_for_new_game(2)
	Market.reset()

	check(absf(Market.get_base_price("raw") - 10.0) < 0.01, "raw base price == 10")
	check(absf(Market.get_base_price("product") - 20.0) < 0.01, "product base price == 20")

	GameState.money = 1000.0
	GameState.add_to_inventory("raw", 10)
	check(Market.post_lot(0, "raw", 10, 12.0), "post lot succeeds")
	check(GameState.get_inventory("raw", 0) == 0, "inventory escrowed after post")
	check(Market.get_lots().size() == 1, "1 lot on market")
	var lot: Dictionary = Market.get_lots()[0]
	check(int(lot["qty"]) == 10, "lot qty 10")
	check(absf(float(lot["price"]) - 12.0) < 0.01, "lot price 12")

	var own_buy = Market.buy_from_lot(int(lot["id"]), 0, 5)
	check(not own_buy["ok"], "cannot buy own lot")

	var ai_money: float = GameState.get_money(1)
	var r2 = Market.buy_from_lot(int(lot["id"]), 1, 5)
	check(r2["ok"], "ai buys 5 from lot")
	check(int(r2["qty"]) == 5, "ai bought 5")
	check(GameState.get_inventory("raw", 1) == 5, "ai received 5 raw")
	check(absf(GameState.money - 1060.0) < 0.01, "player received 60 (got %s)" % GameState.money)
	check(absf(GameState.get_money(1) - (ai_money - 60.0)) < 0.01, "ai paid 60")
	check(int(Market.get_lots()[0]["qty"]) == 5, "lot has 5 remaining (partial fill)")

	var r3 = Market.buy_from_lot(int(lot["id"]), 2, 5)
	check(r3["ok"] and r3["filled"], "second ai fills remaining 5")
	check(Market.get_lots().is_empty(), "lot removed when fully filled")

	GameState.add_to_inventory("raw", 4)
	Market.post_lot(0, "raw", 4, 9.0)
	var lot2: Dictionary = Market.get_lots()[0]
	check(absf(Market.get_best_price("raw") - 9.0) < 0.01, "best price == cheapest lot")
	check(Market.cancel_lot(int(lot2["id"]), 0), "cancel own lot")
	check(GameState.get_inventory("raw", 0) == 4, "goods returned after cancel")
	check(Market.get_lots().is_empty(), "no lots after cancel")

	GameState.add_to_inventory("product", 3, 1)
	Market.post_lot(1, "product", 3, 25.0)
	var lot3: Dictionary = Market.get_lots()[0]
	check(not Market.cancel_lot(int(lot3["id"]), 0), "cannot cancel another owner's lot")

	Market.reset()
	check(absf(Market.get_best_price("raw") - 10.0) < 0.01, "best price falls back to base when no lots")

func _test_ai_players() -> void:
	GameState.reset_for_new_game(3)
	Market.reset()
	check(GameState.ai_count == 3, "ai_count == 3 (got %d)" % GameState.ai_count)
	check(GameState.get_owner_ids().size() == 4, "owner ids: player + 3 ai")

	AIManager.take_turns()
	var ai_ents = GameState.get_enterprises_of_owner(1)
	check(ai_ents.size() >= 1, "ai 1 bought at least 1 enterprise (got %d)" % ai_ents.size())

	for i in 8:
		for ai_id in range(1, 4):
			GameState.add_money(500.0, ai_id)
		AIManager.take_turns()

	for ai_id in range(1, 4):
		var types: Dictionary = {}
		var dupes: bool = false
		for e in GameState.get_enterprises_of_owner(ai_id):
			if types.has(e["type"]):
				dupes = true
			types[e["type"]] = true
		check(not dupes, "ai %d never owns duplicate types" % ai_id)
		check(GameState.get_enterprises_of_owner(ai_id).size() <= 3, "ai %d owns at most 3 enterprises" % ai_id)

	var owned_1: Array = GameState.get_enterprises_of_owner(1)
	check(owned_1.size() == 3, "ai 1 builds a full chain (got %d)" % owned_1.size())
	var upgraded: bool = false
	for e in owned_1:
		if int(e["level"]) > 1:
			upgraded = true
	check(upgraded, "ai 1 reinvests by upgrading levels")

	GameState.reset_for_new_game(1)
	Market.reset()
	var edata: Dictionary = EnterpriseData.load_enterprises()
	GameState.buy_enterprise("raw", edata["raw"][0], 0)
	GameState.add_money(200000.0, 1)
	AIManager.take_turns()
	var ai_raw: int = GameState.count_enterprises_of_type("raw", 1)
	check(ai_raw >= 1, "ai competes for the player's raw type (deny) (got %d)" % ai_raw)

func _test_long_game_lots() -> void:
	GameState.reset_for_new_game(8)
	Market.reset()
	GameState.money = 5000.0
	GameState.money_changed.emit()
	for i in 150:
		TurnManager.end_turn()
	check(Market.get_lots().size() <= 2 * GameState.ai_count, "AI lots stay bounded after 150 turns (got %d)" % Market.get_lots().size())

func _test_win_condition() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	check(not GameState.has_won, "not won at start")
	var won: Array = [false]
	GameState.game_won.connect(func() -> void: won[0] = true)

	GameState.money = 999000.0
	GameState.money_changed.emit()
	check(not GameState.has_won, "no win below threshold")
	GameState.add_money(2000.0)
	check(GameState.has_won, "win when money reaches 1000000 (got %s)" % GameState.money)
	check(won[0], "game_won signal emitted")

	GameState.add_money(10000.0)
	check(won[0] and GameState.has_won, "win stays latched")

	GameState.reset_for_new_game(1, 75000.0)
	check(absf(GameState.win_amount - 75000.0) < 0.01, "custom win amount applied (got %s)" % GameState.win_amount)
	GameState.reset_for_new_game(1, 10000.0)
	check(absf(GameState.win_amount - GameState.MIN_WIN_AMOUNT) < 0.01, "win amount clamped up to min (got %s)" % GameState.win_amount)
	GameState.reset_for_new_game(1, 9000000.0)
	check(absf(GameState.win_amount - GameState.MAX_WIN_AMOUNT) < 0.01, "win amount clamped down to max (got %s)" % GameState.win_amount)
	GameState.reset_for_new_game(1)
	check(absf(GameState.win_amount - GameState.DEFAULT_WIN_AMOUNT) < 0.01, "default win amount restored (got %s)" % GameState.win_amount)

func _test_cars() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	check(GameState.owned_car == -1, "no car at start")
	check(not GameState.own_car(), "own_car false at start")
	check(GameState.get_prestige() == 0, "prestige 0 without car")
	check(absf(GameState.get_sales_multiplier() - 1.0) < 0.001, "sales multiplier 1.0 without car")

	var cars: Array = CarData.load_cars()
	check(cars.size() == 8, "8 cars defined (got %d)" % cars.size())
	var ascending: bool = true
	for i in range(1, cars.size()):
		if int(cars[i]["price"]) <= int(cars[i - 1]["price"]):
			ascending = false
		if int(cars[i]["prestige"]) <= int(cars[i - 1]["prestige"]):
			ascending = false
	check(ascending, "car prices and prestige strictly ascend")
	check(str(cars[0]["id"]) == "oka", "first car is Oka (got %s)" % cars[0]["id"])
	check(str(cars[7]["id"]) == "veyron", "last car is Veyron (got %s)" % cars[7]["id"])

	GameState.money = 400.0
	GameState.money_changed.emit()
	check(not GameState.buy_car(0), "cannot buy Oka with $400")
	check(GameState.owned_car == -1, "still no car after failed buy")

	GameState.money = 1500.0
	GameState.money_changed.emit()
	check(GameState.buy_car(0), "buy Oka with $1500")
	check(GameState.owned_car == 0, "owned_car == 0")
	check(absf(GameState.money - 1000.0) < 0.01, "money 1500-500==1000 (got %s)" % GameState.money)
	check(GameState.get_prestige() == 1, "prestige 1 for Oka")
	check(absf(GameState.get_sales_multiplier() - 1.01) < 0.001, "sales multiplier 1.01")
	check(not GameState.buy_car(0), "cannot rebuy the same car")

	GameState.money = 20000.0
	GameState.money_changed.emit()
	check(GameState.buy_car(2), "buy Logan (third car)")
	check(GameState.owned_car == 2, "owned_car == 2")
	check(absf(GameState.money - 17500.0) < 0.01, "trade-in refunds half of Oka: 20000-2750+250==17500 (got %s)" % GameState.money)

	GameState.money = 500.0
	GameState.money_changed.emit()
	GameState.buy_car(7)
	check(GameState.owned_car == 2, "expensive car not bought without money")

	var data = EnterpriseData.load_enterprises()
	GameState.reset_for_new_game(1)
	Market.reset()
	GameState.money = 100000.0
	GameState.buy_enterprise("sales", data["sales"][0])
	GameState.money = 0.0
	GameState.money_changed.emit()
	GameState.add_to_inventory("product", 50)
	seed(999)
	TurnManager.produce_for_owner(0)
	var no_car: float = GameState.money

	GameState.reset_for_new_game(1)
	Market.reset()
	GameState.money = 100000.0
	GameState.buy_enterprise("sales", data["sales"][0])
	GameState.money = 0.0
	GameState.money_changed.emit()
	GameState.add_to_inventory("product", 50)
	GameState.owned_car = 7
	seed(999)
	TurnManager.produce_for_owner(0)
	var with_car: float = GameState.money
	check(no_car > 0.0, "sales produced income without a car (got %s)" % no_car)
	check(absf(with_car - no_car * 1.4) < 0.5, "prestige boosts sales income by 1.4x (%s vs %s)" % [with_car, no_car])

func _test_properties() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	check(GameState.owned_property == -1, "no property at start")
	check(not GameState.own_property(), "own_property false at start")
	check(GameState.get_property_prestige() == 0, "property prestige 0 without property")

	var props: Array = PropertyData.load_properties()
	check(props.size() == 7, "7 properties defined (got %d)" % props.size())
	var ascending: bool = true
	for i in range(1, props.size()):
		if int(props[i]["price"]) <= int(props[i - 1]["price"]):
			ascending = false
		if int(props[i]["prestige"]) <= int(props[i - 1]["prestige"]):
			ascending = false
	check(ascending, "property prices and prestige strictly ascend")
	check(str(props[0]["id"]) == "shed", "first property is shed (got %s)" % props[0]["id"])
	check(str(props[6]["id"]) == "palace", "last property is palace (got %s)" % props[6]["id"])

	GameState.money = 500.0
	GameState.money_changed.emit()
	check(not GameState.buy_property(0), "cannot buy shed with $500")
	check(GameState.owned_property == -1, "still no property after failed buy")

	GameState.money = 900.0
	GameState.money_changed.emit()
	check(GameState.buy_property(0), "buy shed with $900")
	check(GameState.owned_property == 0, "owned_property == 0")
	check(absf(GameState.money - 100.0) < 0.01, "money 900-800==100 (got %s)" % GameState.money)
	check(GameState.get_property_prestige() == 1, "prestige 1 for shed")
	check(GameState.get_total_prestige() == 1, "total prestige 1 with shed and no car")
	check(absf(GameState.get_income_multiplier() - 1.01) < 0.001, "shed gives +1% income")
	check(not GameState.buy_property(0), "cannot rebuy the same property")

	GameState.money = 6000.0
	GameState.money_changed.emit()
	check(GameState.buy_property(2), "buy city apartment (third property)")
	check(GameState.owned_property == 2, "owned_property == 2")
	check(absf(GameState.money - 900.0) < 0.01, "trade-in refunds half of shed: 6000-5500+400==900 (got %s)" % GameState.money)
	check(absf(GameState.get_income_multiplier() - 1.07) < 0.001, "city apartment gives +7% income")

	GameState.money = 500.0
	GameState.money_changed.emit()
	GameState.buy_property(6)
	check(GameState.owned_property == 2, "expensive property not bought without money")

	GameState.owned_car = 7
	check(GameState.get_total_prestige() == 47, "car and property prestige stack (got %d)" % GameState.get_total_prestige())
	check(absf(GameState.get_income_multiplier() - 1.47) < 0.001, "stacked prestige gives +47% sales")

func _test_random_events() -> void:
	GameState.reset_for_new_game(1)
	Market.reset()
	check(RandomEvents.get_events().size() == 11, "11 random events defined (got %d)" % RandomEvents.get_events().size())

	GameState.money = 1000.0
	RandomEvents.trigger_by_id("find_small_wallet")
	check(absf(GameState.money - 1100.0) < 0.01, "small wallet +100 (got %s)" % GameState.money)

	GameState.money = 1000.0
	RandomEvents.trigger_by_id("bank_error_good")
	check(absf(GameState.money - 1500.0) < 0.01, "bank error good x1.5 (got %s)" % GameState.money)

	GameState.money = 1000.0
	RandomEvents.trigger_by_id("lost_wallet")
	check(absf(GameState.money - 900.0) < 0.01, "lost wallet x0.9 (got %s)" % GameState.money)

	GameState.money = 1000.0
	RandomEvents.trigger_by_id("bank_error_bad")
	check(absf(GameState.money - 500.0) < 0.01, "bank error bad x0.5 (got %s)" % GameState.money)

	GameState.add_to_inventory("raw", 10)
	GameState.add_to_inventory("product", 5)
	RandomEvents.trigger_by_id("exchange_error")
	check(GameState.get_inventory("raw", 0) == 20, "exchange error doubles raw (got %d)" % GameState.get_inventory("raw", 0))
	check(GameState.get_inventory("product", 0) == 10, "exchange error doubles product (got %d)" % GameState.get_inventory("product", 0))

	RandomEvents.trigger_by_id("warehouse_raid")
	check(GameState.get_inventory("raw", 0) == 10, "raid halves raw (got %d)" % GameState.get_inventory("raw", 0))
	check(GameState.get_inventory("product", 0) == 5, "raid halves product (got %d)" % GameState.get_inventory("product", 0))

	GameState.production_multiplier = 1.0
	RandomEvents.trigger_by_id("evening_overtime")
	check(absf(GameState.production_multiplier - 2.0) < 0.01, "overtime sets production x2")

	GameState.production_multiplier = 1.0
	RandomEvents.trigger_by_id("strikes")
	check(absf(GameState.production_multiplier - 0.5) < 0.01, "strikes sets production x0.5")

	var money_before = GameState.money
	GameState.production_multiplier = 1.0
	GameState.owned_car = 3
	RandomEvents.trigger_by_id("car_broken")
	check(GameState.owned_car == -1, "car_broken removes the car")
	check(GameState.money == money_before, "car_broken does not change money")
	check(absf(GameState.production_multiplier - 1.0) < 0.01, "car_broken leaves production multiplier")

func _test_save_load() -> void:
	GameState.reset_for_new_game(2)
	Market.reset()
	var data = EnterpriseData.load_enterprises()
	GameState.buy_enterprise("factory", data["factory"][0])
	GameState.money = 1234.5
	GameState.money_changed.emit()
	GameState.add_to_inventory("raw", 42)
	GameState.add_to_inventory("product", 5)
	Market.post_lot(0, "product", 5, 22.0)
	GameState.current_save_slot = 5
	GameState.has_won = true
	GameState.owned_car = 4
	GameState.owned_property = 3

	check(SaveManager.save_game(), "save_game returns true")
	check(SaveManager.has_save(5), "slot 5 exists after save")
	var info: Dictionary = SaveManager.get_save_info(5)
	check(int(info.get("ai_count", 0)) == 2, "save info ai_count == 2")
	check(absf(float(info.get("money", 0)) - 1234.5) < 0.01, "save info money == 1234.5")

	GameState.reset_for_new_game(1)
	Market.reset()
	check(GameState.money == 500.0, "money reset before load")

	check(SaveManager.load_game(5), "load_game returns true")
	check(absf(GameState.money - 1234.5) < 0.01, "money restored (got %s)" % GameState.money)
	check(GameState.inventory["raw"] == 42, "raw inventory restored")
	check(GameState.get_inventory("product", 0) == 0, "escrowed product stays escrowed")
	check(Market.get_lots().size() == 1, "market lot restored")
	check(GameState.enterprises.size() == 1, "1 enterprise restored")
	check(GameState.enterprises[0]["type"] == "factory", "factory type restored")
	check(int(GameState.enterprises[0]["owner"]) == 0, "restored enterprise owner == player")
	check(GameState.ai_count == 2, "ai_count restored == 2")
	check(GameState.has_won, "win flag restored from save")
	check(GameState.owned_car == 4, "owned car restored from save")
	check(GameState.owned_property == 3, "owned property restored from save")

	SaveManager.delete_save(5)
	check(not SaveManager.has_save(5), "slot 5 deleted")

func _test_save_delete() -> void:
	SaveManager.set_save_dir("user://smoke_test_saves")

	var slot: int = 2
	SaveManager.delete_save(slot)
	GameState.reset_for_new_game(1)
	Market.reset()

	check(SaveManager.save_game(slot), "save_game slot %d succeeds" % slot)
	check(SaveManager.has_save(slot), "slot %d occupied" % slot)
	check(SaveManager.has_save_file(slot), "slot %d file exists" % slot)
	check(SaveManager.delete_save(slot), "delete_save returns true")
	check(not SaveManager.has_save(slot), "has_save false after delete")
	check(not SaveManager.has_save_file(slot), "has_save_file false after delete")
	check(SaveManager.get_available_slot() == slot, "get_available_slot returns freed slot %d" % slot)

	var invalid_slot: int = 3
	SaveManager.delete_save(invalid_slot)
	var path: String = SaveManager.save_dir + "save_%d.json" % invalid_slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "opened slot %d for writing invalid json" % invalid_slot)
	if file != null:
		file.store_string("not json{")
		file.close()

	check(not SaveManager.has_save(invalid_slot), "has_save false for invalid json")
	check(SaveManager.has_save_file(invalid_slot), "has_save_file true for invalid json file")
	check(SaveManager.delete_save(invalid_slot), "delete_save invalid json returns true")
	check(not SaveManager.has_save_file(invalid_slot), "has_save_file false after deleting invalid json")
