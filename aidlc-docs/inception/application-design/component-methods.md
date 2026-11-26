# 컴포넌트 메서드 (Component Methods)

**표기**: 시그니처는 GDScript 4 기준. 상세 비즈니스 규칙은 Functional Design (unit 별) 에서 정한다.
**시그널 표기**: `signal name(args)` 는 발신 컴포넌트에서 선언한다 (AD-4).

---

## 1. GameManager (autoload)

```gdscript
signal game_over()
signal dungeon_saved(dungeon_no: int)

func start_new_game() -> void                 # 새 게임 시작, 상태 초기화
func load_from_file_text(text: String) -> bool  # 불러오기 (SaveService 경유, 서명 실패 시 false)
func export_save_text() -> String               # 내보내기용 JSON + 서명 텍스트
func on_dungeon_cleared(dungeon_no: int) -> void  # DungeonManager 가 호출, 자동 저장 트리거
func add_request_failure() -> int               # 누적 실패 증가, 현재 누적값 반환
func is_game_over() -> bool
func change_screen(screen_id: StringName) -> void # Main 에 화면 전환 요청
```

## 2. DungeonManager (autoload)

```gdscript
signal battle_started(battle_no: int, total: int)
signal battle_items_arrived(battle_no: int, count: int)
signal dungeon_cleared(dungeon_no: int)
signal sleep_started(seconds: float)
signal sleep_finished()
signal shop_opened(dungeon_no: int)
signal shop_closed()
signal request_started(request: Dictionary)
signal request_result(success: bool, request_id: int)

func start_dungeon(dungeon_no: int) -> void         # DungeonFlow 시작
func tick(delta: float) -> void                     # DungeonFlow 와 RequestController 구동 (_process 에서 호출)
func current_state() -> StringName                  # IDLE, BATTLE, DUNGEON_CLEAR, SLEEP, SHOP, NEXT_DUNGEON
func start_sell_quest() -> void                     # 판매 퀘스트 발생 (긴 시간, 많은 수량, EXP 보상)
func confirm_sale() -> int                          # 판매 퀘스트 성공 시 줄 수량만큼 판매, 획득 골드 반환
func request_purchase(order: Array) -> void         # 구매 확정 → EconomyManager 차감 → ItemManager 입력공간 입고
func fulfill_request(item_id: int) -> bool          # 요청 아이템 전달 (성공 시 보상)
func fail_request(request_id: int) -> void          # 시간 초과 또는 실패 처리 → RequestRules 누적
```

### 2-1. DungeonFlow (하위 상태 머신, DungeonManager 소유)

```gdscript
func enter(state: StringName) -> void               # 전환 한 곳에서만 호출 (AD-5)
func on_battle_end() -> void                        # 다음 전투 또는 DUNGEON_CLEAR 로 전환
func tick_sleep(delta: float) -> bool               # 수면 시간 누적, 끝나면 true
```

### 2-2. RequestController (하위, DungeonManager 소유, AD-6)

```gdscript
func spawn_request(item_kind_id: StringName, seconds_limit: float) -> int   # 요청 ID 반환
func tick(delta: float) -> Array                    # 시간 경과, 만료된 request_id 목록 반환
func cancel(request_id: int) -> void
```

### 2-3. ShopFlow (하위, DungeonManager 소유)

```gdscript
func open(dungeon_no: int) -> void                  # 상점 단계 시작 (30초 수면 후)
func build_offer(dungeon_no: int) -> Array          # PurchaseRoller 호출, 구매 후보 목록
func close() -> void
```

## 3. ItemManager (autoload)

```gdscript
signal item_state_changed(item_id: int, state: StringName)
signal item_dropped(item_id: int, position: Vector2)   # 무게 초과 또는 맵 드롭
signal weight_rejected(facility_id: StringName, message: String)

func create_item(item_data: ItemData, stage_id: int, state: StringName) -> int
func spawn_into_input_space(item_ids: Array, rng: RandomNumberGenerator) -> void  # FR-31 무작위 입고
func pick_up(item_id: int, carrier_id: StringName) -> bool        # 줍기 (호버 후 클릭, 키보드 병행)
func drop_on_map(item_id: int, position: Vector2) -> void         # 패널 닫힘 상태에서 맵 드롭 (D-14)
func place_into_facility(item_id: int, facility_id: StringName) -> bool  # 무게 검사 후 적재
func move_to_output(item_id: int) -> bool                          # 판매 퀘스트 줄 아이템을 출력공간으로
func get_untidied_items(stage_id_max: int) -> Array                # 미정리 누적 목록 (FR-15)
func get_facility(facility_id: StringName) -> StorageFacility
```

