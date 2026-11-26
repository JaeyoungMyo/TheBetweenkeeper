# U3 던전 · 요청 도메인 엔티티 (Domain Entities)

**unit**: U3 던전 · 요청
**기준**: `business-rules.md` (BR-U3-01 ~ 24), `business-logic-model.md`

## 엔티티

### Dungeon (던전 1회 진행)
| 속성 | 타입 (개념) | 설명 |
| --- | --- | --- |
| dungeon_no | 정수 | 던전 번호 (1부터) |
| battle_total | 정수 | 전투 횟수 N (3~5, 시작 시 확정) |
| battle_index | 정수 | 현재 전투 번호 (0 = 시작 전) |
| new_item_total | 정수 | 신규 아이템 총량 T (데이터) |
| quest_total | 정수 | 퀘스트 수 R (데이터, 던전 1 = 1) |
| quests_spawned | 정수 | 발생시킨 퀘스트 수 |
| state | 열거 | READY, IN_BATTLE, DUNGEON_COMPLETE, SLEEP, SHOP_HANDOFF, GAME_OVER |

### Battle (전투)
| 속성 | 설명 |
| --- | --- |
| index | 1 ~ N |
| intake_count | 이 전투의 입고 수 (균등 배분, 마지막 전투는 나머지 포함) |

### Quest (긴급 요청, 퀘스트)
| 속성 | 설명 |
| --- | --- |
| quest_id | 식별자 |
| lines | QuestLine 목록 (1~3 줄) |
| total_quantity | Q = 모든 줄의 required 합 (2~10) |
| time_limit_sec | 제한 시간 (기본 30) |
| remaining_sec | 남은 시간 |
| reward_gold / reward_exp | 성공 보상 (데이터) |
| status | PENDING, ACTIVE, SUCCESS, FAILED |

### QuestLine (퀘스트 줄)
| 속성 | 설명 |
| --- | --- |
| item_kind | 아이템 종류 (예: 회복약, 해독제) |
| required | 필요 개수 (1 이상) |
| delivered | 전달 수 (0 ~ required, 넘지 않음) |
| completed | delivered = required 이면 true (BR-U3-10) |

### DeliverySpace (전달 공간)
| 속성 | 설명 |
| --- | --- |
| items | 올려진 아이템 목록. 성공 전에는 삭제되지 않음 |

- 실패 시 items 는 그대로 남고, 다음 퀘스트에서 다시 셉니다 (BR-U3-13, BR-U3-15).
- 성공 시 줄마다 required 개수만큼만 items 에서 삭제합니다 (BR-U3-12).

### FailureCounter (실패 누적)
| 속성 | 설명 |
| --- | --- |
| count | 0 ~ 3, 퀘스트 종류와 무관 |
| limit | 3 (BR-U3-17) |

### 아이템 상태 (U3 가 쓰는 부분, 기획서 4.3)
- `incoming` → 전달 공간에 올림: 판매 불가 (BR-U3-23). 상태 이름은 U1 상태 모델과 맞춰 정합니다.
- 전달 공간에서 성공 삭제 → 아이템 없음 (`sold` 와 구분, 판매 수입 없음)

## 데이터 테이블 (DungeonTable, JSON)
| 필드 | 던전 1 초기값 (기획서 8.2 + 가정) |
| --- | --- |
| new_item_total (T) | 10 |
| battle_range | 3 ~ 5 |
| quest_total (R) | 1 |
| quest_total_quantity (Q) | 2 (줄 1~2 개, 가정 — 사용자 확인 필요) |
| line_count | 1 ~ 2 (던전 1), 1 ~ 3 (이후) |
| sleep_sec | 30 |
| quest_time_limit_sec | 30 (설정값) |
| quest_reward | 골드, EXP (데이터에서 지정) |

던전 2 이후 값은 기획서 8.2 와 던전 난이도에 맞춰 데이터만 추가합니다 (Q 는 2~10, BR-U3-18).
