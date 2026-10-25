extends Control

signal back_requested

const ACCENT := Color(0.85, 0.68, 0.3)
const CARD_H: int = 76

var money_lbl: Label
var list_box: VBoxContainer
var preview_art: PropertyArt
var name_lbl: Label
var owned_lbl: Label
var price_lbl: Label
var stat_lbl: Label
var buy_btn: Button
var buy_confirm: ConfirmationDialog
var info_dialog: AcceptDialog
var _pending_buy: int = -1
var _selected: int = -1

func _ready() -> void:
	_build_ui()
	_refresh()
	GameState.money_changed.connect(_refresh)
	GameState.property_changed.connect(_refresh)

func refresh() -> void:
	_refresh()

func _build_ui() -> void:
	UIBackground.add(self, "properties")

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
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	board.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 18)
	vbox.add_child(info_row)

	var back_btn = Button.new()
	back_btn.text = tr("p_back")
	back_btn.custom_minimum_size = Vector2(140, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_on_back)
	info_row.add_child(back_btn)

	var title = Label.new()
	title.text = tr("p_title")
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

	vbox.add_child(HSeparator.new())

	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	var preview_col = VBoxContainer.new()
	preview_col.add_theme_constant_override("separation", 8)
	preview_col.custom_minimum_size = Vector2(500, 0)
	preview_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview_col)

	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.05, 0.08, 0.13, 0.9)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0.5, 0.41, 0.22)
	frame_style.corner_radius_top_left = 8
	frame_style.corner_radius_top_right = 8
	frame_style.corner_radius_bottom_right = 8
	frame_style.corner_radius_bottom_left = 8
	frame_style.content_margin_left = 8
	frame_style.content_margin_top = 8
	frame_style.content_margin_right = 8
	frame_style.content_margin_bottom = 8

	var preview_frame = PanelContainer.new()
	preview_frame.add_theme_stylebox_override("panel", frame_style)
	preview_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_col.add_child(preview_frame)

	preview_art = PropertyArt.new()
	preview_art.custom_minimum_size = Vector2(380, 380)
	preview_frame.add_child(preview_art)

	name_lbl = Label.new()
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_col.add_child(name_lbl)

	owned_lbl = Label.new()
	owned_lbl.add_theme_font_size_override("font_size", 15)
	owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5))
	preview_col.add_child(owned_lbl)

	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 24)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_col.add_child(stats)

	price_lbl = Label.new()
	price_lbl.add_theme_font_size_override("font_size", 26)
	price_lbl.add_theme_color_override("font_color", ACCENT)
	price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_child(price_lbl)

	stat_lbl = Label.new()
	stat_lbl.add_theme_font_size_override("font_size", 16)
	stat_lbl.add_theme_color_override("font_color", Color(0.7, 0.76, 0.86))
	stat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_child(stat_lbl)

	buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(360, 54)
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_btn.add_theme_font_size_override("font_size", 20)
	_style_accent_button(buy_btn)
	buy_btn.pressed.connect(_on_buy_selected)
	preview_col.add_child(buy_btn)

	var list_col = VBoxContainer.new()
	list_col.add_theme_constant_override("separation", 8)
	list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(list_col)

	var list_header = Label.new()
	list_header.text = tr("p_all")
	list_header.add_theme_font_size_override("font_size", 20)
	list_header.add_theme_color_override("font_color", Color(0.75, 0.82, 0.94))
	list_col.add_child(list_header)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scroll(scroll)
	list_col.add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)

	buy_confirm = ConfirmationDialog.new()
	buy_confirm.title = tr("p_buy_title")
	buy_confirm.confirmed.connect(_on_buy_confirmed)
	add_child(buy_confirm)
	_style_dialog(buy_confirm)

	info_dialog = AcceptDialog.new()
	info_dialog.title = tr("p_buy_title")
	add_child(info_dialog)
	_style_dialog(info_dialog)

func _style_accent_button(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = ACCENT
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", normal)
	var hover = normal.duplicate()
	hover.bg_color = Color(0.93, 0.77, 0.4)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.74, 0.58, 0.24)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.3, 0.33, 0.4)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.02))
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.04, 0.01))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.04, 0.01))
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.63, 0.7))

func _style_scroll(scroll: ScrollContainer) -> void:
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(14, 0)
	var track = StyleBoxFlat.new()
	track.bg_color = Color(0.06, 0.09, 0.14, 0.85)
	track.corner_radius_top_left = 7
	track.corner_radius_top_right = 7
	track.corner_radius_bottom_right = 7
	track.corner_radius_bottom_left = 7
	bar.add_theme_stylebox_override("scroll", track)
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = Color(0.55, 0.6, 0.7, 0.95)
	grabber.corner_radius_top_left = 7
	grabber.corner_radius_top_right = 7
	grabber.corner_radius_bottom_right = 7
	grabber.corner_radius_bottom_left = 7
	bar.add_theme_stylebox_override("grabber", grabber)
	var grabber_hl = grabber.duplicate()
	grabber_hl.bg_color = ACCENT
	bar.add_theme_stylebox_override("grabber_highlight", grabber_hl)
	bar.add_theme_stylebox_override("grabber_pressed", grabber_hl)

func _style_dialog(dialog: AcceptDialog) -> void:
	dialog.dialog_hide_on_ok = true
	dialog.min_size = Vector2i(460, 0)
	var lbl: Label = dialog.get_label()
	if lbl != null:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.custom_minimum_size = Vector2(420, 60)

