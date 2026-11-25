# 자체 PBT 도구 (PBT-07, 08): 도메인 생성기, seed 재현, 목록 축소
# 재현: PBT_SEED=<seed> 환경 변수로 실행
class_name Pbt
extends RefCounted

const RUNS := 200


static func base_seed() -> int:
	var s := OS.get_environment("PBT_SEED")
	return int(s) if s != "" else 20261124


static func gen_weights(rng: RandomNumberGenerator, max_len: int = 30) -> Array:
	var out := []
	for i in rng.randi_range(0, max_len):
		out.append(WeightRules.ALLOWED_ITEM_WEIGHTS[rng.randi_range(0, 4)])
	return out


## 명령: [종류 (0 줍기+적재, 1 꺼내기, 2 드롭), 칸, 무게]
static func gen_commands(rng: RandomNumberGenerator) -> Array:
	var out := []
	for w in gen_weights(rng, 40):
		out.append([rng.randi_range(0, 2), rng.randi_range(0, 2), w])
	return out


## prop 은 실패 사유 (성공이면 "") 를 반환. 실패 시 원소를 하나씩 빼며 축소
static func check(gen: Callable, prop: Callable) -> String:
	for run in RUNS:
		var rng := RandomNumberGenerator.new()
		rng.seed = base_seed() + run
		var input: Array = gen.call(rng)
		if prop.call(input) == "":
			continue
		var k := 0
		while k < input.size():
			var smaller := input.duplicate()
			smaller.remove_at(k)
			if prop.call(smaller) != "":
				input = smaller
				k = 0
			else:
				k += 1
		return "seed=%d run=%d minimal=%s: %s" % [base_seed(), run, str(input), prop.call(input)]
	return ""
