# 플레이어 이동 (CharacterBody2D). FR-01, FR-08 (무게와 무관한 속도), US-07, US-08
class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 180.0

const FEET_OFFSET := Vector2(0, 10)


func _ready() -> void:
	_ensure_actions()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	add_child(shape)
	var body := ColorRect.new()
	body.color = Color(0.35, 0.7, 1.0)
	body.size = Vector2(20, 20)
	body.position = Vector2(-10, -10)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)


## 선반 패널이 열려 있는 동안 true: 이동을 멈춘다
var locked := false


func _physics_process(_delta: float) -> void:
	if locked:
		velocity = Vector2.ZERO
		return
	# 키보드 방향키로만 이동한다 (마우스 클릭 이동 없음)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# BR-U1-09: 손에 든 아이템 무게와 무관하게 속도는 일정
	velocity = dir * current_speed()
	move_and_slide()


## 무게와 무관 (BR-U1-09). 이동 속도 증강만 반영
func current_speed() -> float:
	return WeightRules.carry_speed(move_speed * (1.0 + EconomyManager.augment_bonus("speed")), 0)


func feet_position() -> Vector2:
	return global_position + FEET_OFFSET


## 방향키 (이동), 상호작용 키 (E) 를 실행 시 등록 (project.godot 입력 맵 대신)
static func _ensure_actions() -> void:
	var binds := {
		"move_left": [KEY_LEFT],
		"move_right": [KEY_RIGHT],
		"move_up": [KEY_UP],
		"move_down": [KEY_DOWN],
		"interact": [KEY_X],
		"open_shelf": [KEY_E],
		"shelf_up": [KEY_UP],
		"shelf_down": [KEY_DOWN],
		"shelf_left": [KEY_LEFT],
		"shelf_right": [KEY_RIGHT],
		"drop_item": [KEY_Z],
		"buy_menu": [KEY_C],
		"debug_menu": [KEY_F1],
		"pause": [KEY_P, KEY_ESCAPE],
		"slot_1": [KEY_1, KEY_KP_1],
		"slot_2": [KEY_2, KEY_KP_2],
		"slot_3": [KEY_3, KEY_KP_3],
		"slot_4": [KEY_4, KEY_KP_4],
		"slot_5": [KEY_5, KEY_KP_5],
		"slot_6": [KEY_6, KEY_KP_6],
		"slot_add": [KEY_EQUAL, KEY_KP_ADD],
	}
	for action in binds:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
