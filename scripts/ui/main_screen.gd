extends Control

const ExchangeScene = preload("res://scenes/exchange.tscn")
const EnterprisesScene = preload("res://scenes/enterprises.tscn")
const CarsScene = preload("res://scenes/cars.tscn")
const PropertiesScene = preload("res://scenes/properties.tscn")
const WORK_PAY: float = 50.0

var main_margin: MarginContainer
var exchange_panel: Control
var enterprises_panel: Control
var cars_panel: Control
var properties_panel: Control

var money_label: Label
var income_label: Label
var turn_label: Label
var ai_container: GridContainer
var home_button: Button
var raw_label: Label
var product_label: Label
var work_button: Button

var info_dialog: AcceptDialog
var work_confirm: ConfirmationDialog
var exit_dialog: AcceptDialog
var save_slot_dialog: AcceptDialog
var save_slot_box: VBoxContainer
var delete_confirm: ConfirmationDialog
var game_won_dialog: AcceptDialog
var car_art: CarArt
var car_name_lbl: Label
var property_art: PropertyArt
var property_name_lbl: Label
var _save_then_exit: bool = false
var _pending_delete_slot: int = -1

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_refresh_all()

func _build_ui() -> void:
	UIBackground.add(self, "menu", Color(0.03, 0.05, 0.09, 0.65))

	var board = PanelContainer.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.offset_left = 20
	board.offset_top = 20
	board.offset_right = -20
	board.offset_bottom = -20
	add_child(board)

	main_margin = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 40)
	main_margin.add_theme_constant_override("margin_right", 40)
	main_margin.add_theme_constant_override("margin_top", 30)
	main_margin.add_theme_constant_override("margin_bottom", 30)
	board.add_child(main_margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	main_margin.add_child(root)

	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 34)
	root.add_child(top_bar)

	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 34)
	info_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	info_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_bar.add_child(info_row)

	home_button = Button.new()
	home_button.text = tr("g_menu")
	home_button.tooltip_text = tr("g_menu_tip")
	home_button.custom_minimum_size = Vector2(96, 45)
	home_button.add_theme_font_size_override("font_size", 21)
	home_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	home_button.pressed.connect(_request_exit)
	info_row.add_child(home_button)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 20)
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(money_label)

	income_label = Label.new()
	income_label.add_theme_font_size_override("font_size", 16)
	income_label.add_theme_color_override("font_color", Color(0.45, 0.85, 0.45))
	income_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(income_label)

	turn_label = Label.new()
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(turn_label)

	raw_label = Label.new()
	raw_label.add_theme_font_size_override("font_size", 16)
	raw_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	raw_label.add_theme_color_override("font_color", Color(0.85, 0.55, 0.2))
	info_row.add_child(raw_label)

	product_label = Label.new()
	product_label.add_theme_font_size_override("font_size", 16)
	product_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	product_label.add_theme_color_override("font_color", Color(0.3, 0.75, 0.45))
	info_row.add_child(product_label)

	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_spacer)

	ai_container = GridContainer.new()
	ai_container.columns = 2
	ai_container.add_theme_constant_override("h_separation", 18)
	ai_container.add_theme_constant_override("v_separation", 2)
	ai_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	ai_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_bar.add_child(ai_container)

	var middle_spacer = Control.new()
	middle_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(middle_spacer)

	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 40)
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.size_flags_vertical = Control.SIZE_SHRINK_END
	root.add_child(bottom_row)

	var car_col = VBoxContainer.new()
	car_col.add_theme_constant_override("separation", 6)
	car_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	car_col.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_row.add_child(car_col)

	var transport_lbl = Label.new()
	transport_lbl.text = tr("g_current_transport")
	transport_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transport_lbl.add_theme_font_size_override("font_size", 20)
	transport_lbl.add_theme_color_override("font_color", Color(0.7, 0.82, 1.0))
	car_col.add_child(transport_lbl)

	var car_frame = PanelContainer.new()
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.13, 0.2, 1)
	frame_style.set_border_width_all(2)
	frame_style.border_color = Color(0.28, 0.38, 0.55, 1)
	frame_style.set_corner_radius_all(0)
	frame_style.content_margin_left = 0.0
	frame_style.content_margin_top = 0.0
	frame_style.content_margin_right = 0.0
	frame_style.content_margin_bottom = 0.0
	car_frame.add_theme_stylebox_override("panel", frame_style)
	car_col.add_child(car_frame)

	car_art = CarArt.new()
	car_art.custom_minimum_size = Vector2(320, 320)
	car_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	car_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	car_frame.add_child(car_art)

	var car_name_lbl = Label.new()
	car_name_lbl.name = "CarName"
	car_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	car_name_lbl.add_theme_font_size_override("font_size", 18)
	car_col.add_child(car_name_lbl)
	self.car_name_lbl = car_name_lbl

	var property_col = VBoxContainer.new()
	property_col.add_theme_constant_override("separation", 6)
	property_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	property_col.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_row.add_child(property_col)

	var property_lbl = Label.new()
	property_lbl.text = tr("g_current_property")
	property_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	property_lbl.add_theme_font_size_override("font_size", 20)
	property_lbl.add_theme_color_override("font_color", Color(0.7, 0.82, 1.0))
	property_col.add_child(property_lbl)

	var property_frame = PanelContainer.new()
	var property_style = StyleBoxFlat.new()
	property_style.bg_color = Color(0.1, 0.13, 0.2, 1)
	property_style.set_border_width_all(2)
	property_style.border_color = Color(0.28, 0.38, 0.55, 1)
	property_style.set_corner_radius_all(0)
	property_style.content_margin_left = 0.0
	property_style.content_margin_top = 0.0
	property_style.content_margin_right = 0.0
	property_style.content_margin_bottom = 0.0
	property_frame.add_theme_stylebox_override("panel", property_style)
	property_col.add_child(property_frame)

	property_art = PropertyArt.new()
	property_art.custom_minimum_size = Vector2(320, 320)
	property_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	property_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	property_frame.add_child(property_art)

	var property_name_lbl = Label.new()
	property_name_lbl.name = "PropertyName"
	property_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	property_name_lbl.add_theme_font_size_override("font_size", 18)
	property_col.add_child(property_name_lbl)
	self.property_name_lbl = property_name_lbl

	var row_spacer = Control.new()
	row_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(row_spacer)

	var block = VBoxContainer.new()
	block.size_flags_horizontal = Control.SIZE_SHRINK_END
	block.add_theme_constant_override("separation", 10)
	bottom_row.add_child(block)

	work_button = Button.new()
	work_button.text = tr("g_work_fmt") % int(WORK_PAY)
	work_button.custom_minimum_size = Vector2(280, 56)
	work_button.add_theme_font_size_override("font_size", 19)
	work_button.pressed.connect(_on_work_pressed)
	block.add_child(work_button)

	var exchange_btn = Button.new()
	exchange_btn.text = tr("g_exchange")
	exchange_btn.custom_minimum_size = Vector2(280, 56)
	exchange_btn.add_theme_font_size_override("font_size", 19)
	exchange_btn.pressed.connect(_on_open_exchange)
	block.add_child(exchange_btn)

	var enterprises_btn = Button.new()
	enterprises_btn.text = tr("g_enterprises")
	enterprises_btn.custom_minimum_size = Vector2(280, 56)
	enterprises_btn.add_theme_font_size_override("font_size", 19)
	enterprises_btn.pressed.connect(_on_open_enterprises)
	block.add_child(enterprises_btn)

	var properties_btn = Button.new()
	properties_btn.text = tr("g_properties")
	properties_btn.custom_minimum_size = Vector2(280, 56)
	properties_btn.add_theme_font_size_override("font_size", 19)
	properties_btn.pressed.connect(_on_open_properties)
	block.add_child(properties_btn)

	var cars_btn = Button.new()
	cars_btn.text = tr("g_cars")
	cars_btn.custom_minimum_size = Vector2(280, 56)
	cars_btn.add_theme_font_size_override("font_size", 19)
	cars_btn.pressed.connect(_on_open_cars)
	block.add_child(cars_btn)

	var end_turn_btn = Button.new()
	end_turn_btn.text = "\u27A4  " + tr("g_end_turn")
	end_turn_btn.custom_minimum_size = Vector2(280, 64)
	end_turn_btn.add_theme_font_size_override("font_size", 22)
	var dark = StyleBoxFlat.new()
	dark.bg_color = Color(0.68, 0.72, 0.8)
	dark.corner_radius_top_left = 4
	dark.corner_radius_top_right = 4
	dark.corner_radius_bottom_right = 4
	dark.corner_radius_bottom_left = 4
	dark.border_width_left = 1
	dark.border_width_top = 1
	dark.border_width_right = 1
	dark.border_width_bottom = 1
	dark.border_color = Color(0.5, 0.55, 0.65)
	end_turn_btn.add_theme_stylebox_override("normal", dark)
	var dark_hover = dark.duplicate()
	dark_hover.bg_color = Color(0.6, 0.65, 0.74)
	end_turn_btn.add_theme_stylebox_override("hover", dark_hover)
	var dark_pressed = dark.duplicate()
	dark_pressed.bg_color = Color(0.52, 0.57, 0.67)
	end_turn_btn.add_theme_stylebox_override("pressed", dark_pressed)
	end_turn_btn.pressed.connect(_on_end_turn)
	block.add_child(end_turn_btn)

	exchange_panel = ExchangeScene.instantiate()
	add_child(exchange_panel)
	exchange_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exchange_panel.visible = false
	if exchange_panel.has_signal("back_requested"):
		exchange_panel.connect("back_requested", Callable(self, "_on_back_to_main"))

	enterprises_panel = EnterprisesScene.instantiate()
	add_child(enterprises_panel)
	enterprises_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enterprises_panel.visible = false
	if enterprises_panel.has_signal("back_requested"):
		enterprises_panel.connect("back_requested", Callable(self, "_on_back_to_main"))

	cars_panel = CarsScene.instantiate()
	add_child(cars_panel)
	cars_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cars_panel.visible = false
	if cars_panel.has_signal("back_requested"):
		cars_panel.connect("back_requested", Callable(self, "_on_back_to_main"))

	properties_panel = PropertiesScene.instantiate()
	add_child(properties_panel)
	properties_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	properties_panel.visible = false
	if properties_panel.has_signal("back_requested"):
		properties_panel.connect("back_requested", Callable(self, "_on_back_to_main"))

	info_dialog = AcceptDialog.new()
	info_dialog.title = tr("g_msg_title")
	add_child(info_dialog)
	_style_dialog(info_dialog)

	work_confirm = ConfirmationDialog.new()
	work_confirm.title = tr("g_work_title")
	work_confirm.dialog_text = tr("g_work_confirm_fmt") % int(WORK_PAY)
	work_confirm.confirmed.connect(_on_work_confirmed)
	add_child(work_confirm)
	_style_dialog(work_confirm)

	exit_dialog = AcceptDialog.new()
	exit_dialog.borderless = true
	exit_dialog.min_size = Vector2i(460, 0)
	var exit_menu = VBoxContainer.new()
	exit_menu.add_theme_constant_override("separation", 10)
	exit_dialog.add_child(exit_menu)
	var exit_lbl = Label.new()
	exit_lbl.text = tr("g_exit_confirm")
	exit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exit_lbl.add_theme_font_size_override("font_size", 19)
	exit_lbl.custom_minimum_size = Vector2(420, 77)
	exit_menu.add_child(exit_lbl)
	_make_exit_button(exit_menu, tr("g_save_exit"), _on_save_and_exit)
	_make_exit_button(exit_menu, tr("g_save"), _on_save_from_exit)
	_make_exit_button(exit_menu, tr("g_exit_only"), _on_exit_no_save)
	_make_exit_button(exit_menu, tr("m_back"), _on_exit_cancel, true)
	add_child(exit_dialog)
	exit_dialog.get_ok_button().get_parent().visible = false

	save_slot_dialog = AcceptDialog.new()
	save_slot_dialog.title = tr("g_save_title")
	save_slot_dialog.ok_button_text = tr("g_cancel")
	save_slot_box = VBoxContainer.new()
	save_slot_box.add_theme_constant_override("separation", 8)
	save_slot_dialog.add_child(save_slot_box)
	add_child(save_slot_dialog)
	_style_dialog(save_slot_dialog)

	delete_confirm = ConfirmationDialog.new()
	delete_confirm.title = tr("g_del_title")
	delete_confirm.ok_button_text = tr("g_yes_delete")
	delete_confirm.cancel_button_text = tr("g_no")
	delete_confirm.confirmed.connect(_on_delete_confirmed)
	add_child(delete_confirm)
	_style_dialog(delete_confirm)

	game_won_dialog = AcceptDialog.new()
	game_won_dialog.ok_button_text = tr("g_win_continue")
	game_won_dialog.add_button(tr("g_win_menu"), true).pressed.connect(_go_to_menu)
	add_child(game_won_dialog)
	_style_dialog(game_won_dialog)

