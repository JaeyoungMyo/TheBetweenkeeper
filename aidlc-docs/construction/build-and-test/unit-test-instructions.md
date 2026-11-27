# 단위 테스트 실행 (Unit Test Execution)

## 실행
```
godot --headless --path . -s res://tests/run_tests.gd
```
러너 (`tests/run_tests.gd`) 가 단위 · 통합 · PBT 를 모두 실행한다. 실행 전에 저장 파일 (`user://save.dat`) 을 지운다.

## 기대 결과
- 마지막 줄: `PBT seed=20261124 tests=83 failed=0` (단위 · 통합 · PBT · 동작 합계)
- 종료 코드 0
- 실패가 있으면 `FAIL <파일>::<함수> -> <사유>` 줄이 출력된다.

## PBT 재현
- 실패한 PBT 는 `PBT_SEED=<seed>` 환경 변수로 같은 무작위 값을 재현한다.
  - 예: `PBT_SEED=20261124 godot --headless --path . -s res://tests/run_tests.gd`

## 테스트 목록 (단위 · PBT)
| 영역 | 파일 |
| --- | --- |
| U1 무게 · 칸 · 배치 · 이동 | test_weight_rules, test_placement_rules, test_movement_speed, test_floor_stack, test_carry_capacity, test_storage_flow, test_storage_properties |
| U2 골드 · EXP · 증강 | test_economy, test_economy_properties |
| U3 던전 · 퀘스트 | test_dungeon_rules, test_quest_rules, test_quest_progress, test_failure_counter, test_dungeon_properties |
| U4 상점 | test_shop_rules, test_quest_value, test_shop_properties |
| U5 저장 | test_save_codec, test_save_properties |
| 아이콘 | test_item_icons |

## 커버리지
- **기준**: 80% (사용자 결정)
- **측정**: 미측정. Godot 기본에 라인 커버리지 도구가 없다. 측정하려면 커버리지 애드온 도입이 필요하다 (승인 대기).
