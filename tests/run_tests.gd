# 헤드리스 테스트 러너. 최초 1회는 --import 로 클래스 캐시를 만들어야 한다.
# 실행: godot --headless --path . --import
#       godot --headless --path . -s res://tests/run_tests.gd
extends SceneTree

const TEST_FILES := [
	"res://tests/unit/test_weight_rules.gd",
	"res://tests/unit/test_storage_flow.gd",
	"res://tests/unit/test_placement_rules.gd",
	"res://tests/unit/test_movement_speed.gd",
	"res://tests/unit/test_storage_properties.gd",
	"res://tests/integration/test_tutorial_slice.gd",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
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
	print("PBT seed=%d tests=%d failed=%d" % [load("res://tests/support/pbt.gd").base_seed(), total, failed])
	quit(1 if failed > 0 else 0)
