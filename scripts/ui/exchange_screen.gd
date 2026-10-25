extends Control

signal back_requested

const COL_PRICE: int = 90
const COL_QTY: int = 70
const COL_SELLER: int = 100
const COL_ACTION: int = 260
const DEFAULT_QTY: int = 10

var raw_container: VBoxContainer
var product_container: VBoxContainer
var raw_qty_lbl: Label
var product_qty_lbl: Label
var raw_price_spin: SpinBox
var product_price_spin: SpinBox
var raw_post_btn: Button
var product_post_btn: Button
var money_lbl: Label
var inv_lbl: Label
var ref_lbl: Label
var travel_lbl: Label

var _refresh_queued: bool = false
var _lots_sig: String = ""

func _ready() -> void:
	_build_ui()
	_refresh()
	Market.lots_changed.connect(_queue_refresh)
	GameState.inventory_changed.connect(_queue_refresh)
	GameState.money_changed.connect(_queue_refresh)

func refresh() -> void:
	_refresh()

func _queue_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_flush_refresh.call_deferred()

func _flush_refresh() -> void:
	_refresh_queued = false
	_refresh()

func _build_ui() -> void:
	UIBackground.add(self, "exchange", Color(0.03, 0.05, 0.09, 0.12))

	var board = PanelContainer.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.offset_left = 20
	board.offset_top = 20
	board.offset_right = -20
	board.offset_bottom = -20
	add_child(board)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	board.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 18)
	vbox.add_child(info_row)

	var back_btn = Button.new()
	back_btn.text = tr("x_back")
	back_btn.custom_minimum_size = Vector2(140, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_on_back)
	info_row.add_child(back_btn)

	var title = Label.new()
	title.text = tr("x_title")
	title.add_theme_font_size_override("font_size", 30)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(spacer)

	money_lbl = Label.new()
	money_lbl.add_theme_font_size_override("font_size", 20)
	money_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(money_lbl)

	inv_lbl = Label.new()
	inv_lbl.add_theme_font_size_override("font_size", 20)
	inv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(inv_lbl)

	var sub_row = HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 18)
	vbox.add_child(sub_row)

	ref_lbl = Label.new()
	ref_lbl.add_theme_font_size_override("font_size", 14)
	ref_lbl.add_theme_color_override("font_color", Color.GRAY)
	ref_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_row.add_child(ref_lbl)

	travel_lbl = Label.new()
	travel_lbl.add_theme_font_size_override("font_size", 14)
	travel_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	travel_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_row.add_child(travel_lbl)

	var sub_spacer = Control.new()
	sub_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_row.add_child(sub_spacer)

	var stepper_hint = Label.new()
	stepper_hint.text = tr("x_stepper_hint")
	stepper_hint.add_theme_font_size_override("font_size", 14)
	stepper_hint.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8))
	stepper_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sub_row.add_child(stepper_hint)

	vbox.add_child(HSeparator.new())

	var tables = HBoxContainer.new()
	tables.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tables.add_theme_constant_override("separation", 16)
	vbox.add_child(tables)

	var raw_table: Dictionary = _make_table(tr("x_table_raw"), "raw")
	raw_container = raw_table["container"]
	raw_qty_lbl = raw_table["qty"]
	raw_price_spin = raw_table["price"]
	raw_post_btn = raw_table["btn"]
	tables.add_child(raw_table["panel"])

	var product_table: Dictionary = _make_table(tr("x_table_product"), "product")
	product_container = product_table["container"]
	product_qty_lbl = product_table["qty"]
	product_price_spin = product_table["price"]
	product_post_btn = product_table["btn"]
	tables.add_child(product_table["panel"])

func _make_table(title: String, kind: String) -> Dictionary:
	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title_lbl)

	var post: Dictionary = _make_post_row(kind)
	panel.add_child(post["row"])

	panel.add_child(_make_header_row())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 6)
	scroll.add_child(container)

	return {
		"panel": panel,
		"container": container,
		"qty": post["qty"],
		"price": post["price"],
		"btn": post["btn"],
	}

