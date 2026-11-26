# U3 던전 · 요청 화면 구성 (Frontend Components)

**unit**: U3 던전 · 요청
**기준**: `business-logic-model.md`, `business-rules.md`. 화면 세부 배치는 Code Generation 에서 정합니다.

## 컴포넌트 계층
- `BattleView` (전투 화면): 전투 번호 `k / N` 표시, 입고 연출
- `QuestPanel` (퀘스트 목록): 화면 어딘가에 고정 표시 (퀘스트 진행 중에만)
  - 줄마다 `품목명 (전달 수/필요 수)` 표시 (예: 회복약 (1/3), 해독제 (0/1))
  - 완료된 줄과 미완료 줄을 다르게 표시 (BR-U3-10): 완료 줄은 체크 표시와 흐린 글씨, 미완료 줄은 기본 글씨
  - 남은 시간 표시 (AC-15-1)
- `DeliverySpace` (전달 공간): 올라간 아이템 표시 (퀘스트와 별개로 보임)
- `SleepOverlay` (수면 화면): 남은 초 (30 → 0) 표시, 정리 UI 는 U1 화면 유지 (AC-13-1, AC-13-2)
- `GameOverScreen` (게임오버 화면): 실패 누적 `F / 3` 표시, 새 게임 버튼 (US-16 체크리스트)

## 상태와 props
| 컴포넌트 | props (입력) | 상태 (내부) |
| --- | --- | --- |
| BattleView | battle_index, battle_total | 입고 연출 중 여부 |
| QuestPanel | lines (kind, delivered, required, completed), remaining_sec, status | 없음 (표시 전용) |
| DeliverySpace | items | 없음 |
| SleepOverlay | remaining_sec | 없음 |
| GameOverScreen | failure_count, limit | 없음 |

## 사용자 상호작용 흐름
1. 던전 시작 → BattleView 가 `1 / N` 표시
2. 퀘스트 발생 → QuestPanel 에 줄 목록과 남은 시간 표시
3. 플레이어가 아이템을 전달 공간에 올림 → 같은 종류 줄의 전달 수가 1 올라감 (예: 회복약 0/3 → 1/3)
4. 줄이 필요 개수에 도달 → 그 줄이 완료 표시로 바뀜
5. 모든 줄 완료 → 퀘스트 성공, 필요 개수만큼 전달 공간에서 사라짐 (초과분 남음)
6. 시간 초과 → 퀘스트 실패, 전달 공간 아이템 그대로 남음
7. 던전 완료 → SleepOverlay 30초 → 상점 호출 (U4)
8. 실패 3회 → GameOverScreen

## 검증 규칙 (화면)
- QuestPanel 은 퀘스트가 진행 중일 때만 보인다.
- 줄 표시는 필요 개수를 넘지 않는다 (예: 4개 올려도 `3/3`).
- SleepOverlay 가 열린 동안 BattleView 와 QuestPanel 은 숨긴다 (BR-U3-20).

## API 연동 지점 (내부 서비스 호출)
- DungeonFlow → QuestController: 퀘스트 생성 · 판정
- QuestController → StorageService (U1): 후보 종류 조회
- QuestController → DeliverySpace: 아이템 올림 감지, 성공 시 필요 개수 삭제
- QuestController → EconomyManager (U2): 성공 보상 지급 (골드, EXP)
- DungeonFlow → GameOver: F 가 3 에 도달하면 GAME_OVER 신호
