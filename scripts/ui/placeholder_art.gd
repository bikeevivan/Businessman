extends Control
class_name PlaceholderArt

const SKY_TOP := Color(0.07, 0.10, 0.19)
const SKY_BOTTOM := Color(0.24, 0.35, 0.55)
const GROUND := Color(0.06, 0.08, 0.12)
const BUILDING := Color(0.10, 0.13, 0.20)
const BUILDING_EDGE := Color(0.18, 0.24, 0.34)
const WINDOW := Color(1.0, 0.83, 0.42, 0.85)
const MOON := Color(0.95, 0.93, 0.78)
const BUILDINGS := [
	[0.08, 0.28], [0.06, 0.45], [0.09, 0.34], [0.07, 0.55],
	[0.10, 0.40], [0.06, 0.62], [0.08, 0.36], [0.09, 0.50],
	[0.07, 0.30], [0.10, 0.44], [0.08, 0.58], [0.12, 0.38],
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 8.0 or h < 8.0:
		return

	var steps: int = 32
	for i in steps:
		var t: float = float(i) / float(steps)
		var color: Color = SKY_TOP.lerp(SKY_BOTTOM, t)
		draw_rect(Rect2(0.0, h * t, w, h / float(steps) + 1.0), color)

	draw_circle(Vector2(w * 0.78, h * 0.20), minf(w, h) * 0.075, MOON)

	var base_y: float = h * 0.80
	var bx: float = 0.0
	for b in BUILDINGS:
		var bw: float = w * float(b[0]) - w * 0.010
		var bh: float = h * float(b[1])
		var rect := Rect2(bx, base_y - bh, bw, bh)
		draw_rect(rect, BUILDING)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), BUILDING_EDGE)
		_draw_windows(rect)
		bx += w * float(b[0])

	draw_rect(Rect2(0.0, base_y, w, h - base_y), GROUND)
	draw_rect(Rect2(0.0, base_y, w, 2.0), BUILDING_EDGE)

	var font: Font = ThemeDB.fallback_font
	if font != null:
		var font_size: int = int(minf(w, h) * 0.14)
		var text: String = "БИЗНЕСМЕН"
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var pos := Vector2((w - text_size.x) * 0.5, h * 0.14 + text_size.y * 0.5)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 1.0, 0.92))

func _draw_windows(rect: Rect2) -> void:
	var cols: int = int(rect.size.x / 13.0)
	var rows: int = int(rect.size.y / 15.0)
	if cols < 1 or rows < 1:
		return
	var pad: float = 4.0
	var cw: float = (rect.size.x - pad * float(cols + 1)) / float(cols)
	var ch: float = (rect.size.y - pad * float(rows + 1)) / float(rows)
	if cw <= 0.5 or ch <= 0.5:
		return
	var seed: int = int(rect.position.x) * 17 + int(rect.size.y) * 131
	for r in rows:
		for c in cols:
			if _hash(seed + r * 97 + c * 31) % 100 < 50:
				var pos := Vector2(
					rect.position.x + pad + float(c) * (cw + pad),
					rect.position.y + pad + float(r) * (ch + pad)
				)
				draw_rect(Rect2(pos, Vector2(cw, ch)), WINDOW)

func _hash(value: int) -> int:
	var x: int = (value * 1103515245 + 12345) & 0x7fffffff
	return (x >> 8) & 0x7fffffff