func _make_post_row(kind: String) -> Dictionary:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl = Label.new()
	lbl.text = tr("x_post_lbl")
	lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(lbl)

	var stepper: Dictionary = _make_stepper(DEFAULT_QTY, 1, DEFAULT_QTY)
	row.add_child(stepper["box"])

	var price_lbl = Label.new()
	price_lbl.text = tr("x_price")
	price_lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(price_lbl)

	var price_spin = SpinBox.new()
	price_spin.min_value = 0.5
	price_spin.step = 0.5
	price_spin.value = Market.get_base_price(kind)
	price_spin.custom_minimum_size = Vector2(80, 48)
	price_spin.add_theme_font_size_override("font_size", 16)
	row.add_child(price_spin)

	var btn = Button.new()
	btn.text = tr("x_post_btn")
	btn.custom_minimum_size = Vector2(115, 48)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_on_post.bind(kind, stepper["value"], price_spin))
	row.add_child(btn)

	return {"row": row, "qty": stepper["value"], "price": price_spin, "btn": btn}

func _make_header_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_cell(tr("x_h_price"), COL_PRICE, Color.GRAY))
	row.add_child(_make_cell(tr("x_h_qty"), COL_QTY, Color.GRAY))
	row.add_child(_make_cell(tr("x_h_seller"), COL_SELLER, Color.GRAY))
	row.add_child(_make_cell(tr("x_h_action"), COL_ACTION, Color.GRAY))
	return row

func _make_cell(text: String, width: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 0)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func _make_stepper(initial: int, min_v: int, max_v: int) -> Dictionary:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	var minus = Button.new()
	minus.text = "\u2212"
	minus.custom_minimum_size = Vector2(48, 48)
	minus.add_theme_font_size_override("font_size", 28)
	minus.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))

	var value_lbl = Label.new()
	value_lbl.custom_minimum_size = Vector2(56, 48)
	value_lbl.add_theme_font_size_override("font_size", 24)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var plus = Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(48, 48)
	plus.add_theme_font_size_override("font_size", 28)
	plus.add_theme_color_override("font_color", Color(0.35, 0.9, 0.4))

	_set_range(value_lbl, min_v, max_v, initial)
	value_lbl.set_meta("touched", false)
	minus.pressed.connect(_step_value.bind(value_lbl, -1))
	plus.pressed.connect(_step_value.bind(value_lbl, 1))

	box.add_child(minus)
	box.add_child(value_lbl)
	box.add_child(plus)
	return {"box": box, "value": value_lbl}

func _set_range(lbl: Label, min_v: int, max_v: int, value: int = -1) -> void:
	var lo: int = maxi(min_v, 0)
	var hi: int = maxi(lo, max_v)
	lbl.set_meta("min", lo)
	lbl.set_meta("max", hi)
	var v: int = value if value >= 0 else int(lbl.get_meta("value", lo))
	lbl.set_meta("value", clampi(v, lo, hi))
	lbl.text = str(lbl.get_meta("value"))

func _step_value(lbl: Label, dir: int) -> void:
	var step: int = 1
	if Input.is_key_pressed(KEY_SHIFT):
		step = 100
	elif Input.is_key_pressed(KEY_CTRL):
		step = 10
	var v: int = int(lbl.get_meta("value")) + dir * step
	lbl.set_meta("value", clampi(v, int(lbl.get_meta("min")), int(lbl.get_meta("max"))))
	lbl.set_meta("touched", true)
	lbl.text = str(lbl.get_meta("value"))

func _on_post(kind: String, value_lbl: Label, price_spin: SpinBox) -> void:
	Market.post_lot(0, kind, int(value_lbl.get_meta("value")), float(price_spin.value))

func _refresh() -> void:
	if money_lbl == null:
		return
	if not is_visible_in_tree():
		return
	money_lbl.text = tr("x_money") % int(GameState.money)
	inv_lbl.text = tr("x_inv") % [
		GameState.get_inventory("raw", 0), GameState.get_inventory("product", 0)
	]
	ref_lbl.text = tr("x_ref") % [
		Market.get_base_price("raw"), Market.get_base_price("product")
	]
	if GameState.own_car():
		var car: Dictionary = CarData.get_car(GameState.owned_car)
		travel_lbl.text = tr("x_car") % tr("c_name_%s" % car.get("id", ""))
	else:
		travel_lbl.text = tr("x_tram") % int(GameState.TRAM_FARE)
	_update_post_form("raw", raw_qty_lbl, raw_post_btn)
	_update_post_form("product", product_qty_lbl, product_post_btn)
	_rebuild_lots()

