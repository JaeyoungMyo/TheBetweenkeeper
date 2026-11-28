# 던전 · 요청 화면 (U3 Step 15~16). 코드로 구성: 퀘스트 목록, 전달 선반, 전투 진행, 수면, 게임오버
class_name DungeonUi
extends CanvasLayer

## 전달 선반: 창고 방 오른쪽 아래 고정 위치 (U3-CG-1 = A). 플레이어가 가까이 가서 아이템을 넣는다
const DELIVERY_SHELF := Rect2(860, 420, 80, 90)
## 입고 아이템이 떨어지는 영역 (선반과 전달 선반을 피한 바닥)
const INTAKE_AREA := Rect2(340, 390, 440, 120)
## 전투 길이와 전투 사이 간격 (초기값, 연출 조정 대상)
const BATTLE_SEC := 16.0
const BATTLE_GAP_SEC := 4.0

var room: StorageRoom
var _quest_box: PanelContainer
var _quest_text: RichTextLabel
var _progress: DungeonProgressBar
var _zone_label: Label
var _sleep: ColorRect
var _sleep_label: Label
var _game_over: ColorRect
var _game_over_label: Label
var _battle_timer := 0.0
var _gap_timer := 0.0
var _running := false
var _shown_quest_text := ""
var village: VillageFlow = null
## 튜토리얼 모드: 상점은 열리지만 다음 던전을 시작하지 않고 튜토리얼에 알린다
var tutorial_mode := false
signal tutorial_sell_result(r: Dictionary)
signal tutorial_village_done()
var _village_active := false
var _village_close_timer := 0.0
var _village_pending := 0.0
var _shelf_hint: Label


func _ready() -> void:
	layer = 2
	_build_zone()
	_build_hud()
	_build_sleep()
	_build_game_over()
	DungeonManager.intake_ready.connect(_on_intake)
	DungeonManager.quest_result.connect(_on_quest_result)
	DungeonManager.game_over_reached.connect(_on_game_over)
	DungeonManager.village_visit_ready.connect(_on_village_visit)
	DungeonManager.delivery_changed.connect(_on_delivery_changed)
	DungeonManager.quest_started.connect(func() -> void: _announce("긴급 요청 발생!", Color(1, 0.85, 0.3)))
	room.drop_override = Callable(self, "drop_to_shelf")


## 튜토리얼 완료 후 던전 1 을 시작한다 (U3-CG-2 = A)
func start_run() -> void:
	DungeonManager.start_dungeon(1)
	_running = true
	_begin_battle()


func _begin_battle() -> void:
	DungeonManager.start_battle()
	_battle_timer = BATTLE_SEC


func _process(delta: float) -> void:
	# 화면 표시 (긴급 요청 패널, 수면, 전달 선반) 은 튜토리얼에서도 항상 갱신한다
	_refresh_hud()
	if _village_pending > 0.0:
		_village_pending -= delta
		if _village_pending <= 0.0:
			_village_pending = 0.0
			_open_village()
		return
	if _village_active:
		_process_village(delta)
		return
	if not _running:
		return
	var flow := DungeonManager.flow
	match flow.state:
		DungeonFlow.State.IN_BATTLE:
			_battle_timer -= delta
			if _battle_timer <= 0.0:
				DungeonManager.finish_battle()
				_gap_timer = BATTLE_GAP_SEC
		DungeonFlow.State.READY:
			_gap_timer -= delta
			if _gap_timer <= 0.0:
				_begin_battle()


func _refresh_hud() -> void:
	var flow := DungeonManager.flow
	var was_sleeping := _sleep.visible
	_sleep.visible = flow.state == DungeonFlow.State.SLEEP
	if _sleep.visible and not was_sleeping:
		_focus_first_button(_sleep)
	if _sleep.visible:
		_sleep_label.text = "용사가 잠들었습니다\n정리 시간 %d초" % ceili(flow.sleep_left)
	_refresh_progress(flow)
	_zone_label.text = "전달 선반\n" + _summary()
	_shelf_hint.visible = _near_shelf() and not ItemManager.carried_ids.is_empty()
	_shelf_hint.text = "Z: 1개 넣기"
	_refresh_quest()