func _style_dialog(dialog: AcceptDialog) -> void:
	dialog.min_size = Vector2i(460, 0)
	var lbl: Label = dialog.get_label()
	if lbl != null:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.custom_minimum_size = Vector2(420, 60)

func _connect_signals() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.turn_changed.connect(_on_turn_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.opponents_changed.connect(_refresh_ai_panel)
	GameState.antimonopoly_fine.connect(_on_antimonopoly_fine)
	GameState.car_changed.connect(_refresh_car)
	GameState.property_changed.connect(_refresh_property)
	TurnManager.turn_started.connect(_on_turn_started)
	RandomEvents.event_triggered.connect(_on_random_event)
	GameState.game_won.connect(_on_game_won)

func _refresh_all() -> void:
	_on_money_changed()
	_on_turn_changed()
	_on_inventory_changed()
	_refresh_ai_panel()
	_refresh_car()
	_refresh_property()

func _refresh_car() -> void:
	if car_art == null:
		return
	_refresh_income()
	var name_lbl = car_name_lbl
	if GameState.own_car():
		var car: Dictionary = CarData.get_car(GameState.owned_car)
		if not car.is_empty():
			car_art.set_car(CarData.get_car_color(car), str(car.get("kind", "sedan")), str(car.get("image", "")))
			if name_lbl is Label:
				name_lbl.text = tr("c_name_%s" % car["id"])
			car_art.visible = true
			return
	car_art.set_car(Color(0.85, 0.35, 0.3), "tram", "")
	if name_lbl is Label:
		name_lbl.text = tr("c_tram_name")
	car_art.visible = true

func _refresh_property() -> void:
	if property_art == null:
		return
	_refresh_income()
	if GameState.own_property():
		var prop: Dictionary = PropertyData.get_property(GameState.owned_property)
		if not prop.is_empty():
			property_art.set_property(PropertyData.get_property_color(prop), str(prop.get("kind", "house")), str(prop.get("image", "")))
			if property_name_lbl is Label:
				property_name_lbl.text = tr("p_name_%s" % prop["id"])
			property_art.visible = true
			return
	property_art.set_property(Color(0.35, 0.37, 0.42), "house", "")
	if property_name_lbl is Label:
		property_name_lbl.text = tr("p_none")
	property_art.visible = true

func _on_money_changed() -> void:
	money_label.text = "$%d" % int(GameState.money)
	_refresh_income()

func _refresh_income() -> void:
	if income_label != null:
		income_label.text = "(+%d$/ход)" % int(GameState.get_passive_income())

func _on_game_won() -> void:
	game_won_dialog.title = tr("g_win_title")
	game_won_dialog.dialog_text = tr("g_win_text") % int(GameState.win_amount)
	game_won_dialog.popup_centered()
	SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT_WIN)

