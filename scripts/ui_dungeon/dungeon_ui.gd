# 던전 · 요청 화면 (U3 Step 15~16). 코드로 구성: 퀘스트 목록, 전달 공간, 전투 진행, 수면, 게임오버
class_name DungeonUi
extends CanvasLayer

## 전달 공간: 창고 방 오른쪽 아래 고정 위치 (U3-CG-1 = A)
const DELIVERY_ZONE := Rect2(900, 470, 90, 110)
## 입고 아이템이 떨어지는 영역 (선반과 전달 공간을 피한 바닥)
const INTAKE_AREA := Rect2(260, 480, 560, 150)
## 전투 길이와 전투 사이 간격 (초기값, 연출 조정 대상)
const BATTLE_SEC := 8.0
const BATTLE_GAP_SEC := 2.0

var room: StorageRoom
var _quest_box: PanelContainer
var _quest_text: RichTextLabel
var _battle_label: Label
var _zone_label: Label
var _sleep: ColorRect
var _sleep_label: Label
var _game_over: ColorRect
var _game_over_label: Label
var _battle_timer := 0.0
var _gap_timer := 0.0
var _running := false
var _shown_quest_text := ""


func _ready() -> void:
	layer = 2
	_build_zone()
	_build_hud()
	_build_sleep()
	_build_game_over()
	DungeonManager.intake_ready.connect(_on_intake)
	DungeonManager.quest_result.connect(_on_quest_result)
	DungeonManager.game_over_reached.connect(_on_game_over)
	DungeonManager.shop_visit_ready.connect(_on_shop_visit)


## 튜토리얼 완료 후 던전 1 을 시작한다 (U3-CG-2 = A)
func start_run() -> void:
	DungeonManager.start_dungeon(1)
	_running = true
	_begin_battle()


func _begin_battle() -> void:
	DungeonManager.start_battle()
	_battle_timer = BATTLE_SEC


func _process(delta: float) -> void:
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
	_sleep.visible = flow.state == DungeonFlow.State.SLEEP
	if _sleep.visible:
		_sleep_label.text = "용사가 잠들었습니다\n정리 시간 %d초" % ceili(flow.sleep_left)
	_battle_label.text = "던전 %d · 전투 %d / %d" % [flow.dungeon_no, flow.battle_index, flow.battle_total]
	_zone_label.text = "전달 공간\n" + _summary()
	_refresh_quest()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not _running or key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ENTER and DungeonManager.flow.state != DungeonFlow.State.GAME_OVER:
		_deliver()


## Enter: 플레이어가 전달 공간 안에 있으면 들고 있는 아이템을, 전달 공간 안 바닥 아이템은 항상 올린다
func _deliver() -> void:
	var targets: Array[ItemInstance] = []
	if DELIVERY_ZONE.has_point(room.player.position):
		for id in ItemManager.carried_ids.duplicate():
			targets.append(ItemManager.items[id])
	for v: ItemView in room.views.values():
		if v.item.state == ItemInstance.State.INCOMING and DELIVERY_ZONE.has_point(v.item.world_position):
			targets.append(v.item)
	if targets.is_empty():
		return
	for item in targets:
		ItemManager.carried_ids.erase(item.instance_id)
		if room.views.has(item.instance_id):
			room.views[item.instance_id].queue_free()
			room.views.erase(item.instance_id)
		DungeonManager.put_in_delivery(item)
	room.refresh()


func _refresh_quest() -> void:
	var active := DungeonManager.quests.is_active()
	_quest_box.visible = active
	if not active:
		return
	var q := DungeonManager.quests.quest
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
		_quest_text.text = "[b]긴급 요청[/b]\n" + body


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


func _on_intake(count: int) -> void:
	for i in count:
		var id: String = room.ITEM_IDS.pick_random()
		var pos := Vector2(randf_range(INTAKE_AREA.position.x, INTAKE_AREA.end.x), randf_range(INTAKE_AREA.position.y, INTAKE_AREA.end.y))
		room.add_item(load("res://data/items/%s.tres" % id), pos)
	room.show_message("아이템 %d개가 입고되었습니다" % count)


func _on_quest_result(r: Dictionary) -> void:
	if r["result"] == "success":
		room.show_message("퀘스트 성공! 골드 +%d, EXP +%d" % [r["gold"], r["exp"]])
	else:
		room.show_message("퀘스트 실패 (실패 %d / %d)" % [DungeonManager.failures.count, FailureCounter.LIMIT])


func _on_game_over(failures: int) -> void:
	_game_over_label.text = "요청 실패 %d / %d\n게임오버" % [failures, FailureCounter.LIMIT]
	_game_over.visible = true
	_running = false


func _on_shop_visit() -> void:
	room.show_message("상점 방문 (U4 에서 연결 예정)")
	_running = false


func _build_zone() -> void:
	var z := ColorRect.new()
	z.position = DELIVERY_ZONE.position
	z.size = DELIVERY_ZONE.size
	z.color = Color(0.3, 0.5, 0.8, 0.25)
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(z)
	_zone_label = Label.new()
	_zone_label.position = DELIVERY_ZONE.position + Vector2(0, DELIVERY_ZONE.size.y + 4)
	_zone_label.custom_minimum_size = Vector2(200, 0)
	_zone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_zone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_zone_label)


func _build_hud() -> void:
	_quest_box = PanelContainer.new()
	_quest_box.position = Vector2(1015, 400)
	_quest_box.custom_minimum_size = Vector2(240, 0)
	_quest_box.visible = false
	_quest_text = RichTextLabel.new()
	_quest_text.bbcode_enabled = true
	_quest_text.fit_content = true
	_quest_text.custom_minimum_size = Vector2(230, 0)
	_quest_box.add_child(_quest_text)
	add_child(_quest_box)
	_battle_label = Label.new()
	_battle_label.position = Vector2(540, 690)
	_battle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_battle_label)


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
	get_tree().reload_current_scene()