## 진행 바 내용: 지금 무슨 단계인지 (전투 / 정비 / 수면 / 마을 / 완료 / 게임 오버)
func _refresh_progress(flow: DungeonFlow) -> void:
	var title := "던전 %d" % flow.dungeon_no
	var info := "실패 %d / %d" % [DungeonManager.failures.count, FailureCounter.LIMIT]
	var total := flow.battle_total
	var done := 0
	var active := -1
	var fill := 0.0
	var phase := "준비 중"
	var color := Color(0.8, 0.8, 0.8)
	if _village_active or _village_pending > 0.0:
		phase = "마을 방문 중..."
		color = Color(0.5, 1, 0.6)
		done = total
	elif flow.state == DungeonFlow.State.SLEEP:
		phase = "수면 · 정리 %d초" % ceili(flow.sleep_left)
		color = Color(0.86, 0.78, 1)
		done = total
	elif flow.state == DungeonFlow.State.GAME_OVER:
		phase = "게임 오버"
		color = Color(1, 0.4, 0.4)
	elif not _running:
		if flow.state == DungeonFlow.State.DUNGEON_COMPLETE:
			phase = "던전 완료"
			done = total
			color = Color(0.95, 0.78, 0.3)
	elif flow.state == DungeonFlow.State.IN_BATTLE:
		done = flow.battle_index - 1
		active = flow.battle_index - 1
		fill = 1.0 - _battle_timer / BATTLE_SEC
		phase = "전투 %d / %d · %d초" % [flow.battle_index, total, ceili(_battle_timer)]
		color = Color(1, 0.5, 0.3)
	else:
		done = flow.battle_index
		active = flow.battle_index
		fill = 1.0 - _gap_timer / BATTLE_GAP_SEC
		phase = "정비 · 다음 전투까지 %d초" % ceili(_gap_timer)
		color = Color(0.45, 0.75, 1)
	_progress.set_view(title, phase, info, total, done, active, fill, color)


func _near_shelf() -> bool:
	return StorageService.near_rect(room.player.position, DELIVERY_SHELF)


## Z (전달 선반 근처): 들고 있는 맨 위 1개를 넣는다. 바닥에 내려놓지 않는다
func drop_to_shelf() -> bool:
	if DungeonManager.flow.state == DungeonFlow.State.GAME_OVER or not _near_shelf() or ItemManager.carried_ids.is_empty():
		return false
	_deliver_one()
	return true


## 들고 있는 아이템 중 맨 위 1개만 넣는다 (한 번에 여러 개 넣지 않음)
func _deliver_one() -> void:
	if ItemManager.carried_ids.is_empty():
		room.show_message("들고 있는 아이템이 없습니다")
		return
	_deliver_item(ItemManager.carried_ids[0])


## Z 로 아이템 1개를 넣는다
func _deliver_item(id: int) -> void:
	if not ItemManager.carried_ids.has(id) or not _near_shelf():
		return
	var item: ItemInstance = ItemManager.items[id]
	ItemManager.carried_ids.erase(id)
	if room.views.has(id):
		room.views[id].queue_free()
		room.views.erase(id)
	DungeonManager.put_in_delivery(item)
	room.refresh()


func _refresh_quest() -> void:
	if _village_active:
		_show_quest(village.quests, "판매 퀘스트")
		return
	_show_quest(DungeonManager.quests, "긴급 요청")


func _show_quest(ctrl: QuestController, title: String) -> void:
	var active := ctrl.is_active()
	_quest_box.visible = active
	if not active:
		return
	var q := ctrl.quest
	var lines := PackedStringArray()
	for l: Dictionary in q.lines:
		var text := "%s (%d/%d)" % [_name(l["item_kind"]), l["delivered"], l["required"]]
		if l["delivered"] >= l["required"]:
			lines.append("[s][color=#888888]✔ %s[/color][/s]" % text)
		else:
			lines.append("· " + text)
	var body := "\n".join(lines) + "\n남은 시간 %d초" % ceili(q.remaining)
	if body != _shown_quest_text:
		_shown_quest_text = body
		_quest_text.text = "[b]%s[/b]\n" % title + body


func _summary() -> String:
	var c := DungeonManager.delivery.counts()
	if c.is_empty():
		return "비어 있음"
	var parts := PackedStringArray()
	for k in c:
		parts.append("%s %d" % [_name(k), c[k]])
	return ", ".join(parts)


