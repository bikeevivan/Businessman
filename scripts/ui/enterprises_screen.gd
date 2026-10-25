extends Control

signal back_requested

const TYPE_LIST = ["raw", "factory", "sales"]
const TYPE_COLORS = {"raw": Color(0.75, 0.5, 0.2), "factory": Color(0.35, 0.55, 0.8), "sales": Color(0.3, 0.7, 0.4)}
const FREE_COLOR = Color(0.45, 0.45, 0.5)

var enterprises_data: Dictionary = {}
var grid: GridContainer
var money_lbl: Label
var warn_label: Label

var buy_confirm: ConfirmationDialog
var sell_confirm: ConfirmationDialog
var info_dialog: AcceptDialog

var _pending_buy_etype: String = ""
var _pending_buy_level: Dictionary = {}
var _pending_sell_index: int = -1

func _ready() -> void:
	enterprises_data = EnterpriseData.load_enterprises()
	_build_ui()
	_refresh()
	GameState.enterprises_changed.connect(_refresh)
	GameState.money_changed.connect(_refresh)

func refresh() -> void:
	_refresh()

func _build_ui() -> void:
	UIBackground.add(self, "enterprises")

	var board = PanelContainer.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.offset_left = 18
	board.offset_top = 18
	board.offset_right = -18
	board.offset_bottom = -18
	add_child(board)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	board.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 18)
	vbox.add_child(info_row)

	var back_btn = Button.new()
	back_btn.text = tr("e_back")
	back_btn.custom_minimum_size = Vector2(140, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_on_back)
	info_row.add_child(back_btn)

	var title = Label.new()
	title.text = tr("e_title")
	title.add_theme_font_size_override("font_size", 30)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(spacer)

	money_lbl = Label.new()
	money_lbl.text = tr("e_money") % int(GameState.money)
	money_lbl.add_theme_font_size_override("font_size", 20)
	money_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(money_lbl)

	warn_label = Label.new()
	warn_label.text = tr("e_warn")
	warn_label.add_theme_font_size_override("font_size", 16)
	warn_label.add_theme_color_override("font_color", Color.RED)
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.visible = false
	vbox.add_child(warn_label)

	var grid_holder = CenterContainer.new()
	grid_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid_holder)

	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 150)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_holder.add_child(grid)

	buy_confirm = ConfirmationDialog.new()
	buy_confirm.title = tr("e_buy_title")
	buy_confirm.confirmed.connect(_on_buy_confirmed)
	add_child(buy_confirm)
	_style_dialog(buy_confirm)

	sell_confirm = ConfirmationDialog.new()
	sell_confirm.title = tr("e_sell_title")
	sell_confirm.confirmed.connect(_on_sell_confirmed)
	add_child(sell_confirm)
	_style_dialog(sell_confirm)

	info_dialog = AcceptDialog.new()
	info_dialog.title = tr("e_msg_title")
	add_child(info_dialog)
	_style_dialog(info_dialog)

func _style_dialog(dialog: AcceptDialog) -> void:
	dialog.min_size = Vector2i(460, 0)
	var lbl: Label = dialog.get_label()
	if lbl != null:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.custom_minimum_size = Vector2(420, 60)

