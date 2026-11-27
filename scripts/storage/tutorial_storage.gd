# 튜토리얼 (7단계): 메인 메뉴의 "튜토리얼" 에서만 실행. 끝나면 완료 표시 후 메인 메뉴로 돌아간다
extends StorageRoom

const TUTORIAL_IDS := ["potion_hp", "scroll", "sword", "dagger", "helmet"]
const ITEM_SPOT_Y := 215.0
const MENU_SCENE := "res://scenes/main_menu.tscn"

## 실행 중에는 true. 테스트에서는 false 로 두어 씬 전환을 막는다
var auto_return := true
var tutorial_items: Array[ItemInstance] = []
var completed := false
var take_out_count := 0

var _ui: DungeonUi
var _guide: CanvasLayer
var _guide_label: RichTextLabel
var _guide_button: Button
var _steps: Array = []
var _step := 0
var _guide_running := false
var _quest_kind := ""
var _sell_ok := false
var _floor_item: ItemInstance = null


func _initial_shelf_count() -> int:
	return 1


func _ready() -> void:
	super()
	EconomyManager.reset_run()
	ItemManager.reset_run()
	DungeonManager.reset_run()
	SaveService.delete_save()
	EconomyManager.choices_enabled = false  # 1~2단계 동안 증강은 나오지 않는다
	DungeonManager.start_dungeon(1)
	_ui = find_child("DungeonUi", true, false) as DungeonUi
	_ui.tutorial_mode = true
	_ui.tutorial_shop_done.connect(_on_tutorial_shop_done)
	_ui.tutorial_sell_result.connect(_on_tutorial_sell)
	_build_guide()
	_create_tutorial_items()
	_start_guide()


func _create_tutorial_items() -> void:
	tutorial_items.clear()
	for i in TUTORIAL_IDS.size():
		var pos := Vector2(520 + i * 60, ITEM_SPOT_Y)
		tutorial_items.append(add_item(load("res://data/items/%s.tres" % TUTORIAL_IDS[i]), pos))


## 튜토리얼 상점의 판매 퀘스트: 검 1개 (DungeonUi 가 상점을 열 때 사용)
func sell_override() -> Dictionary:
	return {"fixed_lines": [{"item_kind": "sword", "required": 1}], "time_limit": 120.0, "exp": 40, "gold": 0}


func on_take_out_done() -> void:
	take_out_count += 1


# ---------- 단계 ----------

func _build_guide() -> void:
	_guide = CanvasLayer.new()
	_guide.layer = 6
	add_child(_guide)
	var panel := PanelContainer.new()
	panel.position = Vector2(290, 585)
	panel.custom_minimum_size = Vector2(700, 0)
	_guide.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_guide_label = RichTextLabel.new()
	_guide_label.bbcode_enabled = true
	_guide_label.fit_content = true
	_guide_label.custom_minimum_size = Vector2(680, 0)
	box.add_child(_guide_label)
	_guide_button = Button.new()
	_guide_button.text = "다음"
	_guide_button.visible = false
	_guide_button.pressed.connect(_on_guide_next)
	box.add_child(_guide_button)
	_guide.visible = false


func _start_guide() -> void:
	_steps = _build_steps()
	_step = 0
	_guide_running = true
	_guide.visible = true
	_show_step()


func _build_steps() -> Array:
	var s := []
	# 1. 아이템 적재
	s.append({"text": "[b]1. 아이템 적재[/b] 아이템에게 다가가세요. [b]WASD[/b] 로 움직이거나 빈 바닥을 클릭하세요.", "check": func() -> bool: return _near_any_item()})
	s.append({"text": "[b]1. 아이템 적재[/b] [b]X[/b] 키로 아이템을 주우세요.", "check": func() -> bool: return not ItemManager.carried_ids.is_empty()})
	s.append({"text": "[b]1. 아이템 적재[/b] 선반 [b]앞[/b] 으로 가세요.", "check": func() -> bool: return _near_shelf0()})
	s.append({"text": "[b]1. 아이템 적재[/b] [b]X[/b] 키로 선반을 여세요.", "check": func() -> bool: return _ui != null and room_panel_visible()})
	s.append({"text": "[b]1. 아이템 적재[/b] 선반이 열린 상태에서 [b]1[/b] 키를 누르면 들고 있는 아이템이 1번 칸에 들어갑니다.", "check": func() -> bool: return _stored_count() >= 1})
	s.append({"text": "[b]1. 아이템 적재[/b] 남은 아이템도 같은 방법으로 넣으세요 (집고 → 선반 앞 → X → 1·2·3 키).", "check": func() -> bool: return _all_stored()})
	# 2. 긴급 퀘스트 (아이템 꺼내서 전달)
	s.append({"text": "[b]2. 긴급 퀘스트[/b] 왼쪽 아래에 [b]긴급 요청[/b] 이 떴습니다. 요청 품목을 선반에서 꺼내야 합니다. 선반을 열고 손을 비운 채 [b]1[/b] 키를 누르세요 (칸의 맨 위 아이템이 나옵니다).", "enter": func() -> void: _spawn_quest_from_top(), "check": func() -> bool: return take_out_count >= 1 and not ItemManager.carried_ids.is_empty()})
	s.append({"text": "[b]2. 긴급 퀘스트[/b] 들고 [b]전달 선반[/b] (오른쪽 아래 파란 칸) 앞에서 [b]Z[/b] 를 누르세요.", "check": func() -> bool: return _quest_done()})
	# 3. 증강 선택
	s.append({"text": "[b]3. 증강 선택[/b] 레벨이 올랐습니다! 나온 증강 중 하나를 고르세요.", "enter": func() -> void: _level_up(), "check": func() -> bool: return not EconomyManager.augments.is_empty() and EconomyManager.pending_choices == 0})
	# 4. 아이템 드랍
	s.append({"text": "[b]4. 아이템 드랍[/b] 바닥의 아이템에 다가가 [b]X[/b] 로 줍고, 선반에서 떨어진 곳에서 [b]Z[/b] 로 내려놓으세요.", "enter": func() -> void: _spawn_floor_item(), "check": func() -> bool: return _dropped_on_floor()})
	# 5. 수면
	s.append({"text": "[b]5. 수면[/b] 용사가 잠듭니다 (튜토리얼은 6초). 수면 중에도 [b]C[/b] 로 선반과 칸을 강화할 수 있습니다.", "enter": func() -> void: _start_sleep(), "check": func() -> bool: return _ui != null and _ui._shop_active})
	# 6. 상점 퀘스트
	s.append({"text": "[b]6. 상점 퀘스트[/b] 상점이 열렸습니다. 요청 품목 [b]검[/b] 을 선반에서 꺼내 [b]전달 선반[/b] 에 [b]Z[/b] 로 넣으세요. 판매되면 골드와 EXP 를 얻습니다.", "check": func() -> bool: return _sell_ok})
	# 7. 선반 구매와 확장
	s.append({"text": "[b]7. 선반 구매[/b] 튜토리얼 지원금 500골드를 드렸습니다. [b]C[/b] 키로 메뉴를 열고 위 구역 [b]새 선반 사기[/b] 를 누르세요.", "enter": func() -> void: EconomyManager.add_gold(500), "check": func() -> bool: return room_shelves() >= 2})
	s.append({"text": "[b]7. 칸 확장[/b] 아래 구역 [b]칸 확장[/b] 에서 [b]선반 1 · 칸 추가[/b] 를 눌러 칸을 늘리세요. 선반마다 따로 늘립니다.", "check": func() -> bool: return shelves[0].state.slot_count > 3})
	s.append({"info": true, "text": "[b]튜토리얼 완료![/b] 이제 메인 메뉴에서 [b]새 게임[/b] 을 눌러 시작하세요. 시작 버튼을 누르면 메인 메뉴로 돌아갑니다."})
	return s