func _refresh() -> void:
	if money_lbl == null:
		return
	if not is_visible_in_tree():
		return
	money_lbl.text = tr("p_money") % int(GameState.money)
	var properties: Array = PropertyData.load_properties()
	if properties.is_empty():
		return
	if _selected < 0:
		_selected = GameState.owned_property if GameState.own_property() else 0
	_selected = clampi(_selected, 0, properties.size() - 1)
	_rebuild_list(properties)
	_show_preview(properties[_selected])

func _rebuild_list(properties: Array) -> void:
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()
	for i in properties.size():
		list_box.add_child(_make_card(i, properties[i]))

func _make_card(index: int, prop: Dictionary) -> Button:
	var card = Button.new()
	card.custom_minimum_size = Vector2(0, CARD_H)
	var sel: bool = index == _selected
	card.add_theme_stylebox_override("normal", _card_style(Color(0.1, 0.14, 0.21, 0.92), ACCENT if sel else Color(0.24, 0.31, 0.44), 2 if sel else 1, sel))
	card.add_theme_stylebox_override("hover", _card_style(Color(0.15, 0.2, 0.29, 0.96), ACCENT, 1, sel))
	card.add_theme_stylebox_override("pressed", _card_style(Color(0.13, 0.17, 0.25, 0.98), ACCENT, 2, true))
	card.add_theme_stylebox_override("focus", _card_style(Color(0, 0, 0, 0), ACCENT, 1, sel))
	card.pressed.connect(_on_card_pressed.bind(index))

	var inner = HBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 10
	inner.offset_top = 6
	inner.offset_right = -19
	inner.offset_bottom = -6
	inner.add_theme_constant_override("separation", 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inner)

	var art = PropertyArt.new()
	art.custom_minimum_size = Vector2(64, 64)
	art.set_property(PropertyData.get_property_color(prop), str(prop.get("kind", "house")), str(prop.get("image", "")))
	inner.add_child(art)

	var text_col = VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 2)
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(text_col)

	var name_lbl_card = Label.new()
	name_lbl_card.text = tr("p_name_%s" % prop["id"])
	name_lbl_card.add_theme_font_size_override("font_size", 19)
	text_col.add_child(name_lbl_card)

	var sub_lbl = Label.new()
	sub_lbl.text = tr("p_prestige") % int(prop["prestige"])
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.66, 0.76))
	text_col.add_child(sub_lbl)

	var value_lbl = Label.new()
	value_lbl.add_theme_font_size_override("font_size", 19)
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if index == GameState.owned_property:
		value_lbl.text = tr("p_owned_btn")
		value_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5))
	else:
		value_lbl.text = "$%d" % int(prop["price"])
		value_lbl.add_theme_color_override("font_color", ACCENT)
	inner.add_child(value_lbl)

	return card

func _card_style(bg: Color, border: Color, width: int, selected: bool) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = width
	s.border_width_top = width
	s.border_width_right = width
	s.border_width_bottom = width
	s.border_color = border
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left = 6
	if selected:
		s.shadow_color = Color(0.85, 0.68, 0.3, 0.25)
		s.shadow_size = 4
	return s

func _show_preview(prop: Dictionary) -> void:
	var index: int = _selected
	preview_art.set_property(PropertyData.get_property_color(prop), str(prop.get("kind", "house")), str(prop.get("image", "")))
	name_lbl.text = tr("p_name_%s" % prop["id"])
	price_lbl.text = "$%d" % int(prop["price"])
	stat_lbl.text = tr("p_prestige") % int(prop["prestige"])
	var owned: bool = index == GameState.owned_property
	owned_lbl.text = tr("p_owned_btn") if owned else (tr("p_none") if not GameState.own_property() else "")
	if owned:
		buy_btn.text = tr("p_owned_btn")
		buy_btn.disabled = true
	else:
		buy_btn.text = tr("p_buy_btn") % int(prop["price"])
		buy_btn.disabled = GameState.money < float(prop["price"])

func _on_card_pressed(index: int) -> void:
	_selected = index
	var properties: Array = PropertyData.load_properties()
	_rebuild_list(properties)
	_show_preview(properties[index])

func _on_buy_selected() -> void:
	if _selected < 0:
		return
	var prop: Dictionary = PropertyData.get_property(_selected)
	if prop.is_empty():
		return
	_pending_buy = _selected
	var refund: float = 0.0
	if GameState.own_property():
		var old: Dictionary = PropertyData.get_property(GameState.owned_property)
		if not old.is_empty():
			refund = float(old["price"]) * 0.5
	var text: String = tr("p_buy_confirm") % [
		tr("p_name_%s" % prop["id"]), int(prop["price"]), int(prop["prestige"])
	]
	if refund > 0.0:
		text += "\n" + tr("p_trade_in") % int(refund)
	buy_confirm.dialog_text = text
	buy_confirm.popup_centered()

func _on_buy_confirmed() -> void:
	buy_confirm.hide()
	var index: int = _pending_buy
	_pending_buy = -1
	if index < 0:
		return
	if not GameState.buy_property(index):
		info_dialog.dialog_text = tr("p_buy_failed")
		info_dialog.popup_centered()
		return
	_refresh()
	back_requested.emit()

func _on_back() -> void:
	back_requested.emit()
