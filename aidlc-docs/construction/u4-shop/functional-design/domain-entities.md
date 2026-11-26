# U4 상점 도메인 엔티티 (Domain Entities)

**unit**: U4 상점
**기준**: `business-rules.md` (BR-U4-01 ~ 14)

## 엔티티

### Shop (상점 1회 방문)
| 속성 | 설명 |
| --- | --- |
| visit_no | 방문 번호 (던전 완료 수와 같음) |
| state | CLOSED, SELL, BUY, DONE |
| sell_requests | 판매 요청 아이템 목록 (던전 1 = 2) |
| buy_count | 구매 추첨 개수 (던전 1 = 4) |

### SellRequest (판매 요청)
| 속성 | 설명 |
| --- | --- |
| item_instance_id | 요청된 아이템 |
| status | PENDING, SOLD |

### OutputSpace (출력공간)
| 속성 | 설명 |
| --- | --- |
| items | 올린 아이템 목록 (용량 제한 없음, BR-U4-12) |

### PurchaseItem (구매 품목)
| 속성 | 설명 |
| --- | --- |
| item_id | 상점 품목 종류 |
| price | 구매 비용 (데이터) |
| weight | 추첨 가중치 (데이터) |

## 데이터 테이블 (ShopTable, JSON)
| 필드 | 값 |
| --- | --- |
| sell_requests (던전 1) | 2 |
| buy_count (던전 1) | 4 |
| 품목 목록 | 무기 · 방어구 제외 (BR-U4-14), 회복약 · 주문서 · 광석 상자 등 기획서 9.2 후보 |
| 판매 보너스 | U2 증강 `sell` |

던전 2 이후 수치는 기획서 8.2 와 같은 방식으로 데이터만 추가합니다.
