# U3 던전 · 요청 코드 요약

**계획**: `construction/plans/u3-dungeon-requests-code-generation-plan.md` (Step 1~18)
**상태**: Step 1~14 완료 (로직 · 데이터 · 단위 · PBT · 통합 테스트 · 러너 등록). **Step 15~17 (UI) 미구현**. Step 18 (이 문서) 작성.
**검증**: Godot 4.7.2 (headless) 에서 실행. `PBT seed=20261124 tests=54 failed=0`, 종료 코드 0. 스크립트 파싱 오류 없음. 종료 시 리소스 누수 경고가 있으나 테스트 실패는 아님 (기존 테스트 포함 공통).

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

## 미구현 (다음 작업)
- **Step 15**: QuestPanel, 전달 공간 UI (창고 방 고정 위치, U3-CG-1 = A). 줄 완료 표시
- **Step 16**: BattleView, SleepOverlay, GameOverScreen 장면
- **Step 17**: 디버그 메뉴 (F1) 퀘스트 강제 발생 등
- 선반 · 바닥에서 전달 공간으로 아이템을 옮길 때 기존 보관 위치에서 빼는 처리 (`ItemManager.take_out` 연결)
- 튜토리얼 완료 후 던전 1 자동 시작 (U3-CG-2 = A) 연결 (main 조립)
- 전달 공간 위치와 P-02 (구매품 공간) 의 관계 확인

## 열린 항목 (검토 필요)
- 던전 2 이후 Q, 줄 수, 보상 값은 기획서 8.2 의 "예상 요청 수" 를 퀘스트 수 R 로 해석했다. 밸런스 조정 대상