func _on_turn_changed() -> void:
	turn_label.text = tr("g_turn") % GameState.turn

func _on_inventory_changed() -> void:
	raw_label.text = tr("g_raw") % GameState.inventory.get("raw", 0)
	product_label.text = tr("g_product") % GameState.inventory.get("product", 0)

func _refresh_ai_panel() -> void:
	for child in ai_container.get_children():
		child.queue_free()
	for i in GameState.ai_players.size():
		_add_ai_entry(i + 1)

func _add_ai_entry(ai_id: int) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_SHRINK_END

	var dot = ColorRect.new()
	dot.color = GameState.get_owner_color(ai_id)
	dot.custom_minimum_size = Vector2(14, 14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)

	var lbl = Label.new()
	lbl.text = tr("g_ai") % [ai_id, int(GameState.get_money(ai_id))]
	lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(lbl)

	ai_container.add_child(row)

func _on_turn_started(_turn: int) -> void:
	_refresh_all()

func _on_antimonopoly_fine(fine_amount: float, etype: String) -> void:
	var type_names = {"raw": tr("t_raw"), "factory": tr("t_factory"), "sales": tr("t_sales")}
	info_dialog.title = tr("g_anti_title")
	info_dialog.dialog_text = tr("g_anti_text") % [int(fine_amount), type_names.get(etype, etype)]
	info_dialog.popup_centered()

