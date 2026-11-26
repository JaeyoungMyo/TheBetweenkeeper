# U3 던전 · 요청 도메인 엔티티 (Domain Entities)

**unit**: U3 던전 · 요청
**기준**: `business-rules.md` (BR-U3-01 ~ 16), `business-logic-model.md`

## 엔티티

### Dungeon (던전 1회 진행)
| 속성 | 타입 (개념) | 설명 |
| --- | --- | --- |
| dungeon_no | 정수 | 던전 번호 (1부터) |
| battle_total | 정수 | 전투 횟수 N (3~5, 시작 시 확정) |
| battle_index | 정수 | 현재 전투 번호 (0 = 시작 전) |
| new_item_total | 정수 | 던전 신규 아이템 총량 T (데이터) |
| request_total | 정수 | 요청 수 R (데이터, 던전 1 = 1) |
| requests_spawned | 정수 | 이미 발생시킨 요청 수 |
| state | 열거 | READY, IN_BATTLE, DUNGEON_COMPLETE, SLEEP, SHOP_HANDOFF, GAME_OVER |

관계: Dungeon 1 : N Battle, Dungeon 1 : R Request.

### Battle (전투)
| 속성 | 설명 |
| --- | --- |
| index | 1 ~ N |
| intake_count | 이 전투의 입고 수 (균등 배분, 마지막 전투는 나머지 포함) |
| request_spawn_point | 이 전투 안에서 요청이 생길 무작위 시점 (요청이 있을 때만) |

### Request (긴급 요청)
| 속성 | 설명 |
| --- | --- |
| request_id | 식별자 |
| target_item_ids | 요청 대상 아이템 목록 (수량 Q, 2~10) |
| quantity | Q (데이터, 던전 난이도에 따라 증가) |
| delivered_count | 전달 공간에 옮겨진 개수 (0 ~ Q) |
| time_limit_sec | 제한 시간 (기본 30) |
| remaining_sec | 남은 시간 |
| reward_gold / reward_exp | 성공 보상 (데이터) |
| status | PENDING, ACTIVE, SUCCESS (전달 아이템 삭제), FAILED, (생성 안 됨 = 후보 없음) |

### FailureCounter (실패 누적)
| 속성 | 설명 |
| --- | --- |
| count | 0 ~ 3, 요청 종류와 무관 |
| limit | 3 (BR-U3-11) |

### 아이템 상태 전이 (U3 가 쓰는 부분, 기획서 4.3)
- `incoming` → `reserved` (요청 ACTIVE 시작)
- `reserved` → 요청 전 상태 (`incoming` 또는 `stored`) (요청 FAILED)
- 전달 공간에 옮긴 아이템 → 삭제 (요청 SUCCESS, BR-U3-18)

## 데이터 테이블 (DungeonTable, JSON)
| 필드 | 던전 1 값 (기획서 8.2) |
| --- | --- |
| new_item_total (T) | 10 |
| kind_count | 3 |
| request_total (R) | 1 |
| request_quantity (Q) | 2 (범위 2~10, 던전 난이도에 따라 증가) |
| battle_range | 3 ~ 5 |
| sleep_sec | 30 |
| request_time_limit_sec | 30 (설정값) |
| request_reward | 골드, EXP (값 미정, 데이터에서 지정) |

던전 2 이후 값은 기획서 8.2 표를 그대로 넣는 것으로 U3 범위에 둡니다 (데이터만, 로직 변경 없음).
