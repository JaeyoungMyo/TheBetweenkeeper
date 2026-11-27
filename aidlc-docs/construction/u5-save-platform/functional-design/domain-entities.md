# U5 저장 · 플랫폼 도메인 엔티티

- **SaveData**: 버전, 던전 번호, 완료 횟수, 상점 방문 횟수, 골드, 레벨, EXP, 증강, 능력치, 튜토리얼 완료 여부, 실패 횟수, 아이템 목록, 선반 목록, 저장 지점 (dungeon_clear | shop_clear)
- **SavedItem**: instance_id, item_id, stage_id, 상태 (incoming · carried · stored · sold · delivered 중 저장 대상), 위치, 시설 ID, 칸 번호, EXP 지급 여부
- **SavedFacility**: facility_id, 종류, 위치, 칸 수 (칸 한도는 종류 데이터)
- **SaveEnvelope**: payload (암호화된 JSON 문자열), signature (HMAC-SHA256)

## 저장 대상 제외
- 진행 중 퀘스트 · 판매 퀘스트 (BR-U5-06)
- 전투 타이머 · 수면 남은 시간 (복원 지점이 던전 완료 · 상점 완료이므로 불필요)
