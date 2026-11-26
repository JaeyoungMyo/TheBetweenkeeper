# 판매 퀘스트 보상 훅 (QuestController.value_of): 판매가 합계 골드, 훅이 없으면 U3 동작 유지
extends TestBase


func _item(kind: String, id: int) -> ItemInstance:
	var d := ItemData.new()
	d.item_id = kind
	d.weight = 2
	return ItemInstance.new(id, d, 1)


func _price(data: ItemData) -> int:
	return data.weight * 10


func test_success_gold_is_sum_of_sell_prices_with_hook() -> void:
	var space := DeliverySpace.new()
	var ctrl := QuestController.new(space)
	ctrl.value_of = Callable(self, "_price")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var spec := {"quantity": 3, "line_max": 1, "time_limit": 120.0, "gold": 0, "exp": 80}
	ctrl.spawn(spec, ["sword"], rng)
	for i in 3:
		space.put(_item("sword", 20 + i))
	var r := ctrl.on_delivery_changed()
	expect(r.get("result") == "success", "quest succeeds")
	expect(int(r["gold"]) == 60, "3 items x 20 each")
	expect(int(r["exp"]) == 80, "exp reward")


func test_without_hook_uses_reward_gold() -> void:
	var space := DeliverySpace.new()
	var ctrl := QuestController.new(space)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	ctrl.spawn({"quantity": 2, "line_max": 1, "time_limit": 30.0, "gold": 30, "exp": 20}, ["potion_hp"], rng)
	space.put(_item("potion_hp", 1))
	space.put(_item("potion_hp", 2))
	var r := ctrl.on_delivery_changed()
	expect(int(r["gold"]) == 30, "U3 behaviour kept")
