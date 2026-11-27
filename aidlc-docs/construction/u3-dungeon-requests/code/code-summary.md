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
| US-11 던전 전투 진행 | scripts/dungeon/dungeon_rules.gd (roll_intake), dungeon_flow.gd, dungeon_table.gd, data/dungeons/dungeons.json (intake_min/max 5~10) | test_dungeon_rules, test_dungeon_properties, test_dungeon_slice |
| US-12 던전 완료 판정 | dungeon_rules.gd (is_complete), dungeon_flow.gd (finish_battle) | test_dungeon_rules, test_dungeon_slice |
| US-13 30초 수면 | dungeon_flow.gd (begin_sleep, tick_sleep) | test_dungeon_slice |
| US-14 미정리 누적 | dungeon_flow.gd (입고는 incoming 유지, 상태 불변) | test_dungeon_slice (입고 수 범위 5~10 × 전투 수) |
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
- **위치 · 조작**: 전달 선반은 창고 방 오른쪽 아래 (`DELIVERY_SHELF`, U3-CG-1 = A). 두 가지 방식으로 넣는다. (1) 목록의 아이템을 선반에 **드래그앤드롭** (`DeliveryDropTarget`, 선반 칸과 같은 방식). (2) 가까이 가서 클릭해 열고 **1 키**. 둘 다 아이템 **1개씩** 넣는다. 한 번에 여러 개를 넣는 기능은 없다. 선반 가까이 있을 때만 받는다. 바닥 아이템은 대상이 아니다. 선반 아이템은 먼저 꺼내서 들고 가야 한다.
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

## 아이템 아이콘 (추가)
- 원본 시트: `art/items/potions_sheet.png` (29 x 9 칸), `art/items/items_sheet.png` (36 x 35 칸). 칸 크기 16px.
- `ItemData.icon_sheet` + `icon_cell` 로 칸을 지정하고, `ItemData.icon()` 이 AtlasTexture 를 돌려준다.
- 적용 위치: `ItemView` (맵), `ItemListPanel.make_entry` (목록 · 선반 칸).
- 칸 선택은 시각 확인으로 골랐다. 주문서 (`scroll`, 시트 0,10) 과 광석 상자 (`ore_box`, 24,5) 는 확신이 낮다. 수동 테스트에서 확인.
- `.gitignore` 에 `assets` 가 있어서 이미지 폴더를 `art/` 로 두었다.
- 테스트: `tests/unit/test_item_icons.gd` (모든 아이템이 시트 안의 칸을 가짐).

## 퀘스트 패널 위치와 바닥 (추가)
- 퀘스트 패널은 왼쪽 위 (8, 8), 반투명 배경 (검정 45%). 아이템 목록 (y 60) 과 겹칠 수 있어 화면에서 확인 필요.
- 바닥은 Kenney Tiny Dungeon 타일 `tile_0049` (모래색, CC0) 을 `art/floor/floor_tile.png` 로 두고 타일 반복으로 깐다. 라이선스 파일 `art/floor/License.txt`.
- 원본 자산 폴더 `assets/` 는 저장소에서 `.gitignore` 로 제외되어 있어, Kenney 원본 zip 은 과거 커밋 (21e9b12) 에서 가져왔다.

---

## 변경 기록 (2026-11-27)
- 전투 입고: 총량 분배 (T = 10) 를 폐지하고 **전투마다 5~10개 무작위** 로 바꿨습니다 (`DungeonRules.roll_intake`).
- 초기 선반: 튜토리얼 이후 던전을 시작할 때 선반 **3개** 로 시작합니다 (`StorageRoom.START_SHELVES = 3`, 한 던전 입고 약 108 무게 ≈ 선반 3 × 36).
- 선반 가격표 (`economy.json` shelf_prices): 다음 선반 가격은 현재 선반 수 기준. 3개일 때 다음 선반 500, 그 다음 800, 1200. 6번째 이후는 구매 불가.
