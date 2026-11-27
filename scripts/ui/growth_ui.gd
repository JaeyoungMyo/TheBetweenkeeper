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
	# 오른쪽 위 상점 버튼 (C 키와 같은 동작). 일시정지 버튼 왼쪽에 둔다
	var shop_button := Button.new()
	shop_button.name = "shop-open-button"
	shop_button.text = "구매 (C)"
	shop_button.position = Vector2(1000, 8)
	shop_button.focus_mode = Control.FOCUS_NONE
	shop_button.pressed.connect(func() -> void:
		if not get_tree().paused:
			toggle_menu())
	add_child(shop_button)
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
	# 상점 (C): 선반과 가방을 산다. 칸 추가는 선반을 열어서 (버튼 또는 + 키)
	_section("[ 구매 ]")
	_section("선반 구매")
	var n := room.shelves.size()
	if n >= EconomyManager.config["shelf_prices"].size() + 1:
		_info("새 선반: 최대 %d개입니다" % n)
	else:
		_buy_button("새 선반 사기 (%d번째)" % (n + 1), EconomyManager.shelf_price(n), func() -> void: room.buy_shelf())
		_info("새 선반은 칸 3개로 시작합니다. 칸 추가는 선반을 열고 버튼이나 + 키")
	_section("가방 구매")
	var bag_price := EconomyManager.bag_price(ItemManager)
	_buy_button("가방 확장 (현재 %d)" % ItemManager.bag_size, bag_price, func() -> void: EconomyManager.buy_bag(ItemManager))
	_info("가방은 손에 드는 개수를 늘립니다")
	var close := Button.new()
	close.name = "menu-close-button"
	close.text = "닫기 (C)"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(menu.hide)
	_menu_box.add_child(close)


func _section(title: String) -> void:
	var l := Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_menu_box.add_child(l)


func _info(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	_menu_box.add_child(l)


func _buy_button(text: String, price: int, action: Callable) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = "%s - %s" % [text, "최대" if price < 0 else "%d 골드" % price]
	b.disabled = price < 0 or price > EconomyManager.gold()
	if price >= 0 and price > EconomyManager.gold():
		b.text += " (골드 부족)"
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