func _on_random_event(ev: Dictionary) -> void:
	info_dialog.title = ""
	var event_id: String = str(ev["id"])
	info_dialog.dialog_text = tr("ev_%s_desc" % event_id) + "\n\n" + tr("g_ev_effect") % tr("ev_%s_effect" % event_id)
	info_dialog.popup_centered()

func _on_work_pressed() -> void:
	work_confirm.dialog_text = tr("g_work_confirm_fmt") % int(WORK_PAY)
	work_confirm.popup_centered()

func _on_work_confirmed() -> void:
	GameState.add_money(WORK_PAY)
	TurnManager.work_turn()

func _on_open_exchange() -> void:
	if not GameState.own_car():
		if GameState.money < GameState.TRAM_FARE:
			info_dialog.title = tr("g_tram_title")
			info_dialog.dialog_text = tr("g_tram_no_money") % int(GameState.TRAM_FARE)
			info_dialog.popup_centered()
			return
		GameState.spend_money(GameState.TRAM_FARE, 0)
	main_margin.visible = false
	exchange_panel.visible = true
	if exchange_panel.has_method("refresh"):
		exchange_panel.refresh()

func _on_open_enterprises() -> void:
	main_margin.visible = false
	enterprises_panel.visible = true
	if enterprises_panel.has_method("refresh"):
		enterprises_panel.refresh()

