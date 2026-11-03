extends Control

const GAME_SCENE: String = "res://scenes/main.tscn"

var _lang_option: OptionButton
var _music_check: CheckBox
var _win_amount_edit: LineEdit
var _win_amount_error: Label
var _realistic_ai_check: CheckButton
var delete_confirm: ConfirmationDialog
var _pending_delete_slot: int = -1
var donate_dialog: AcceptDialog

func _ready() -> void:
	delete_confirm = ConfirmationDialog.new()
	delete_confirm.title = tr("m_del_title")
	delete_confirm.ok_button_text = tr("m_yes_delete")
	delete_confirm.cancel_button_text = tr("m_no")
	delete_confirm.confirmed.connect(_on_delete_confirmed)
	add_child(delete_confirm)
	_style_dialog(delete_confirm)

	donate_dialog = AcceptDialog.new()
	donate_dialog.title = tr("m_donate")
	donate_dialog.ok_button_text = tr("m_ok")
	add_child(donate_dialog)
	_style_dialog(donate_dialog)

	show_main_menu()

func _clear() -> void:
	for child in get_children():
		if child == delete_confirm or child == donate_dialog:
			continue
		child.queue_free()

func _make_page() -> VBoxContainer:
	_clear()
	UIBackground.add(self, "menu", Color(0.04, 0.06, 0.10, 0.28))

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var board = PanelContainer.new()
	center.add_child(board)

	var panel = VBoxContainer.new()
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 18)
	board.add_child(panel)
	return panel

func _make_title(parent: Node, text: String, size: int = 56) -> void:
	var title = Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", size)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(title)

func _make_button(parent: Node, text: String, handler: Callable, width: int = 420, height: int = 64, font: int = 24) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", font)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(handler)
	parent.add_child(btn)
	return btn

func show_main_menu() -> void:
	var page = _make_page()
	_make_title(page, tr("m_title"))
	_add_spacer(page, 40)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 80)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(row)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)

	_make_button(col, tr("m_new_game"), show_new_game)
	_make_button(col, tr("m_load"), show_load)
	_make_button(col, tr("m_settings"), show_settings)
	var donate_btn = _make_button(col, "\u2665  " + tr("m_donate"), _on_donate, 420, 56, 20)
	donate_btn.add_theme_color_override("font_color", Color(0.85, 0.15, 0.2))
	_make_button(col, tr("m_exit"), _on_exit)
	_add_version_label()

func _add_version_label() -> void:
	var lbl = Label.new()
	lbl.text = tr("m_version") % Version.get_version()
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.92))
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.05, 0.09, 0.82)
	bg.set_corner_radius_all(4)
	bg.content_margin_left = 5.0
	bg.content_margin_top = 4.0
	bg.content_margin_right = 5.0
	bg.content_margin_bottom = 4.0
	lbl.add_theme_stylebox_override("normal", bg)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	lbl.offset_left = -224.0
	lbl.offset_top = -42.0
	lbl.offset_right = -14.0
	lbl.offset_bottom = -10.0
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

func _add_spacer(parent: Node, height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)

func _style_dialog(dialog: AcceptDialog) -> void:
	dialog.min_size = Vector2i(460, 0)
	var lbl: Label = dialog.get_label()
	if lbl != null:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.custom_minimum_size = Vector2(420, 60)

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

func show_new_game() -> void:
	var page = _make_page()
	_make_title(page, tr("m_choose_opponents"), 34)
	_add_spacer(page, 12)

	var amount_row = HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 14)
	amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(amount_row)

	var amount_lbl = Label.new()
	amount_lbl.text = tr("m_win_amount")
	amount_lbl.add_theme_font_size_override("font_size", 20)
	amount_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_row.add_child(amount_lbl)

	_win_amount_edit = LineEdit.new()
	_win_amount_edit.text = str(int(GameState.DEFAULT_WIN_AMOUNT))
	_win_amount_edit.custom_minimum_size = Vector2(200, 44)
	_win_amount_edit.add_theme_font_size_override("font_size", 20)
	_win_amount_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_amount_edit.max_length = 7
	_win_amount_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_win_amount_edit.text_changed.connect(_on_win_amount_changed)
	_win_amount_edit.gui_input.connect(_on_win_amount_input)
	amount_row.add_child(_win_amount_edit)

	_win_amount_error = Label.new()
	_win_amount_error.add_theme_font_size_override("font_size", 15)
	_win_amount_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_amount_error.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(_win_amount_error)
	_update_win_amount_hint()

	_add_spacer(page, 10)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(grid)

	for i in range(GameState.MIN_OPPONENTS, GameState.MAX_OPPONENTS + 1):
		var btn = Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(84, 84)
		btn.add_theme_font_size_override("font_size", 32)
		btn.pressed.connect(_start_new_game.bind(i))
		grid.add_child(btn)

	_add_spacer(page, 18)

	_realistic_ai_check = CheckButton.new()
	_realistic_ai_check.text = tr("m_realistic_ai")
	_realistic_ai_check.button_pressed = GameState.realistic_ai
	_realistic_ai_check.add_theme_font_size_override("font_size", 20)
	_realistic_ai_check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_realistic_ai_check.toggled.connect(func(on: bool) -> void: GameState.realistic_ai = on)
	page.add_child(_realistic_ai_check)

	var realistic_note = Label.new()
	realistic_note.text = tr("m_realistic_ai_note")
	realistic_note.add_theme_font_size_override("font_size", 14)
	realistic_note.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	realistic_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realistic_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realistic_note.custom_minimum_size = Vector2(760, 0)
	realistic_note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(realistic_note)

	_add_spacer(page, 20)
	_make_button(page, tr("m_back"), show_main_menu, 260, 54, 20)

