# 던전 진행 바 (방치형 게임 방식): 전투마다 한 칸씩 채워지는 칸 막대 + 지금 상태 글자.
# 칸 색: 끝난 전투 = 금색, 진행 중인 전투 = 현재 단계 색 (채워지는 정도로 남은 시간을 보여 준다), 남은 전투 = 회색
class_name DungeonProgressBar
extends Control

const TRACK := Color(0.12, 0.1, 0.16, 0.9)
const DONE := Color(0.95, 0.78, 0.3)
const TODO := Color(0.3, 0.28, 0.36)
const GAP := 6.0
const BAR_TOP := 36.0
const BAR_H := 22.0

var _title: Label
var _phase: Label
var _info: Label
var _total := 0
var _done := 0
var _active := -1
var _fill := 0.0
var _phase_color := Color(1, 0.5, 0.3)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _make_label(Vector2(14, 6), HORIZONTAL_ALIGNMENT_LEFT, 20)
	_phase = _make_label(Vector2(0, 6), HORIZONTAL_ALIGNMENT_CENTER, 20)
	_info = _make_label(Vector2(0, 8), HORIZONTAL_ALIGNMENT_RIGHT, 16)
	resized.connect(_layout)
	_layout()


func _make_label(pos: Vector2, align: HorizontalAlignment, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _layout() -> void:
	_phase.size = Vector2(size.x, 26)
	_phase.position = Vector2(0, 6)
	_info.size = Vector2(size.x - 14, 22)
	_info.position = Vector2(0, 8)


## view: title (왼쪽 글자), phase (가운데 글자), info (오른쪽 글자), total (전투 수), done (끝난 전투 수),
## active (진행 중인 칸 번호, -1 이면 없음), fill (진행 중인 칸이 찬 비율 0~1), color (진행 중인 칸 색)
func set_view(title: String, phase: String, info: String, total: int, done: int, active: int, fill: float, color: Color) -> void:
	_title.text = title
	_phase.text = phase
	_phase.add_theme_color_override("font_color", color)
	_info.text = info
	_total = total
	_done = done
	_active = active
	_fill = clampf(fill, 0.0, 1.0)
	_phase_color = color
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), TRACK)
	if _total <= 0:
		return
	var x0 := 14.0
	var width := size.x - 28.0
	var seg := (width - GAP * (_total - 1)) / _total
	for i in _total:
		var rect := Rect2(x0 + i * (seg + GAP), BAR_TOP, seg, BAR_H)
		draw_rect(rect, DONE if i < _done else TODO)
		if i == _active:
			draw_rect(Rect2(rect.position, Vector2(rect.size.x * _fill, rect.size.y)), _phase_color)