func room_panel_visible() -> bool:
	return shelf_panel.visible


func room_shelves() -> int:
	return shelves.size()


func _process(delta: float) -> void:
	super(delta)
	if not _guide_running or _step >= _steps.size():
		return
	var step: Dictionary = _steps[_step]
	if step.has("check") and step["check"].call():
		_step += 1
		_show_step()


func _show_step() -> void:
	if _step >= _steps.size():
		_finish_tutorial()
		return
	var step: Dictionary = _steps[_step]
	if step.has("enter") and not step.get("entered", false):
		step["entered"] = true
		step["enter"].call()
	_guide_label.text = step["text"]
	_guide_button.visible = step.get("info", false)
	_guide_button.text = "시작" if _step == _steps.size() - 1 else "다음"


func _on_guide_next() -> void:
	_step += 1
	_show_step()


# ----- 단계별 동작 -----

func _spawn_quest_from_top() -> void:
	var ids: Array = shelves[0].state.slot_items[0]
	var top: ItemInstance = ItemManager.items[ids.back()]
	_quest_kind = top.data.item_id
	DungeonManager.spawn_quest_now({"quantity": 1, "line_max": 1, "time_limit": 120.0, "gold": 10, "exp": 10, "fixed_lines": [{"item_kind": _quest_kind, "required": 1}]})


func _quest_done() -> bool:
	return DungeonManager.quests.quest != null and DungeonManager.quests.quest.status == Quest.Status.SUCCESS


func _level_up() -> void:
	EconomyManager.choices_enabled = true
	EconomyManager.add_exp(EconomyManager.exp_to_next() - EconomyManager.exp_points)


func _spawn_floor_item() -> void:
	_floor_item = add_item(load("res://data/items/axe.tres"), Vector2(420, 470))


var _floor_carried := false


## 바닥 아이템을 들었다가 (Z) 내려놓았는지
func _dropped_on_floor() -> bool:
	if _floor_item == null:
		return false
	if ItemManager.carried_ids.has(_floor_item.instance_id):
		_floor_carried = true
	return _floor_carried and _floor_item.state == ItemInstance.State.INCOMING and ItemManager.carried_ids.is_empty()


func _start_sleep() -> void:
	DungeonManager.flow.begin_sleep()
	DungeonManager.flow.sleep_left = 6.0


func _on_tutorial_sell(r: Dictionary) -> void:
	if r.get("result") == "success":
		_sell_ok = true


func _on_tutorial_shop_done() -> void:
	pass


func _finish_tutorial() -> void:
	_guide_running = false
	completed = true
	SaveService.mark_tutorial_done()
	if auto_return:
		show_message("튜토리얼 완료! 메인 메뉴로 돌아갑니다")
		get_tree().create_timer(2.5).timeout.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))


func _near_any_item() -> bool:
	for it in tutorial_items:
		if it.state == ItemInstance.State.INCOMING and player.position.distance_to(it.world_position) < 60.0:
			return true
	return false


func _near_shelf0() -> bool:
	return StorageService.near_rect(player.position, shelves[0].bounds())


func _stored_count() -> int:
	var n := 0
	for it in tutorial_items:
		if it.state == ItemInstance.State.STORED:
			n += 1
	return n


func _all_stored() -> bool:
	return not tutorial_items.is_empty() and _stored_count() == tutorial_items.size()
