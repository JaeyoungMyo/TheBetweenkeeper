# 튜토리얼 (7단계): 메인 메뉴의 "튜토리얼" 에서만 실행. 끝나면 완료 표시 후 메인 메뉴로 돌아간다
extends StorageRoom

const TUTORIAL_IDS := ["potion_hp", "scroll", "sword", "dagger", "helmet"]
const ITEM_SPOT_Y := 262.0
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
		var pos := Vector2(566 + i * 49, ITEM_SPOT_Y)
		tutorial_items.append(add_item(load("res://data/items/%s.tres" % TUTORIAL_IDS[i]), pos))


## 튜토리얼 상점의 판매 퀘스트: 검 1개 (DungeonUi 가 상점을 열 때 사용)
func sell_override() -> Dictionary:
	return {"quantity": 2, "line_max": 2, "fixed_lines": [{"item_kind": "sword", "required": 1}, {"item_kind": "helmet", "required": 1}], "time_limit": 120.0, "exp": 40, "gold": 0}


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
	# 말풍선: 둥근 밝은 상자 + 캐릭터 쪽을 가리키는 꼬리
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color(1.0, 0.98, 0.93, 0.96)
	bubble.border_color = Color(0.45, 0.32, 0.55)
	bubble.set_border_width_all(3)
	bubble.set_corner_radius_all(14)
	bubble.content_margin_left = 16
	bubble.content_margin_right = 16
	bubble.content_margin_top = 10
	bubble.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", bubble)
	# 꼬리는 말풍선 오른쪽 윗부분에 붙어 캐릭터 쪽(오른쪽)을 가리킨다. 말풍선 크기가 바뀌면 따라 옮긴다
	var tail := Polygon2D.new()
	tail.name = "guide-bubble-tail"
	tail.color = Color(0.45, 0.32, 0.55)
	panel.add_child(tail)
	var tail_fill := Polygon2D.new()
	tail_fill.color = Color(1.0, 0.98, 0.93)
	panel.add_child(tail_fill)
	var place_tail := func() -> void:
		var w := panel.size.x
		tail.polygon = PackedVector2Array([Vector2(w, 12), Vector2(w + 20, 20), Vector2(w, 28)])
		tail_fill.polygon = PackedVector2Array([Vector2(w - 2, 15), Vector2(w + 14, 20), Vector2(w - 2, 25)])
	panel.resized.connect(place_tail)
	place_tail.call()
	_guide.add_child(panel)
	# 안내 캐릭터: 대화창 왼쪽에서 설명해 주는 느낌 (화면 밖으로 나가지 않도록 아래쪽에 맞춘다)
	var guide_img := TextureRect.new()
	guide_img.name = "guide-character"
	guide_img.texture = load("res://art/guide/guide_character.png")
	guide_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guide_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	guide_img.position = Vector2(1010, 500)
	guide_img.size = Vector2(220, 221)
	guide_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide.add_child(guide_img)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_guide_label = RichTextLabel.new()
	_guide_label.bbcode_enabled = true
	_guide_label.fit_content = true
	_guide_label.custom_minimum_size = Vector2(680, 0)
	_guide_label.add_theme_color_override("default_color", Color(0.18, 0.13, 0.22))
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
	s.append({"text": "[b]1. 아이템 적재[/b] 반짝이는 아이템 쪽으로 살금살금 다가가 볼까요? [b]WASD[/b] 로 움직이거나 빈 바닥을 클릭하면 돼요~", "check": func() -> bool: return _near_any_item()})
	s.append({"text": "[b]1. 아이템 적재[/b] 좋아요! [b]X[/b] 키를 눌러서 아이템을 주워 볼까요?", "check": func() -> bool: return not ItemManager.carried_ids.is_empty()})
	s.append({"text": "[b]1. 아이템 적재[/b] 잘했어요! 이제 저기 선반 [b]앞[/b] 으로 가 볼까요?", "check": func() -> bool: return _near_shelf0()})
	s.append({"text": "[b]1. 아이템 적재[/b] 선반 앞에 도착했어요~ [b]E[/b] 키를 누르면 선반이 열려요!", "check": func() -> bool: return _ui != null and room_panel_visible()})
	# 1-b. 선반 닫기: 열었다가 E 로 닫아야 이동이 풀린다
	s.append({"text": "[b]1. 아이템 적재[/b] 선반을 닫아 볼까요? 선반 앞에서 [b]E[/b] 로 열었다면, 다시 [b]E[/b] 를 눌러 닫아 주세요. 선반이 열려 있는 동안에는 이동이 잠겨요.", "enter": func() -> void:
		_was_open = false
		shelf_closed_by_key = false, "check": func() -> bool:
		if room_panel_visible():
			_was_open = true
			return false
		return _was_open and shelf_closed_by_key})
	s.append({"text": "[b]1. 아이템 적재[/b] 이제 다시 [b]E[/b] 로 열고, [b]1[/b] 키를 누르면 들고 있는 아이템이 1번 칸에 쏙 들어가요!", "check": func() -> bool: return _stored_count() >= 1})
	s.append({"text": "[b]1. 아이템 적재[/b] 나머지도 같은 방법으로 넣어 봐요~ (집고 → 선반 앞 → E → 1·2·3 키) 손에는 [b]2개[/b] 까지 들 수 있고, 칸이 가득 차면 다른 칸 번호를 눌러 보세요!", "check": func() -> bool: return _all_stored()})
	# 2. 아이템 드랍
	s.append({"text": "[b]2. 아이템 드랍[/b] 바닥에 떨어진 아이템 쪽으로 가서 [b]X[/b] 로 주워 볼까요? 그다음 선반에서 조금 떨어진 곳에서 [b]Z[/b] 를 누르면 내려놓을 수 있어요~", "enter": func() -> void: _spawn_floor_item(), "check": func() -> bool: return _dropped_on_floor()})
	# 3. 긴급 퀘스트 (아이템 꺼내서 전달)
	s.append({"text": "[b]3. 긴급 퀘스트[/b] 큰일이에요! 왼쪽 아래에 [b]긴급 요청 (회복약 1개)[/b] 이 떴어요. 선반을 열고 [b]회복약[/b] 을 ←→ 로 고른 뒤 [b]X[/b] 로 꺼내 주세요 (이름을 클릭해도 돼요)!", "enter": func() -> void: _ensure_on_shelf("potion_hp"); _spawn_potion_quest(), "check": func() -> bool: return _carrying("potion_hp")})
	s.append({"text": "[b]3. 긴급 퀘스트[/b] 회복약을 들고 [b]전달 선반[/b] (오른쪽 아래 파란 칸) 앞에서 [b]Z[/b] 를 눌러 주세요.", "check": func() -> bool: return _quest_done()})
	# 4. 증강 선택
	s.append({"text": "[b]4. 증강 선택[/b] 와아, 레벨이 올랐어요! 나온 증강 중에서 하나를 골라 주세요~ (고르는 동안 게임이 잠시 멈춰요)", "enter": func() -> void: _level_up(), "check": func() -> bool: return not EconomyManager.augments.is_empty() and EconomyManager.pending_choices == 0})
	# 5. 수면
	s.append({"text": "[b]5. 수면[/b] 용사님이 잠이 들었어요. 쿨쿨~ (튜토리얼은 6초예요). 수면 중에도 [b]C[/b] 로 새 선반을 살 수 있어요.", "enter": func() -> void: _start_sleep(), "check": func() -> bool: return _ui != null and _ui._shop_active})
	# 6. 상점 퀘스트
	s.append({"text": "[b]6. 상점 퀘스트[/b] 상점이 열렸어요! 요청 품목 [b]검[/b] 과 [b]투구[/b] 를 선반에서 꺼내서 [b]전달 선반[/b] 에 [b]Z[/b] 로 넣어 주세요. 팔리면 골드와 EXP 를 받을 수 있어요~", "enter": func() -> void: _ensure_on_shelf("sword"); _ensure_on_shelf("helmet"), "check": func() -> bool: return _sell_ok})
	# 7. 선반 구매와 확장
	s.append({"text": "[b]7. 선반 구매[/b] 튜토리얼 지원금 500골드를 드릴게요! [b]C[/b] 키 (또는 오른쪽 위 [b]상점[/b] 버튼) 로 상점을 열고 [b]새 선반 사기[/b] 를 눌러 보세요.", "enter": func() -> void: EconomyManager.add_gold(500), "check": func() -> bool: return room_shelves() >= 2})
	s.append({"text": "[b]7. 가방 구매[/b] 상점에서 [b]가방 확장[/b] 도 살 수 있어요. 손에 드는 개수가 늘어나요! 골드가 남았으니 한번 눌러 보세요.", "check": func() -> bool: return ItemManager.bag_size >= 3})
	s.append({"text": "[b]7. 칸 확장[/b] 선반 [b]앞[/b] 에서 [b]E[/b] 로 선반을 열고, 패널 맨 위 [b]칸 추가[/b] 버튼을 누르거나 [b]+[/b] 키를 눌러 주세요. 선반마다 따로 늘릴 수 있어요~", "check": func() -> bool: return shelves[0].state.slot_count > 3})
	s.append({"info": true, "text": "[b]던전 흐름[/b] 던전은 전투 3~5회로 이루어져요. 전투가 끝날 때마다 아이템이 들어오니까, 바닥에 쌓이기 전에 선반에 정리해 주세요! 던전이 끝나면 [b]수면[/b] → [b]상점[/b] 순서로 진행돼요."})
	s.append({"info": true, "text": "[b]실패와 게임오버[/b] 긴급 요청을 시간 안에 못 채우면 실패가 1 쌓여요. [b]실패 3번[/b] 이면 게임오버예요ㅠ 던전이나 상점이 끝날 때마다 자동 저장되니까, 메인 메뉴의 [b]이어하기[/b] 로 이어서 할 수 있어요."})
	s.append({"info": true, "text": "[b]상점 구매와 무게[/b] 상점에서는 판매 후 골드로 아이템을 [b]구매[/b] 할 수 있고, 구매한 아이템은 바닥에 떨어져요. 골드가 모자라면 그 품목은 건너뛰어요. 선반 칸 하나는 무게 [b]12[/b] 까지만 들어가니까, 넘치면 다른 칸을 써 주세요!"})
	s.append({"info": true, "text": "[b]가방, 일시정지, 설정[/b] 손에 드는 개수는 상점([b]C[/b])의 [b]가방 확장[/b] 으로 늘릴 수 있어요. [b]P[/b] 는 일시정지, [b]F2[/b] 는 설정(전체 화면)이에요~"})
	s.append({"info": true, "text": "[b]조작 요약[/b] 이동 WASD · 줍기 X · 선반 열기 E (열면 이동이 잠겨요) · 아이템 고르기 ←→ · 선반 바꾸기 ↑↓ · 꺼내기 X · 넣기 1~3 · 내려놓기 Z · 칸 추가 + · 상점 C · 일시정지 P · 설정 F2. 헷갈리면 언제든 다시 봐 주세요!"})
	s.append({"info": true, "text": "[b]튜토리얼 완료![/b] 정말 잘했어요! 이제 메인 메뉴에서 [b]새 게임[/b] 을 눌러 시작해 봐요. 시작 버튼을 누르면 메인 메뉴로 돌아가요~"})
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

