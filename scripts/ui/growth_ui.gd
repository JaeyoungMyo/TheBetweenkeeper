# 골드 · 레벨 표시, 증강 선택 (일시정지), 구매 메뉴 (C 키). US-09, US-10, US-22
class_name GrowthUi
extends CanvasLayer

var room: StorageRoom
var hud := Label.new()
var menu := PanelContainer.new()
var choice_panel := PanelContainer.new()
var _menu_box := VBoxContainer.new()
var _choice_box := VBoxContainer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2
	hud.position = Vector2(12, 12)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	menu.position = Vector2(440, 180)
	menu.custom_minimum_size = Vector2(400, 0)
	menu.add_child(_menu_box)
	menu.hide()
	add_child(menu)
	choice_panel.position = Vector2(440, 220)
	choice_panel.custom_minimum_size = Vector2(400, 0)
	choice_panel.add_child(_choice_box)
	choice_panel.hide()
	add_child(choice_panel)
	EconomyManager.gold_changed.connect(_on_gold_changed)
	EconomyManager.exp_changed.connect(_on_exp_changed)
	EconomyManager.level_up.connect(_on_level_up)
	refresh_hud()


func _process(_delta: float) -> void:
	if not get_tree().paused and Input.is_action_just_pressed("shop_menu"):
		toggle_menu()


func refresh_hud() -> void:
	hud.text = "골드 %d   Lv.%d   EXP %d / %d   [C] 구매" % [EconomyManager.gold(), EconomyManager.level, EconomyManager.exp_points, EconomyManager.exp_to_next()]


func toggle_menu() -> void:
	menu.visible = not menu.visible
	if menu.visible:
		_fill_menu()


func _fill_menu() -> void:
	_clear(_menu_box)
	_buy_button("가방 확장 (현재 %d)" % ItemManager.bag_size, EconomyManager.bag_price(ItemManager), func() -> void: EconomyManager.buy_bag(ItemManager))
	_buy_button("선반 추가 (현재 %d)" % room.shelves.size(), EconomyManager.shelf_price(room.shelves.size()), func() -> void: room.buy_shelf())
	for i in room.shelves.size():
		var state: FacilityState = room.shelves[i].state
		_buy_button("선반 %d 칸 추가 (현재 %d)" % [i + 1, state.slot_count], EconomyManager.slot_price(state, i), func() -> void: EconomyManager.buy_slot(state, i))
	var close := Button.new()
	close.name = "menu-close-button"
	close.text = "닫기 (C)"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(menu.hide)
	_menu_box.add_child(close)


func _buy_button(text: String, price: int, action: Callable) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = "%s - %s" % [text, "최대" if price < 0 else "%d 골드" % price]
	b.disabled = price < 0 or price > EconomyManager.gold()
	b.pressed.connect(func() -> void:
		action.call()
		_fill_menu()
		room.refresh())
	_menu_box.add_child(b)


func show_choices() -> void:
	_clear(_choice_box)
	var choices := EconomyManager.draw_choices() if EconomyManager.pending_choices > 0 else []
	# 남은 선택이 없거나 모든 증강이 최대치면 닫는다
	if choices.is_empty():
		EconomyManager.pending_choices = 0
		choice_panel.hide()
		get_tree().paused = false
		return
	var title := Label.new()
	title.text = "레벨 업! 증강을 고르세요"
	_choice_box.add_child(title)
	for a: Dictionary in choices:
		var b := Button.new()
		b.name = "augment-%s-button" % a["id"]
		b.text = describe(a)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pick.bind(a["id"]))
		_choice_box.add_child(b)
	menu.hide()
	choice_panel.show()
	get_tree().paused = true


## 운반 배수는 다음 단계 (2배, 그다음 3배) 를 보여 준다
func describe(a: Dictionary) -> String:
	if a["id"] == "carry":
		return "운반배수 %d배" % (ItemManager.carry_multiplier + 1)
	return "%s: %s" % [a["name"], a["desc"]]


func pick(id: String) -> void:
	EconomyManager.choose_augment(id, ItemManager)
	show_choices()


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _on_gold_changed(_amount: int) -> void:
	refresh_hud()


func _on_exp_changed(_level: int, _exp: int) -> void:
	refresh_hud()


func _on_level_up(_level: int) -> void:
	show_choices()