func _on_open_cars() -> void:
	main_margin.visible = false
	cars_panel.visible = true
	if cars_panel.has_method("refresh"):
		cars_panel.refresh()

func _on_open_properties() -> void:
	main_margin.visible = false
	properties_panel.visible = true
	if properties_panel.has_method("refresh"):
		properties_panel.refresh()

func _on_back_to_main() -> void:
	exchange_panel.visible = false
	enterprises_panel.visible = false
	cars_panel.visible = false
	properties_panel.visible = false
	main_margin.visible = true
	_refresh_all()

func _on_save_pressed() -> void:
	_show_save_slot_dialog(false)

func _make_exit_button(parent: VBoxContainer, text: String, action: Callable, accent: bool = false) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 48)
	btn.add_theme_font_size_override("font_size", 18)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if accent:
		var light = StyleBoxFlat.new()
		light.bg_color = Color(0.68, 0.72, 0.8)
		light.corner_radius_top_left = 4
		light.corner_radius_top_right = 4
		light.corner_radius_bottom_right = 4
		light.corner_radius_bottom_left = 4
		light.border_width_left = 1
		light.border_width_top = 1
		light.border_width_right = 1
		light.border_width_bottom = 1
		light.border_color = Color(0.5, 0.55, 0.65)
		btn.add_theme_stylebox_override("normal", light)
		var light_hover = light.duplicate()
		light_hover.bg_color = Color(0.6, 0.65, 0.74)
		btn.add_theme_stylebox_override("hover", light_hover)
		var light_pressed = light.duplicate()
		light_pressed.bg_color = Color(0.52, 0.57, 0.67)
		btn.add_theme_stylebox_override("pressed", light_pressed)
	btn.pressed.connect(action)
	parent.add_child(btn)