## 튜토리얼 긴급 퀘스트: 항상 회복약 1개
func _spawn_potion_quest() -> void:
	_quest_kind = "potion_hp"
	DungeonManager.spawn_quest_now({"quantity": 1, "line_max": 1, "time_limit": 120.0, "gold": 10, "exp": 10, "fixed_lines": [{"item_kind": "potion_hp", "required": 1}]})


## 튜토리얼 지원: 선반에 kind 아이템이 없으면 (이미 꺼냈거나 빠진 경우) 새로 만들어 선반에 넣는다
## 손에 들고 있거나 선반에 있으면 아무것도 하지 않는다. 칸이 없으면 바닥에 둔다
func _ensure_on_shelf(kind: String) -> void:
	if _carrying(kind) or _stored_kind(kind):
		return
	# 바닥에 있는 같은 종류 아이템이 있으면 그것을 쓰고, 없으면 새로 만든다
	var item: ItemInstance = null
	for id in ItemManager.items:
		var it: ItemInstance = ItemManager.items[id]
		if it.state == ItemInstance.State.INCOMING and it.data.item_id == kind:
			item = it
			break
	if item == null:
		item = add_item(load("res://data/items/%s.tres" % kind), shelves[0].position + Vector2(0, 60))
	if not ItemManager.try_pick_up(item, item.world_position):
		return
	for s in shelves:
		for slot in s.state.slot_count:
			if ItemManager.place_carried(item.instance_id, s.state, slot)["ok"]:
				_refresh()
				return


## 선반(어느 칸이든)에 kind 아이템이 들어 있는지
func _stored_kind(kind: String) -> bool:
	for id in ItemManager.items:
		var it: ItemInstance = ItemManager.items[id]
		if it.state == ItemInstance.State.STORED and it.data.item_id == kind:
			return true
	return false


## 손에 든 아이템 중에 kind 가 있는지
func _carrying(kind: String) -> bool:
	for id in ItemManager.carried_ids:
		if ItemManager.items.has(id) and ItemManager.items[id].data.item_id == kind:
			return true
	return false


func _quest_done() -> bool:
	return DungeonManager.quests.quest != null and DungeonManager.quests.quest.status == Quest.Status.SUCCESS


func _level_up() -> void:
	EconomyManager.choices_enabled = true
	EconomyManager.add_exp(EconomyManager.exp_to_next() - EconomyManager.exp_points)


func _spawn_floor_item() -> void:
	_floor_item = add_item(load("res://data/items/axe.tres"), Vector2(500, 430))


var _floor_carried := false
## 선반 닫기 단계: 패널이 열렸다가 닫혔는지
var _was_open := false


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
	if completed:
		return
	_guide_button.visible = false
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
