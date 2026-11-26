# 헤드리스 테스트 러너. 최초 1회는 --import 로 클래스 캐시를 만들어야 한다.
# 실행: godot --headless --path . --import
#       godot --headless --path . -s res://tests/run_tests.gd
extends SceneTree

const TEST_FILES := [
	"res://tests/unit/test_weight_rules.gd",
	"res://tests/unit/test_storage_flow.gd",
	"res://tests/unit/test_placement_rules.gd",
	"res://tests/unit/test_movement_speed.gd",
	"res://tests/unit/test_floor_stack.gd",
	"res://tests/unit/test_economy.gd",
	"res://tests/unit/test_economy_properties.gd",
	"res://tests/unit/test_carry_capacity.gd",
	"res://tests/unit/test_storage_properties.gd",
	"res://tests/integration/test_tutorial_slice.gd",
	"res://tests/unit/test_dungeon_rules.gd",
	"res://tests/unit/test_quest_rules.gd",
	"res://tests/unit/test_quest_progress.gd",
	"res://tests/unit/test_failure_counter.gd",
	"res://tests/unit/test_dungeon_properties.gd",
	"res://tests/integration/test_dungeon_slice.gd",
	"res://tests/integration/test_dungeon_ui.gd",
	"res://tests/unit/test_item_icons.gd",
	"res://tests/unit/test_shop_rules.gd",
	"res://tests/unit/test_quest_value.gd",
	"res://tests/unit/test_shop_properties.gd",
	"res://tests/integration/test_shop_flow.gd",
	"res://tests/unit/test_save_codec.gd",
	"res://tests/unit/test_save_properties.gd",
	"res://tests/unit/test_edge_cases.gd",
	"res://tests/integration/test_save_flow.gd",
	"res://tests/integration/test_behavior_input.gd",
	"res://tests/integration/test_behavior_more.gd",
	"res://tests/integration/test_continue_flow.gd",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# 테스트마다 이전 저장을 지운다 (튜토리얼이 이어하기 화면으로 가지 않도록)
	root.get_node("SaveService").delete_save()
	var total := 0
	var failed := 0
	for path in TEST_FILES:
		var script = load(path)
		if script == null or not script.can_instantiate():
			print("FAIL cannot load %s" % path)
			failed += 1
			continue
		var obj = script.new()
		if "tree" in obj:
			obj.tree = self
		for m in script.get_script_method_list():
			var method_name: String = m["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			obj.failures = []
			obj.call(method_name)
			if obj.failures.size() > 0:
				failed += 1
				print("FAIL %s::%s -> %s" % [path, method_name, ", ".join(obj.failures)])
	root.get_node("SaveService").delete_save()
	var move = load("res://tests/integration/test_click_move.gd").new()
	total += 1
	await move.run(self)
	if move.failures.size() > 0:
		failed += 1
		print("FAIL click_move -> %s" % ", ".join(move.failures))
	print("PBT seed=%d tests=%d failed=%d" % [load("res://tests/support/pbt.gd").base_seed(), total, failed])
	quit(1 if failed > 0 else 0)
