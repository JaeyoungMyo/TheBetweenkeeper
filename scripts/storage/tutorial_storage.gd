# 튜토리얼 (US-01): 아이템 5개를 한 단계씩 따라 하며 조작을 배운다. 끝나면 설명 페이지 후 던전 1 시작
extends StorageRoom

signal tutorial_completed

## 튜토리얼 아이템 (5개, 무게 합 13 → 선반 1개에 들어감)
const TUTORIAL_IDS := ["potion_hp", "scroll", "sword", "dagger", "helmet"]
const ITEM_SPOT_Y := 215.0

var tutorial_items: Array[ItemInstance] = []
var completed := false
var take_out_count := 0

var _guide: CanvasLayer
var _guide_label: RichTextLabel
var _guide_button: Button
var _steps: Array = []
var _step := 0
var _guide_running := false


func _ready() -> void:
	super()
	tutorial_completed.connect(_start_dungeon)
	_build_guide()
	if SaveService.has_save():
		_offer_continue()
	else:
		_create_tutorial_items()


func _create_tutorial_items() -> void:
	tutorial_items.clear()
	for i in TUTORIAL_IDS.size():
		# 선반 1 (610, 140) 앞쪽에 가깝게 둔다
		var pos := Vector2(520 + i * 60, ITEM_SPOT_Y)
		tutorial_items.append(add_item(load("res://data/items/%s.tres" % TUTORIAL_IDS[i]), pos))
	_start_guide()


## 저장 파일이 있으면 이어하기 / 새 게임 중 고른다
func _offer_continue() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(520, 300)
	layer.add_child(box)
	var label := Label.new()
	label.text = "저장된 진행이 있습니다"
	box.add_child(label)
	var cont := Button.new()
	cont.text = "이어하기"
	cont.pressed.connect(func() -> void:
		layer.queue_free()
		_continue_game())
	box.add_child(cont)
	var fresh := Button.new()
	fresh.text = "새 게임 (튜토리얼)"
	fresh.pressed.connect(func() -> void:
		layer.queue_free()
		SaveService.delete_save()
		_create_tutorial_items())
	box.add_child(fresh)


## 저장 지점에 맞춰 다시 시작: 던전 완료 저장 → 상점부터, 상점 완료 저장 → 다음 던전
func _continue_game() -> void:
	var d := SaveService.load_save()
	if d.is_empty():
		show_message("저장 파일이 손상되어 새 게임으로 시작합니다")
		SaveService.delete_save()
		_create_tutorial_items()
		return
	restore_layout(d["shelves"])
	completed = true
	var ui := find_child("DungeonUi", true, false) as DungeonUi
	if ui == null:
		return
	if d["point"] == "dungeon_clear":
		ui.resume_at_shop()
	else:
		ui.resume_next_dungeon()


## 선반에서 꺼내기 (StorageRoom 이 호출)
func on_take_out_done() -> void:
	take_out_count += 1


# ---------- 단계별 안내 ----------

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
	var steps := []
	steps.append({"text": "1/8 아이템에게 다가가세요. [b]WASD[/b] 로 움직이거나 빈 바닥을 클릭하세요.", "check": func() -> bool: return _near_any_item()})
	steps.append({"text": "2/8 [b]X[/b] 키로 아이템을 주우세요.", "check": func() -> bool: return not ItemManager.carried_ids.is_empty()})
	steps.append({"text": "3/8 선반에 다가가세요. 선반 [b]앞[/b] 까지 걸어가세요.", "check": func() -> bool: return _near_shelf0()})
	steps.append({"text": "4/8 [b]X[/b] 키로 선반을 여세요.", "check": func() -> bool: return shelf_panel.visible})
	steps.append({"text": "5/8 선반이 열린 상태에서 [b]1[/b] 키를 누르면 들고 있는 아이템이 1번 칸에 들어갑니다. 1 키를 누르세요.", "check": func() -> bool: return _stored_count() >= 1})
	steps.append({"text": "6/8 같은 방법으로 남은 아이템을 넣으세요. 아이템을 집고 → 선반 앞 → [b]X[/b] → [b]1·2·3[/b] 키 (칸 번호).", "check": func() -> bool: return _all_stored()})
	steps.append({"text": "7/8 이제 선반에서 꺼내 봅시다. 선반 앞에서 [b]X[/b] 로 선반을 열고, 손을 비운 상태에서 [b]1[/b] 키를 누르세요. 그 칸의 맨 위 아이템이 나옵니다.", "check": func() -> bool: return take_out_count >= 1})
	steps.append({"text": "8/8 꺼낸 아이템을 다시 넣으세요 (선반 열림 상태에서 1·2·3 키). 모두 넣으면 다음 안내로 넘어갑니다.", "check": func() -> bool: return _all_stored()})
	steps.append({"info": true, "text": "[b]긴급 요청[/b]: 왼쪽 아래 패널에 나온 품목을 들고 [b]전달 선반[/b] (창고 오른쪽 아래 파란 칸) 가까이 가서 [b]Z[/b] 키로 1개씩 넣으세요. 제한 시간 안에 다 넣으면 성공입니다."})
	steps.append({"info": true, "text": "[b]전투와 수면[/b]: 던전에서는 전투마다 아이템이 들어옵니다. 전투가 끝나면 [b]수면 60초[/b] 동안 정리하고, [b]C[/b] 키로 선반과 칸을 강화할 수 있습니다."})
	steps.append({"info": true, "text": "[b]상점[/b]: 던전이 끝나면 [b]판매 퀘스트[/b]가 뜹니다. 잡템과 장비를 출력공간 (전달 선반) 에 넣어 팔면 골드와 EXP 를 얻습니다. 구매품은 맵에 떨어집니다."})
	steps.append({"info": true, "text": "[b]조작 요약[/b]: 이동 WASD · 줍기 X · 내려놓기 Z · 선반 칸 1~3 · 강화 C · 설정 F2. 이제 [b]던전 1[/b] 을 시작합니다."})
	return steps


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
		_finish_guide()
		return
	var step: Dictionary = _steps[_step]
	_guide_label.text = step["text"]
	_guide_button.visible = step.get("info", false)
	_guide_button.text = "시작" if _step == _steps.size() - 1 else "다음"


func _on_guide_next() -> void:
	_step += 1
	_show_step()


func _finish_guide() -> void:
	_guide_running = false
	_guide.visible = false
	completed = true
	SaveService.tutorial_done = true
	show_message("튜토리얼 완료!")
	tutorial_completed.emit()


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


## 튜토리얼 완료 후 던전 1 시작 (U3-CG-2 = A)
func _start_dungeon() -> void:
	var ui := find_child("DungeonUi", true, false) as DungeonUi
	if ui != null:
		ui.start_run()