func _on_exit_cancel() -> void:
	exit_dialog.hide()

func _on_save_from_exit() -> void:
	exit_dialog.hide()
	_on_save_pressed()

func _on_end_turn() -> void:
	TurnManager.end_turn()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if exchange_panel.visible or enterprises_panel.visible or cars_panel.visible or properties_panel.visible:
			_on_back_to_main()
		elif not exit_dialog.visible:
			_request_exit()
		get_viewport().set_input_as_handled()

func _request_exit() -> void:
	exit_dialog.popup_centered()

func _on_save_and_exit() -> void:
	exit_dialog.hide()
	_show_save_slot_dialog(true)

func _on_exit_no_save() -> void:
	_go_to_menu()

func _show_save_slot_dialog(then_exit: bool) -> void:
	_save_then_exit = then_exit
	_rebuild_slot_box()
	save_slot_dialog.popup_centered()

func _make_mode_badge() -> Label:
	var badge = Label.new()
	badge.text = "R"
	badge.custom_minimum_size = Vector2(26, 26)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", Color(0.85, 0.68, 0.3))
	var frame = StyleBoxFlat.new()
	frame.bg_color = Color(0.08, 0.1, 0.15, 0.6)
	frame.border_color = Color(0.85, 0.68, 0.3)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(13)
	badge.add_theme_stylebox_override("normal", frame)
	badge.mouse_filter = Control.MOUSE_FILTER_STOP
	badge.tooltip_text = tr("m_mode_realistic_tip")
	return badge

func _rebuild_slot_box() -> void:
	for child in save_slot_box.get_children():
		save_slot_box.remove_child(child)
		child.queue_free()

	for slot in range(1, SaveManager.MAX_SLOTS + 1):
		var info: Dictionary = SaveManager.get_save_info(slot)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var btn = Button.new()
		if info.is_empty():
			btn.text = tr("g_slot_empty") % slot
		else:
			btn.text = tr("g_slot_info") % [
				slot, int(info["turn"]), int(info["money"]), int(info["ai_count"])
			]
		btn.custom_minimum_size = Vector2(420, 46)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_slot_chosen.bind(slot))
		row.add_child(btn)

		if not info.is_empty() and bool(info.get("realistic_ai", false)):
			row.add_child(_make_mode_badge())

		if SaveManager.has_save_file(slot):
			var del_btn = Button.new()
			del_btn.text = tr("g_delete_btn")
			del_btn.custom_minimum_size = Vector2(130, 46)
			del_btn.add_theme_font_size_override("font_size", 18)
			del_btn.pressed.connect(_on_delete_slot_pressed.bind(slot))
			row.add_child(del_btn)

		save_slot_box.add_child(row)

func _on_delete_slot_pressed(slot: int) -> void:
	_pending_delete_slot = slot
	delete_confirm.dialog_text = tr("g_del_confirm") % slot
	delete_confirm.popup_centered()

func _on_delete_confirmed() -> void:
	var slot: int = _pending_delete_slot
	_pending_delete_slot = -1
	if slot < 1:
		return
	if SaveManager.delete_save(slot):
		_rebuild_slot_box()

func _on_slot_chosen(slot: int) -> void:
	GameState.current_save_slot = slot
	var saved: bool = SaveManager.save_game(slot)
	save_slot_dialog.hide()
	if _save_then_exit:
		_go_to_menu()
		return
	info_dialog.title = tr("g_save_title")
	info_dialog.dialog_text = tr("g_saved_ok") % slot if saved else tr("g_saved_err")
	info_dialog.popup_centered()

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