func _name(kind: String) -> String:
	for item: ItemInstance in ItemManager.items.values():
		if item.data.item_id == kind and item.data.display_name != "":
			return item.data.display_name
	return kind


func _on_intake(count: int, kinds: Array) -> void:
	for i in count:
		var id: String = kinds[i] if i < kinds.size() else room.ITEM_IDS.pick_random()
		var pos := Vector2(randf_range(INTAKE_AREA.position.x, INTAKE_AREA.end.x), randf_range(INTAKE_AREA.position.y, INTAKE_AREA.end.y))
		room.add_item(load("res://data/items/%s.tres" % id), pos)
	room.show_message("아이템 %d개가 입고되었습니다" % count)


func _on_quest_result(r: Dictionary) -> void:
	if r["result"] == "success":
		room.show_message("퀘스트 성공! 골드 +%d, EXP +%d" % [r["gold"], r["exp"]])
	else:
		room.show_message("퀘스트 실패 (실패 %d / %d)" % [DungeonManager.failures.count, FailureCounter.LIMIT])


func _on_game_over(failures: int) -> void:
	SaveService.delete_save()
	_game_over_label.text = "요청 실패 %d / %d\n게임오버" % [failures, FailureCounter.LIMIT]
	_game_over.visible = true
	_focus_first_button(_game_over)
	_running = false


## 수면이 끝나면 먼저 "상점 방문 중" 을 보여 주고, 잠시 뒤 상점 판매 퀘스트를 연다
func _on_village_visit() -> void:
	_running = false
	_village_pending = 2.5


func _open_village() -> void:
	if village == null:
		village = VillageFlow.new(DungeonManager.delivery, Callable(self, "_place_floor"))
		village.sell_finished.connect(_on_sell_finished)
		village.buy_finished.connect(_on_buy_finished)
	_village_active = true
	_village_close_timer = 0.0
	var override: Dictionary = room.sell_override() if room.has_method("sell_override") else {}
	village.open(override)
	if village.quests.is_active():
		_announce("판매 퀘스트 발생!", Color(0.5, 1, 0.6))
	room.show_message("마을 방문: 판매 퀘스트 시작")


func _process_village(delta: float) -> void:
	village.tick(delta)
	_zone_label.text = "전달 선반\n" + _summary()
	_refresh_quest()
	if village.state == VillageFlow.State.DONE:
		_village_close_timer -= delta
		if _village_close_timer <= 0.0:
			_finish_village()


func _on_sell_finished(r: Dictionary) -> void:
	tutorial_sell_result.emit(r)
	match r["result"]:
		"success":
			room.show_message("판매 성공! 골드 +%d, EXP +%d" % [r["gold"], r["exp"]])
		"skipped":
			room.show_message("판매할 아이템이 없습니다")
		_:
			room.show_message("판매 실패 (남은 아이템은 맵으로 이동)")


func _on_buy_finished(lines: Array) -> void:
	if not tutorial_mode:
		SaveService.village_visits += 1
		SaveService.save_point("village_clear")
	var parts := PackedStringArray()
	for l: Dictionary in lines:
		parts.append(_name(l["item_id"]) if l["bought"] else "%s (골드 부족)" % _name(l["item_id"]))
	room.show_message("용사가 마을에서 사 옴: " + ", ".join(parts))
	_village_close_timer = 3.0


## 이어하기: 던전 완료 저장 시점 → 상점부터
func resume_at_village() -> void:
	_on_village_visit()


## 이어하기: 상점 완료 저장 시점 → 다음 던전 시작
func resume_next_dungeon() -> void:
	DungeonManager.start_dungeon(DungeonManager.flow.dungeon_no + 1)
	_running = true
	_begin_battle()


## 상점 종료 후 다음 던전을 시작한다
func _finish_village() -> void:
	village.close()
	_village_active = false
	if tutorial_mode:
		_running = false
		tutorial_village_done.emit()
		return
	DungeonManager.start_dungeon(DungeonManager.flow.dungeon_no + 1)
	_running = true
	_begin_battle()
	room.show_message("던전 %d 시작" % DungeonManager.flow.dungeon_no)


func _on_delivery_changed() -> void:
	if _village_active and village.state == VillageFlow.State.SELL:
		village.on_output_changed()