func _update_post_form(kind: String, value_lbl: Label, btn: Button) -> void:
	var inv: int = GameState.get_inventory(kind, 0)
	var hi: int = maxi(1, inv)
	if bool(value_lbl.get_meta("touched", false)):
		_set_range(value_lbl, 1, hi)
	else:
		_set_range(value_lbl, 1, hi, mini(DEFAULT_QTY, hi))
	btn.disabled = inv <= 0

func _rebuild_lots() -> void:
	var sig: String = _lots_signature()
	if sig == _lots_sig:
		_update_buy_buttons(raw_container)
		_update_buy_buttons(product_container)
		return
	_lots_sig = sig
	_fill_table(raw_container, "raw")
	_fill_table(product_container, "product")

func _lots_signature() -> String:
	var parts: PackedStringArray = []
	for l in Market.lots:
		parts.append("%d:%d:%s:%d:%s" % [int(l["id"]), int(l["owner"]), l["kind"], int(l["qty"]), str(l["price"])])
	return ",".join(parts)

func _update_buy_buttons(container: VBoxContainer) -> void:
	for row in container.get_children():
		if row.has_meta("buy_btn"):
			(row.get_meta("buy_btn") as Button).disabled = GameState.money < float(row.get_meta("price"))

func _fill_table(container: VBoxContainer, kind: String) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	var lots: Array = Market.get_lots_of_kind(kind)
	if lots.is_empty():
		var lbl = Label.new()
		lbl.text = tr("x_empty")
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color.GRAY)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(lbl)
		return

	lots.sort_custom(func(a, b): return float(a["price"]) < float(b["price"]))
	for lot in lots:
		container.add_child(_make_lot_row(lot))

func _make_lot_row(lot: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	row.add_child(_make_cell("$%.2f" % float(lot["price"]), COL_PRICE, Color(0.9, 0.85, 0.4)))
	row.add_child(_make_cell("%d" % int(lot["qty"]), COL_QTY, Color.WHITE))

	var owner_id: int = int(lot["owner"])
	var seller_text: String = tr("x_you") if owner_id == 0 else tr("x_seller_ai") % owner_id
	row.add_child(_make_cell(seller_text, COL_SELLER, GameState.get_owner_color(owner_id)))

	var action = HBoxContainer.new()
	action.add_theme_constant_override("separation", 8)
	action.custom_minimum_size = Vector2(COL_ACTION, 0)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(action)

	if owner_id == 0:
		var cancel_btn = Button.new()
		cancel_btn.text = tr("x_cancel_btn")
		cancel_btn.custom_minimum_size = Vector2(150, 48)
		cancel_btn.add_theme_font_size_override("font_size", 16)
		cancel_btn.pressed.connect(_on_cancel.bind(int(lot["id"])))
		action.add_child(cancel_btn)
	else:
		var lot_qty: int = int(lot["qty"])
		var stepper: Dictionary = _make_stepper(mini(DEFAULT_QTY, lot_qty), 1, lot_qty)
		action.add_child(stepper["box"])

		var buy_btn = Button.new()
		buy_btn.text = tr("x_buy_btn")
		buy_btn.custom_minimum_size = Vector2(120, 48)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.disabled = GameState.money < float(lot["price"])
		buy_btn.pressed.connect(_on_buy_lot.bind(int(lot["id"]), stepper["value"]))
		action.add_child(buy_btn)
		row.set_meta("buy_btn", buy_btn)
		row.set_meta("price", float(lot["price"]))

	return row

func _on_buy_lot(lot_id: int, value_lbl: Label) -> void:
	Market.buy_from_lot(lot_id, 0, int(value_lbl.get_meta("value")))

func _on_cancel(lot_id: int) -> void:
	Market.cancel_lot(lot_id, 0)

func _on_back() -> void:
	back_requested.emit()
