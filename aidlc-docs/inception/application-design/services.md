# 서비스 정의 (Services)

서비스는 여러 컴포넌트를 묶어 한 흐름을 끝까지 실행하는 오케스트레이션 계층이다. 서비스 자체는 노드가 아니라 해당 오토로드 하위의 클래스다 (AD-1 B 기준 소속 명시).

---

## 1. DungeonFlowService (DungeonManager 소속)

**목적**: 던전 1개의 전체 진행 (전투 3~5회 → 완료 → 수면 → 상점 → 다음 던전) 을 상태 머신으로 실행 (FR-12~17)

**조율 대상**
- `ItemManager` : 전투마다 신규 아이템 생성 · 입고 (`create_item`, 입고 위치 계산)
- `RequestController` : 전투 중 긴급 요청 생성 · 시간 관리 (FR-20)
- `GameManager` : 던전 완료 시 자동 저장 요청 (`on_dungeon_cleared`)
- `EconomyManager` : 상점 단계에서 판매 · 구매 처리 (`confirm_sale`, `roll_purchase`)
- `ShopFlow` : 상점 화면 흐름
- UI 노드 : `BattleView`, `SleepOverlay`, `ShopView`, `RequestPanel`

**상태 흐름 (AD-5)**

```
IDLE
  └─ start_dungeon ─▶ BATTLE (battle_no = 1)
BATTLE
  ├─ 전투 종료, battle_no < total ─▶ BATTLE (battle_no += 1)
  └─ 전투 종료, battle_no == total ─▶ DUNGEON_CLEAR
DUNGEON_CLEAR
  ├─ 완료 판정 (정리 여부 무관, FR-13)
  ├─ 자동 저장 (FR-25)
  └─▶ SLEEP
SLEEP   (30초, FR-14, 플레이어는 정리 가능)
  └─ 시간 종료 ─▶ SHOP
SHOP    (판매 · 구매, FR-16, FR-30, FR-31)
  └─ 상점 종료 ─▶ NEXT_DUNGEON
NEXT_DUNGEON
  ├─ 미정리 아이템 (incoming) 포함하여 신규 목록 구성 (FR-15, D-18)
  └─▶ BATTLE (dungeon_no += 1, battle_no = 1)
```

**불변 규칙**
- 상태 전환은 `DungeonFlow.enter()` 한 곳에서만 발생 (AD-5)
- 완료 판정은 아이템 상태를 보지 않는다 (FR-13)
- 전투 중 요청 실패가 3회에 도달하면 즉시 `GameManager` 가 게임오버로 전환 (FR-21)

---

## 2. ShopService (DungeonManager 소속, ShopFlow 가 사용)

**목적**: 상점 방문 한 번의 판매와 구매를 처리 (FR-16, FR-30, FR-31, D-18)

**판매 흐름**
1. 상점이 열리면 판매 퀘스트가 발생한다 (`start_sell_quest`). 줄 (품목 × 필요 개수) 은 창고의 판매 가능 품목에서 고른다. 제한 시간은 길다.
2. 플레이어가 줄에 해당하는 아이템을 `OutputSpace` 에 옮긴다 (`ItemManager.move_to_output`).
3. 줄을 모두 채우면 퀘스트 성공. `OutputSpace` 에서 줄 필요 개수만큼만 판매하고 (`confirm_sale`), `EconomyManager.sell_price` 합계를 골드로 지급하고, EXP 보상을 준다. 판매된 아이템은 `sold` 상태가 된다 (FR-23).
4. 시간 초과 시 실패. 출력공간 아이템은 판매하지 않고, 상점 종료 시 맵 어딘가로 이동한다.
5. 예약 아이템 (`reserved`) 과 물약 (소모품) 은 판매 퀘스트 후보에서 제외한다.