## 상점 구매품 등을 맵 무작위 위치에 놓는다 (입력공간 없음, FD-U4-8 X)
func _place_floor(item: ItemInstance) -> void:
	var pos := Vector2(randf_range(INTAKE_AREA.position.x, INTAKE_AREA.end.x), randf_range(INTAKE_AREA.position.y, INTAKE_AREA.end.y))
	item.world_position = ItemManager.floor_position(pos)
	room.attach_item(item)


func _build_zone() -> void:
	var z := ColorRect.new()
	z.position = DELIVERY_SHELF.position
	z.size = DELIVERY_SHELF.size
	z.color = Color(0.3, 0.5, 0.8, 0.25)
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(z)
	_shelf_hint = Label.new()
	_shelf_hint.position = DELIVERY_SHELF.position + Vector2(-30, -26)
	_shelf_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shelf_hint.visible = false
	add_child(_shelf_hint)
	_zone_label = Label.new()
	_zone_label.position = DELIVERY_SHELF.position + Vector2(0, DELIVERY_SHELF.size.y + 4)
	_zone_label.custom_minimum_size = Vector2(200, 0)
	_zone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_zone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_zone_label)


## 큰 글씨 알림 (약 2초 표시 후 사라짐). 퀘스트 발생을 놓치지 않도록 한다
func _announce(text: String, color: Color) -> void:
	var banner := Label.new()
	banner.text = text
	banner.add_theme_font_size_override("font_size", 36)
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	banner.add_theme_constant_override("outline_size", 6)
	banner.position = Vector2(380, 62)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(banner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(banner.queue_free)


func _build_hud() -> void:
	_quest_box = PanelContainer.new()
	_quest_box.position = Vector2(8, 560)
	_quest_box.custom_minimum_size = Vector2(240, 0)
	_quest_box.visible = false
	_quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0, 0, 0, 0.45)
	box_style.set_corner_radius_all(4)
	box_style.set_content_margin_all(8)
	_quest_box.add_theme_stylebox_override("panel", box_style)
	_quest_text = RichTextLabel.new()
	_quest_text.bbcode_enabled = true
	_quest_text.fit_content = true
	_quest_text.custom_minimum_size = Vector2(230, 0)
	_quest_box.add_child(_quest_text)
	add_child(_quest_box)
	# 아래쪽 던전 진행 바: 전투 칸과 지금 단계 (전투 · 정비 · 수면 · 마을 방문)
	_progress = DungeonProgressBar.new()
	_progress.name = "dungeon-progress"
	_progress.position = Vector2(300, 648)
	_progress.size = Vector2(680, 64)
	add_child(_progress)


func _build_sleep() -> void:
	_sleep = ColorRect.new()
	_sleep.color = Color(0, 0, 0, 0.5)
	_sleep.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sleep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sleep.visible = false
	add_child(_sleep)
	_sleep_label = Label.new()
	_sleep_label.position = Vector2(540, 300)
	_sleep.add_child(_sleep_label)
	# 정리할 게 없으면 바로 깨워서 마을 방문으로 넘어간다
	var wake := Button.new()
	wake.name = "sleep-wake-button"
	wake.text = "용사 깨우기 (수면 건너뛰기)"
	wake.position = Vector2(520, 360)
	wake.pressed.connect(func() -> void: DungeonManager.flow.wake_up())
	_sleep.add_child(wake)


## 키보드 포커스: 화면 안의 첫 버튼을 고른다 (Enter 로 누른다)
func _focus_first_button(node: Node) -> void:
	for c in node.get_children():
		if c is Button and not c.disabled:
			c.call_deferred("grab_focus")
			return


func _build_game_over() -> void:
	_game_over = ColorRect.new()
	_game_over.color = Color(0, 0, 0, 0.85)
	_game_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.visible = false
	add_child(_game_over)
	_game_over_label = Label.new()
	_game_over_label.position = Vector2(520, 280)
	_game_over.add_child(_game_over_label)
	var again := Button.new()
	again.text = "새 게임"
	again.position = Vector2(560, 380)
	again.pressed.connect(_new_game)
	_game_over.add_child(again)


## 새 게임: U1 · U2 · U3 진행 값을 모두 처음으로 되돌리고 씬을 다시 연다
func _new_game() -> void:
	DungeonManager.reset_run()
	ItemManager.reset_run()
	EconomyManager.reset_run()
	SaveService.tutorial_done = false
	SaveService.village_visits = 0
	get_tree().reload_current_scene()