func _refresh() -> void:
	_update_money()
	if grid == null:
		return
	if not is_visible_in_tree():
		return

	var max_type: int = 0
	for etype in TYPE_LIST:
		max_type = maxi(max_type, GameState.count_enterprises_of_type(etype, 0))
	warn_label.visible = max_type >= 2

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	var corner = Label.new()
	corner.text = tr("e_prod")
	corner.add_theme_font_size_override("font_size", 16)
	corner.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	corner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	corner.custom_minimum_size = Vector2(90, 0)
	grid.add_child(corner)

	for etype in TYPE_LIST:
		var hdr = Label.new()
		hdr.text = _type_name(etype)
		hdr.add_theme_font_size_override("font_size", 20)
		hdr.add_theme_color_override("font_color", TYPE_COLORS[etype])
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(hdr)

	var levels_size = enterprises_data.get(TYPE_LIST[0], []).size()
	for level_idx in levels_size:
		var prod_data: Dictionary = enterprises_data[TYPE_LIST[0]][level_idx]
		var prod_label = Label.new()
		prod_label.text = "%d–%d" % [int(prod_data["prod_min"]), int(prod_data["prod_max"])]
		prod_label.add_theme_font_size_override("font_size", 16)
		prod_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
		prod_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prod_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prod_label.custom_minimum_size = Vector2(90, 0)
		grid.add_child(prod_label)

		for etype in TYPE_LIST:
			var level_data: Dictionary = enterprises_data[etype][level_idx]
			grid.add_child(_make_cell(etype, level_data))

func _make_cell(etype: String, level_data: Dictionary) -> Button:
	var level_num: int = int(level_data["level"])
	var owner_id: int = GameState.get_enterprise_owner(etype, level_num)

	var bg: Color = FREE_COLOR if owner_id == -1 else GameState.get_owner_color(owner_id)
	var btn = Button.new()
	btn.text = "$%d" % int(level_data["price"])
	btn.custom_minimum_size = Vector2(170, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 16)
	btn.disabled = (owner_id > 0) or (owner_id == -1 and GameState.money < float(level_data["price"]))
	_style_cell(btn, bg, owner_id)
	btn.pressed.connect(_on_cell_pressed.bind(etype, level_data, owner_id))
	return btn

func _style_cell(btn: Button, bg: Color, owner_id: int) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.12)
	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.15)
	var disabled = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = bg.darkened(0.25)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)

	var font_color: Color = Color.WHITE if bg.get_luminance() < 0.45 else Color(0.08, 0.08, 0.1)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_color)
	btn.add_theme_color_override("font_disabled_color", font_color)

	if owner_id == 0:
		btn.tooltip_text = tr("e_tip_own")
	elif owner_id > 0:
		btn.tooltip_text = tr("e_tip_ai") % owner_id
	else:
		btn.tooltip_text = tr("e_tip_free")

func _on_cell_pressed(etype: String, level_data: Dictionary, owner_id: int) -> void:
	if owner_id == -1:
		_pending_buy_etype = etype
		_pending_buy_level = level_data
		buy_confirm.dialog_text = tr("e_buy_confirm") % [
			_type_name(etype), int(level_data["level"]), int(level_data["price"])
		]
		buy_confirm.popup_centered()
	elif owner_id == 0:
		_pending_sell_index = _find_owned_index(etype, int(level_data["level"]))
		if _pending_sell_index < 0:
			return
		sell_confirm.dialog_text = tr("e_sell_confirm") % [
			_type_name(etype), int(level_data["level"]), int(int(level_data["price"]) * 0.7)
		]
		sell_confirm.popup_centered()

func _on_buy_confirmed() -> void:
	var ok: bool = GameState.buy_enterprise(_pending_buy_etype, _pending_buy_level, 0)
	_refresh()
	if not ok:
		info_dialog.dialog_text = tr("e_buy_failed")
		info_dialog.popup_centered()

func _on_sell_confirmed() -> void:
	if _pending_sell_index < 0:
		return
	GameState.sell_enterprise(_pending_sell_index, 0)
	_pending_sell_index = -1
	_refresh()

func _find_owned_index(etype: String, level: int) -> int:
	var owned: Array = GameState.get_enterprises_of_owner(0)
	for i in owned.size():
		if owned[i]["type"] == etype and int(owned[i]["level"]) == level:
			return i
	return -1

func _update_money() -> void:
	if money_lbl:
		money_lbl.text = tr("e_money") % int(GameState.money)

func _type_name(etype: String) -> String:
	match etype:
		"raw":
			return tr("t_raw")
		"factory":
			return tr("t_factory")
		"sales":
			return tr("t_sales")
	return etype

func _on_back() -> void:
	back_requested.emit()