### 3-1. WeightRules (순수)

```gdscript
static func total_weight(items: Array) -> float
static func can_add(current_total: float, add_weight: float, max_weight: float) -> bool
static func carry_speed_factor(weight: float, base_factor: float) -> float   # FR-08, 무거울수록 작음
```

### 3-2. PlacementRules (순수)

```gdscript
static func overlaps(rect_a: Rect2, rect_b: Rect2) -> bool
static func pick_random_free_slot(bounds: Rect2, occupied: Array, rng: RandomNumberGenerator, max_tries: int) -> Variant  # 실패 시 null
```

## 4. EconomyManager (autoload)

```gdscript
signal gold_changed(new_amount: int)
signal exp_changed(level: int, exp: int)
signal level_up(new_level: int)

func add_gold(amount: int) -> void                  # NFR-04: 골드 변경은 이 메서드로만
func spend_gold(amount: int) -> bool                # 잔액 부족이면 false (FR-19)
func sell_price(item_data: ItemData) -> int
func grant_exp(item_id: int, amount: int) -> bool   # 중복 지급 방지 (FR-10), 이미 지급되었으면 false
func draw_augment_choices(count: int, rng: RandomNumberGenerator) -> Array  # FR-11
func apply_augment(augment_id: StringName) -> void
func roll_purchase(dungeon_no: int, rng: RandomNumberGenerator) -> Array   # FR-18, 품목과 수량
func buy_facility_upgrade(facility_id: StringName) -> bool                 # FR-24
```

### 4-1. GoldLedger (순수)

```gdscript
var amount: int
func try_spend(cost: int) -> bool
func add(value: int) -> void
```

### 4-2. ExpCalculator (순수)

```gdscript
static func exp_for_item(item_data: ItemData, rarity_multiplier: float) -> int
static func exp_to_next_level(level: int) -> int
```

### 4-3. AugmentPool (순수)

```gdscript
static func draw_unique(pool: Array, count: int, taken: Array, rng: RandomNumberGenerator) -> Array  # 중복 제한
```

### 4-4. PurchaseRoller (순수)

```gdscript
static func roll(table: Dictionary, budget: int, rng: RandomNumberGenerator) -> Array   # [{item_kind_id, quantity}]
```

## 5. RequestRules (순수, DungeonManager 소유)

```gdscript
static func next_failure_count(current: int) -> int
static func is_game_over(failure_count: int, limit: int) -> bool   # limit = 3 (FR-21, 설정값)
```

## 6. SaveCodec (순수, GameManager 소유)

```gdscript
static func to_json(snapshot: Dictionary) -> String
static func from_json(text: String) -> Dictionary     # 파싱 실패 시 빈 Dictionary
static func sign(payload: String, key: PackedByteArray) -> String   # HMAC-SHA256 hex
static func verify(text: String, key: PackedByteArray) -> bool
```

## 7. 씬 노드 메서드 (요약)

| 노드 | 주요 메서드 | 설명 |
| --- | --- | --- |
| `Player` | `pick_up_nearby()`, `drop_carried(position)`, `set_carry_speed(factor)` | 줍기 · 드롭 · 무게 반영 속도 |
| `Item` | `set_hover(on: bool)`, `get_display_name()` | 호버 이름 표시 (F3) |
| `StorageFacility` | `open_panel()`, `close_panel()`, `current_weight()`, `max_weight()`, `slots()` | 선반 패널 열림 · 닫힘 (C1) |
| `InputSpace` | `receive(item_ids)` | 입력공간 입고 (FR-31, 무작위 위치는 ItemManager 가 계산) |
| `OutputSpace` | `receive(item_ids)`, `collect_for_sale() -> Array` | 출력공간 적재 · 판매 대상 수집 (FR-30) |
| `ItemListPanel` | `refresh(items)`, `on_drag_started(item_id)` | 목록 상시 표시 (FR-02) |
| `ShelfPanel` | `show_for(facility)`, `hide()` | 선반 패널 표시 · X 버튼 (FR-03) |
| `RequestPanel` | `show_request(request)`, `update_timer(seconds_left)` | 요청 표시 (FR-20) |
| `HUD` | `set_gold(v)`, `set_dungeon(no)`, `set_level(lv, exp)` | 상단 · 우측 정보 (FR-27) |
| `SaveTransferPanel` | `on_export_pressed()`, `on_import_file(text)` | 웹 내보내기 · 불러오기 (FR-26) |