func _on_win_amount_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.keycode
		var allowed: bool = false
		if kc >= KEY_0 and kc <= KEY_9:
			allowed = true
		elif kc >= KEY_KP_0 and kc <= KEY_KP_9:
			allowed = true
		elif kc in [KEY_BACKSPACE, KEY_DELETE, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END, KEY_TAB, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			allowed = true
		if event.ctrl_pressed and kc in [KEY_A, KEY_C, KEY_V, KEY_X]:
			allowed = true
		if not allowed:
			get_viewport().set_input_as_handled()

func _on_win_amount_changed(new_text: String) -> void:
	var caret: int = _win_amount_edit.caret_column
	var digits: String = ""
	for ch in new_text:
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits != new_text:
		_win_amount_edit.text = digits
		_win_amount_edit.caret_column = mini(caret, digits.length())
	_update_win_amount_hint()

func _is_win_amount_valid() -> bool:
	if _win_amount_edit == null:
		return false
	var t: String = _win_amount_edit.text
	if t.is_empty() or not t.is_valid_int():
		return false
	var v: int = t.to_int()
	return v >= int(GameState.MIN_WIN_AMOUNT) and v <= int(GameState.MAX_WIN_AMOUNT)

func _update_win_amount_hint() -> void:
	if _win_amount_error == null:
		return
	if _is_win_amount_valid():
		_win_amount_error.text = tr("m_win_amount_hint") % [int(GameState.MIN_WIN_AMOUNT), int(GameState.MAX_WIN_AMOUNT)]
		_win_amount_error.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	else:
		_win_amount_error.text = tr("m_win_amount_invalid") % [int(GameState.MIN_WIN_AMOUNT), int(GameState.MAX_WIN_AMOUNT)]
		_win_amount_error.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))

func _parse_win_amount() -> float:
	if _win_amount_edit == null:
		return GameState.DEFAULT_WIN_AMOUNT
	return clampf(float(_win_amount_edit.text.to_int()), GameState.MIN_WIN_AMOUNT, GameState.MAX_WIN_AMOUNT)

func _start_new_game(opponents: int) -> void:
	if not _is_win_amount_valid():
		_update_win_amount_hint()
		var dlg = AcceptDialog.new()
		dlg.title = tr("m_settings")
		dlg.dialog_text = tr("m_win_amount_invalid") % [int(GameState.MIN_WIN_AMOUNT), int(GameState.MAX_WIN_AMOUNT)]
		dlg.ok_button_text = tr("m_ok")
		add_child(dlg)
		dlg.popup_centered()
		dlg.confirmed.connect(dlg.queue_free)
		dlg.canceled.connect(dlg.queue_free)
		return
	var amount: float = _parse_win_amount()
	var realistic: bool = _realistic_ai_check.button_pressed if _realistic_ai_check != null else GameState.realistic_ai
	GameState.reset_for_new_game(opponents, amount, realistic)
	Market.reset()
	GameState.current_save_slot = SaveManager.get_available_slot()
	get_tree().change_scene_to_file(GAME_SCENE)

