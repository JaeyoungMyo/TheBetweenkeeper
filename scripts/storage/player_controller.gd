# 플레이어 이동 (CharacterBody2D). FR-01, FR-08 (무게와 무관한 속도), US-07, US-08
class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 180.0

const FEET_OFFSET := Vector2(0, 10)
const ARRIVE_DISTANCE := 4.0
const STUCK_SECONDS := 0.25

var move_target := Vector2.INF
var _stuck_time := 0.0


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


func _physics_process(delta: float) -> void:
	if locked:
		velocity = Vector2.ZERO
		stop_moving()
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		stop_moving()
	elif has_target():
		dir = global_position.direction_to(move_target)
	# BR-U1-09: 손에 든 아이템 무게와 무관하게 속도는 일정
	velocity = dir * current_speed()
	var before := global_position
	move_and_slide()
	if has_target():
		_check_arrival(before, delta)


## 마우스 클릭 이동 (키보드 입력이 우선)
func move_to(point: Vector2) -> void:
	move_target = point
	_stuck_time = 0.0


func has_target() -> bool:
	return move_target != Vector2.INF


func stop_moving() -> void:
	move_target = Vector2.INF


func _check_arrival(before: Vector2, delta: float) -> void:
	var step := current_speed() * delta
	if global_position.distance_to(move_target) <= maxf(ARRIVE_DISTANCE, step):
		stop_moving()
		return
	var progress := before.distance_to(move_target) - global_position.distance_to(move_target)
	_stuck_time = _stuck_time + delta if progress < step * 0.1 else 0.0
	if _stuck_time > STUCK_SECONDS:
		stop_moving()


## 무게와 무관 (BR-U1-09). 이동 속도 증강만 반영
func current_speed() -> float:
	return WeightRules.carry_speed(move_speed * (1.0 + EconomyManager.augment_bonus("speed")), 0)


func feet_position() -> Vector2:
	return global_position + FEET_OFFSET


## WASD 와 방향키, 상호작용 키 (E) 를 실행 시 등록 (project.godot 입력 맵 대신)
static func _ensure_actions() -> void:
	var binds := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_X],
		"open_shelf": [KEY_E],
		"shelf_up": [KEY_UP],
		"shelf_down": [KEY_DOWN],
		"shelf_take": [KEY_ENTER, KEY_KP_ENTER],
		"drop_item": [KEY_Z],
		"shop_menu": [KEY_C],
		"debug_menu": [KEY_F1],
		"pause": [KEY_P],
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
