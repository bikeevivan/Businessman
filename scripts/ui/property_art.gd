class_name PropertyArt
extends Control

var body_color: Color = Color(0.8, 0.8, 0.85)
var kind: String = "house"
var image_path: String = ""
var _texture: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(280, 180)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resized.connect(queue_redraw)
	queue_redraw()

func set_property(color: Color, prop_kind: String, img_path: String = "") -> void:
	body_color = color
	kind = prop_kind
	image_path = img_path
	_texture = null
	if image_path != "":
		var tex = load(image_path)
		if tex is Texture2D:
			_texture = tex
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		w = custom_minimum_size.x
		h = custom_minimum_size.y
	if _texture != null:
		var tex_size: Vector2 = _texture.get_size()
		if tex_size.x <= 0.0 or tex_size.y <= 0.0:
			return
		var sc: float = minf(w / tex_size.x, h / tex_size.y)
		var draw_size: Vector2 = tex_size * sc
		var offset: Vector2 = Vector2((w - draw_size.x) * 0.5, (h - draw_size.y) * 0.5)
		draw_texture_rect(_texture, Rect2(offset, draw_size), false)
		return

	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.08, 0.1, 0.14, 0.25))

	var bw_ratio: float = 0.55
	var bh_ratio: float = 0.34
	var pitched: bool = true
	var cols: int = 3
	var rows: int = 2
	var chimney: bool = false
	var water: bool = false
	var top_band: bool = false

	match kind:
		"shed":
			bw_ratio = 0.42
			bh_ratio = 0.22
			cols = 1
			rows = 1
		"house":
			bw_ratio = 0.55
			bh_ratio = 0.34
			cols = 3
			rows = 2
			chimney = true
		"flat":
			bw_ratio = 0.4
			bh_ratio = 0.62
			pitched = false
			cols = 3
			rows = 5
		"cottage":
			bw_ratio = 0.64
			bh_ratio = 0.36
			cols = 4
			rows = 2
			chimney = true
		"penthouse":
			bw_ratio = 0.44
			bh_ratio = 0.68
			pitched = false
			cols = 3
			rows = 6
			top_band = true
		"mansion":
			bw_ratio = 0.72
			bh_ratio = 0.42
			cols = 6
			rows = 2
		"palace":
			bw_ratio = 0.82
			bh_ratio = 0.46
			cols = 7
			rows = 2

	var pad: float = min(w, h) * 0.08
	var cw: float = w - pad * 2.0
	var ch: float = h - pad * 2.0
	var ground_y: float = pad + ch * (0.72 if water else 0.9)
	var body_w: float = cw * bw_ratio
	var body_h: float = ch * bh_ratio
	var bx: float = pad + (cw - body_w) * 0.5
	var by: float = ground_y - body_h

	if water:
		draw_rect(Rect2(pad, ground_y, cw, (pad + ch) - ground_y), Color(0.18, 0.42, 0.62))
		for i in 4:
			var wy: float = ground_y + 6.0 + i * 9.0
			if wy < pad + ch:
				draw_line(Vector2(pad + cw * 0.1, wy), Vector2(pad + cw * 0.9, wy), Color(0.35, 0.65, 0.85, 0.5), 2.0)

	var body = StyleBoxFlat.new()
	body.bg_color = body_color
	body.set_corner_radius_all(int(min(body_w, body_h) * 0.05))
	draw_style_box(body, Rect2(bx, by, body_w, body_h))

	if pitched:
		var roof_h: float = min(body_h * 0.62, body_w * 0.42)
		var roof_col: Color = body_color.darkened(0.32)
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx - body_w * 0.06, by),
			Vector2(bx + body_w * 0.5, by - roof_h),
			Vector2(bx + body_w * 1.06, by),
		]), roof_col)
		if chimney:
			var chx: float = bx + body_w * 0.7
			var chw: float = body_w * 0.09
			draw_rect(Rect2(chx, by - roof_h * 0.75, chw, roof_h * 0.7), roof_col.darkened(0.15))
	else:
		draw_rect(Rect2(bx - body_w * 0.03, by - body_h * 0.06, body_w * 1.06, body_h * 0.07), body_color.darkened(0.28))
		if top_band:
			draw_rect(Rect2(bx, by, body_w, body_h * 0.08), body_color.lightened(0.22))

	if kind == "mansion":
		var col_w: float = body_w * 0.045
		var col_gap: float = body_w / 5.0
		for i in 4:
			var cx2: float = bx + col_gap * (i + 1) - col_w * 0.5
			draw_rect(Rect2(cx2, by + body_h * 0.16, col_w, body_h * 0.7), body_color.lightened(0.18))

	var win_col: Color = Color(1.0, 0.86, 0.5)
	var win_w: float = body_w * 0.1
	var win_h: float = body_h * 0.13
	var gap_x: float = (body_w - cols * win_w) / float(cols + 1)
	var gap_y: float = (body_h * 0.68 - rows * win_h) / float(rows + 1)
	for r in rows:
		for c in cols:
			var wx: float = bx + gap_x + c * (win_w + gap_x)
			var wy: float = by + body_h * 0.12 + gap_y + r * (win_h + gap_y)
			draw_rect(Rect2(wx, wy, win_w, win_h), win_col)

	var door_w: float = body_w * 0.13
	var door_h: float = body_h * 0.22
	draw_rect(Rect2(bx + (body_w - door_w) * 0.5, by + body_h - door_h, door_w, door_h), body_color.darkened(0.45))

	draw_rect(Rect2(pad, ground_y, cw, maxf(2.0, ch * 0.02)), Color(0.1, 0.12, 0.16, 0.7))
