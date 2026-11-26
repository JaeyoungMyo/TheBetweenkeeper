# U3 던전 · 요청 코드 요약

**계획**: `construction/plans/u3-dungeon-requests-code-generation-plan.md` (Step 1~18)
**상태**: Step 1~17 완료. Step 15~16 UI 는 `scripts/ui_dungeon/dungeon_ui.gd` 에 코드로 구성 (`.tscn` 미작성), Step 17 디버그 항목 추가.
**검증**: Godot 4.7.2 (headless). `PBT seed=20261124 tests=55 failed=0`, 종료 코드 0. 메인 씬 300 프레임 실행 시 스크립트 오류 없음. 종료 시 리소스 누수 경고는 기존 테스트와 공통. UI 의 실제 클릭 · 화면 배치는 사람이 확인해야 한다.

```
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd
```

## 스토리별 파일

| 스토리 | 파일 | 테스트 |
| --- | --- | --- |
| US-11 던전 전투 진행 | scripts/dungeon/dungeon_rules.gd, dungeon_flow.gd, dungeon_table.gd, data/dungeons/dungeons.json | test_dungeon_rules, test_dungeon_properties, test_dungeon_slice |
| US-12 던전 완료 판정 | dungeon_rules.gd (is_complete), dungeon_flow.gd (finish_battle) | test_dungeon_rules, test_dungeon_slice |
| US-13 30초 수면 | dungeon_flow.gd (begin_sleep, tick_sleep) | test_dungeon_slice |
| US-14 미정리 누적 | dungeon_flow.gd (입고는 incoming 유지, 상태 불변) | test_dungeon_slice (입고 합 = 10) |
| US-15 긴급 요청 | quest.gd, quest_rules.gd, quest_controller.gd, delivery_space.gd | test_quest_rules, test_quest_progress, test_dungeon_properties |
| US-16 실패 누적 · 게임오버 | failure_counter.gd, dungeon_manager.gd (_handle) | test_failure_counter |
| US-17 아이템 보호 | scripts/storage/item_instance.gd (DELIVERED), autoload/economy_manager.gd (sell 차단) | test_quest_progress |
| US-18 상점 호출 | dungeon_flow.gd (SHOP_HANDOFF, 1회) | test_dungeon_slice |

## 기존 파일 수정
- `scripts/storage/item_instance.gd`: `State.DELIVERED` 추가 (끝에 추가해 기존 값 유지)
- `autoload/economy_manager.gd`: `sell` 에서 DELIVERED 아이템 거부
- `project.godot`: `DungeonManager` 오토로드 등록
- `tests/run_tests.gd`: 신규 테스트 6개 등록

## 구현 단순화 (계획과 다른 부분)
1. **퀘스트 발생 시점**: 계획은 전투 중 무작위 시점이었으나, 구현은 **선택된 전투의 시작 시점**에 발생한다. 전투 안 무작위 시간은 다음 단계에서 넣는다.
2. **퀘스트 타이머**: 전투 중 (IN_BATTLE) 과 전투 사이 (READY) 에만 흐른다. 수면 중에는 멈춘다.
3. **대기 퀘스트**: 던전이 끝나면 대기 중인 퀘스트는 실패 없이 버린다 (계획에 없던 판단).
4. **퀘스트 줄 종류**: 창고에 `STORED` 상태로 있는 종류만 쓴다 (BR-U3-08). 입고 아이템 생성 (intake) 은 신호만 낸다 (`intake_ready`), 실제 ItemInstance 생성은 UI 단계에서 연결한다.

## UI 구현 (Step 15~17)
- **위치 · 조작**: 전달 공간은 창고 방 오른쪽 아래 (`DELIVERY_ZONE`, U3-CG-1 = A). **Enter** 키로 전달한다. 플레이어가 전달 공간 안에서 **들고 있는** 아이템만 올라간다. 바닥 아이템은 대상이 아니다. 선반 아이템은 먼저 꺼내서 들고 가야 한다 (바로 이동 기능 없음, 사용자 확인).
- **퀘스트 목록**: 줄마다 `품목 (전달/필요)`. 완료 줄은 취소선과 회색. 남은 시간 표시.
- **전투 · 수면 · 게임오버**: 전투 8초, 전투 사이 2초 (초기값). 수면 중 카운트다운 오버레이. 게임오버 화면에 실패 수와 "새 게임" 버튼.
- **시작**: 튜토리얼 완료 시 던전 1 자동 시작 (U3-CG-2 = A).
- **디버그 (F1)**: "퀘스트 발생" 버튼 추가.
- **새 게임**: `DungeonManager`, `ItemManager`, `EconomyManager` 의 `reset_run()` 으로 진행 값을 처음으로 되돌리고 씬을 다시 연다.
- **입고**: 전투마다 신규 아이템을 입고 영역 (`INTAKE_AREA`) 에 무작위 종류로 만든다.

## 미구현 · 알려진 한계
- 전달 공간에 올라간 아이템은 화면에서 사라지고, 개수는 전달 공간 표시에만 나온다.
- 상점 호출 후에는 "U4 에서 연결 예정" 메시지만 띄우고 멈춘다 (U4 미구현).
- 전달 공간 위치와 P-02 (구매품 공간) 의 관계는 확인하지 않았다.
- 화면 배치 (좌표) 는 실행 화면에서 조정이 필요할 수 있다.

## 열린 항목 (검토 필요)
- 던전 2 이후 Q, 줄 수, 보상 값은 기획서 8.2 의 "예상 요청 수" 를 퀘스트 수 R 로 해석했다. 밸런스 조정 대상
