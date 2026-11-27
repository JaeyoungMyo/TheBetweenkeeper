# U4 상점 도메인 엔티티 (Domain Entities) — 변경 반영본

## 엔티티
- **Shop**: visit_no, state (CLOSED, SELL_QUEST, BUY, DONE)
- **SellQuest**: 줄 (품목 × 필요 개수) 목록, 총 수량 (던전 1 = 12), 제한 시간 (120초), 보상 EXP (80) — U3 Quest 구조 재사용
- **OutputSpace**: 판매 대상으로 올린 아이템 목록 (용량 제한 없음)
- **PurchaseItem**: item_id, price, weight (추첨 가중치)

## 데이터 (ShopTable · sell 설정, JSON)
| 필드 | 던전 1 초기값 |
| --- | --- |
| sell_quantity | 12 |
| sell_time_limit_sec | 120 |
| sell_reward_exp | 80 |
| buy_count | 4 |
| sell_excluded_categories | 물약 |
| 품목 목록 | 무기 · 방어구 제외 (BR-U4-15) |