**구매 흐름**
1. `ShopFlow.build_offer` 가 `EconomyManager.roll_purchase` 로 품목과 수량을 만든다 (FR-18).
2. 용사가 구매를 확정하면 (`request_purchase`) `EconomyManager.spend_gold` 로 차감한다. 잔액 부족이면 구매 전체 실패 (FR-19).
3. 성공하면 구매 수량만큼 `ItemManager.create_item` 으로 `incoming` 아이템을 만든다.
4. `ItemManager.spawn_into_input_space` 가 입력공간 안에서 무작위 빈 자리를 고른다 (`PlacementRules.pick_random_free_slot`). 자리가 없으면 남은 아이템은 다음 던전 목록으로 넘긴다 (A-07 확인 필요).

**불변 규칙**
- 골드 변경은 `EconomyManager` 메서드만 사용 (NFR-04)
- 구매는 원자적으로 처리: 차감 실패 시 아이템을 만들지 않는다

---

## 3. StorageService (ItemManager 소속)

**목적**: 플레이어의 줍기 · 적재 · 드롭을 검증하고 상태를 갱신 (FR-03~07, D-14, D-16)

**흐름**
- 줍기 (`pick_up`): 호버 후 클릭 또는 키보드 키. 이미 들고 있으면 실패 (운반 개수 제한, 기본 1)
- 적재 (`place_into_facility`): 선반 패널 열림 상태에서만 허용. `WeightRules.can_add` 로 검사, 초과면 `weight_rejected` 시그널 후 아이템을 그 자리 바닥에 떨어뜨림 (`item_dropped`, FR-07)
- 드롭 (`drop_on_map`): 패널이 닫힌 상태에서 맵 아무 곳에나 드롭. 현재 위치에 버려짐 (D-14)
- 겹침 검사: `PlacementRules.overlaps` 로 맵 위 충돌 영역 검사 (기획서 3.4)

---

## 4. SaveService (GameManager 소속)

**목적**: 자동 저장, 웹 내보내기 · 불러오기를 서명된 JSON 으로 처리 (FR-25, FR-26, NFR-03, AD-8, AD-9)

**흐름**
- 자동 저장: `on_dungeon_cleared` → 스냅샷 구성 (아이템 위치·상태, 골드, 시설, 성장, 던전 번호, 실패 횟수) → `SaveCodec.to_json` → `SaveCodec.sign` → `user://save.json` 에 기록
- 내보내기 (웹): `export_save_text()` 결과를 브라우저 파일 다운로드로 제공 (`SaveTransferPanel`)
- 불러오기: 텍스트 입력 → `SaveCodec.verify` → 실패 시 거부 → 성공 시 스냅샷 복원
- 복원 후 아이템 수와 상태를 비교하는 검사 (NFR-03, 저장 10회 왕복 테스트)

**보안 경계 (AD-9)**
- HMAC 키는 코드에 상수로 두지 않고 빌드 시 주입한다 (단순 문자열 검색으로 찾기 어렵게). 완전한 비밀은 아니다.
- 서명 실패는 항상 거부한다. 부분 복원은 하지 않는다.

---

## 5. RequestService (DungeonManager 소속)

**목적**: 긴급 요청의 생성, 제한 시간, 성공 · 실패 처리 (FR-20~22)

**흐름**
1. 전투 중 `RequestController.spawn_request` 로 요청 생성 (요청 종류는 DungeonTable 기준)
2. `_process` 에서 `tick` 으로 시간 누적. 만료되면 `fail_request` 호출
3. 전달 (`fulfill_request`) 성공 시 `EconomyManager` 로 보상 지급 (골드, EXP, FR-22)
4. 실패 시 `RequestRules.next_failure_count` 로 누적. `is_game_over` 이면 `GameManager.game_over` 시그널 (FR-21)
5. 요청 중 아이템은 `reserved` 로 바꿔 판매를 막는다 (FR-23)

---

## 6. ProgressionService (EconomyManager 소속)

**목적**: 수납 EXP, 레벨업, 증강 선택 (FR-10, FR-11)

**흐름**
- 아이템이 정해진 보관 위치에 적재되면 `grant_exp` (중복 지급 방지, `is_exp_claimed` 기록)
- 누적 EXP가 `exp_to_next_level` 에 도달하면 `level_up` 시그널 → `AugmentSelection` 표시 → 선택 결과를 `apply_augment` 로 반영
- 증강 후보는 `draw_augment_choices` 로 중복 제한을 지켜 뽑는다
