# U1 창고 · 조작 도메인 엔티티 (Domain Entities)

**unit**: U1 창고 · 조작
**기준**: `business-logic-model.md`, `business-rules.md`, `inception/application-design/components.md`

## 1. 엔티티 목록

### ItemData (정의, 읽기 전용)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `item_id` | String | 아이템 종류 ID |
| `display_name` | String | 표시 이름 (한국어) |
| `category` | String | 카테고리 (무기, 물약, 재료 등) |
| `weight` | int | 무게 (1, 2, 3, 4, 6 중 하나) |
| `weight_class` | enum | 경량 (≤2) · 중량 (≤4) · 고중량 (>4), 분류 정보 (BR-U1-10) |
| `footprint` | Vector2 | 물리 충돌 크기 (적재 규칙에 사용하지 않음) |
| `base_price` | int | 판매가 (U4 에서 사용) |
| `exp_value` | int | 수납 EXP (U2 에서 사용) |
| `allowed_facilities` | Array[String] | 보관 가능한 시설 |

### ItemInstance (개체, 상태 보유)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `instance_id` | int | 고유 ID |
| `item_data` | ItemData | 종류 참조 |
| `stage_id` | int | 생성된 던전 번호 |
| `state` | enum | `incoming` · `carried` · `stored` · `requested` · `sold` · `reserved` |
| `world_position` | Vector2 | 바닥 또는 플레이어 손 좌표 |
| `facility_id` | String (nullable) | 배정된 시설 |
| `slot_index` | int (nullable) | 배정된 칸 번호 |
| `is_exp_claimed` | bool | EXP 지급 여부 (U2 에서 사용) |

### FacilityData (정의)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `facility_id` | String | 시설 ID |
| `display_name` | String | 표시 이름 |
| `slot_count` | int | 칸 수 (기본 3) |
| `slot_weight_limit` | int | 칸 무게 한도 (12, 고정) |
| `max_weight` | int (계산) | `slot_count × slot_weight_limit` = 3 × 12 = 36 (FD-A1) |
| `allowed_categories` | Array[String] | 허용 카테고리 |

### StorageFacility (씬 노드 상태, 런타임)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `data` | FacilityData | 정의 참조 |
| `slots` | Array[SlotState] | 칸 목록 (길이 = slot_count) |
| `current_weight` | float (계산) | 모든 칸 무게 합 |

### SlotState (런타임 값 객체)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `index` | int | 칸 번호 (0부터) |
| `item_ids` | Array[int] | 들어 있는 아이템 ID |
| `weight_sum` | float (계산) | 칸 안 무게 합 |

### PlayerCarry (런타임, Player 소유)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `carried_ids` | Array[int] | 운반 아이템 (최대 15, BR-U1-06) |
| `move_speed` | float | 기본 이동 속도 (무게와 무관, BR-U1-09). 배율 필드 없음 |

## 2. 관계

```text
FacilityData 1 ── 1 StorageFacility ── N SlotState ── N ItemInstance (item_ids 로 참조)
ItemData 1 ── N ItemInstance
PlayerCarry 0..1 ── 1 ItemInstance (held_item_id)
```

- 한 `ItemInstance` 는 `carried` 일 때 `PlayerCarry` 에, `stored` 일 때 `SlotState` 에 **정확히 하나만** 연결된다 (불변식)
- `ItemData` 의 값은 U1 에서 읽기만 한다. 변경은 데이터 파일 편집으로만 한다 (NFR-05)

## 3. 순수 클래스 (PBT 대상, AD-3)

| 클래스 | 입력 | 출력 | 관련 BR |
| --- | --- | --- | --- |
| `WeightRules` | 무게 목록, 한도 | 합계, 적재 가능 여부, 무게 등급 | BR-U1-01 ~ 03, 10, 11 |
| `PlacementRules` | 사각형 2개, 빈 자리 목록 | 겹침 여부, 빈 자리 | 겹침 검사 (기획서 3.4) |
| `SlotRules` (신규, U1 전용) | 칸 상태, 아이템 무게 | 칸 적재 가능, 배정 결과 | BR-U1-01, 12, 13 |