func show_load() -> void:
	var page = _make_page()
	_make_title(page, tr("m_load"), 40)
	_add_spacer(page, 10)

	for slot in range(1, SaveManager.MAX_SLOTS + 1):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		page.add_child(row)

		var info: Dictionary = SaveManager.get_save_info(slot)
		var lbl = Label.new()
		if info.is_empty():
			lbl.text = tr("m_slot_empty") % slot
			lbl.add_theme_color_override("font_color", Color.GRAY)
		else:
			lbl.text = tr("m_slot_info") % [
				slot, int(info["turn"]), int(info["money"]), int(info["ai_count"])
			]
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.custom_minimum_size = Vector2(420, 0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		if not info.is_empty() and bool(info.get("realistic_ai", false)):
			row.add_child(_make_mode_badge())

		var load_btn = Button.new()
		load_btn.text = tr("m_load_btn")
		load_btn.custom_minimum_size = Vector2(160, 48)
		load_btn.add_theme_font_size_override("font_size", 18)
		load_btn.disabled = info.is_empty()
		load_btn.pressed.connect(_load_game.bind(slot))
		row.add_child(load_btn)

		if SaveManager.has_save_file(slot):
			var del_btn = Button.new()
			del_btn.text = tr("m_delete_btn")
			del_btn.custom_minimum_size = Vector2(140, 48)
			del_btn.add_theme_font_size_override("font_size", 18)
			del_btn.pressed.connect(_on_delete_slot_pressed.bind(slot))
			row.add_child(del_btn)

	_add_spacer(page, 20)
	_make_button(page, tr("m_back"), show_main_menu, 260, 54, 20)

func _on_delete_slot_pressed(slot: int) -> void:
	_pending_delete_slot = slot
	delete_confirm.dialog_text = tr("m_del_confirm") % slot
	delete_confirm.popup_centered()

func _on_delete_confirmed() -> void:
	var slot: int = _pending_delete_slot
	_pending_delete_slot = -1
	if slot < 1:
		return
	if SaveManager.delete_save(slot):
		show_load()

func _load_game(slot: int) -> void:
	if SaveManager.load_game(slot):
		get_tree().change_scene_to_file(GAME_SCENE)

func show_settings() -> void:
	var page = _make_page()
	_make_title(page, tr("m_settings"), 40)
	_add_spacer(page, 10)

	var lang_row = HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 16)
	lang_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.custom_minimum_size = Vector2(0, 44)
	page.add_child(lang_row)

	var lang_lbl = Label.new()
	lang_lbl.text = tr("m_language")
	lang_lbl.add_theme_font_size_override("font_size", 20)
	lang_lbl.custom_minimum_size = Vector2(140, 44)
	lang_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lang_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lang_row.add_child(lang_lbl)

	_lang_option = OptionButton.new()
	_lang_option.add_theme_font_size_override("font_size", 16)
	_lang_option.custom_minimum_size = Vector2(130, 44)
	_lang_option.add_item("Русский")
	_lang_option.add_item("English")
	_lang_option.select(0 if Settings.language == "ru" else 1)
	_lang_option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lang_option.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lang_row.add_child(_lang_option)

	var music_row = HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 16)
	music_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	music_row.alignment = BoxContainer.ALIGNMENT_CENTER
	music_row.custom_minimum_size = Vector2(0, 44)
	page.add_child(music_row)

	var music_lbl = Label.new()
	music_lbl.text = tr("m_music")
	music_lbl.add_theme_font_size_override("font_size", 20)
	music_lbl.custom_minimum_size = Vector2(140, 44)
	music_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	music_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_row.add_child(music_lbl)

	_music_check = CheckBox.new()
	_music_check.add_theme_font_size_override("font_size", 16)
	_music_check.text = ""
	_music_check.button_pressed = Settings.music_enabled
	_music_check.custom_minimum_size = Vector2(130, 44)
	_music_check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_music_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	music_row.add_child(_music_check)

	_add_spacer(page, 20)
	_make_button(page, tr("m_apply"), _apply_settings, 260, 54, 20)
	_make_button(page, tr("m_back"), show_main_menu, 260, 54, 20)

func _apply_settings() -> void:
	Settings.language = "ru" if _lang_option.selected == 0 else "en"
	Settings.music_enabled = _music_check.button_pressed
	Settings.save_settings()
	Settings.apply()
	show_main_menu()

func _on_exit() -> void:
	get_tree().quit()

func _on_donate() -> void:
	var url: String = GameState.ITCH_PROJECT_URL.strip_edges()
	if url.is_empty():
		donate_dialog.dialog_text = tr("m_donate_not_configured")
		donate_dialog.popup_centered()
		return
	var err: int = OS.shell_open(url)
	if err != OK:
		donate_dialog.dialog_text = tr("m_donate_failed") % url
		donate_dialog.popup_centered()
