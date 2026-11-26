# U3 던전 · 요청 화면 구성 (Frontend Components)

**unit**: U3 던전 · 요청
**기준**: `business-logic-model.md`, `business-rules.md`. 화면 세부 배치는 Code Generation 에서 정합니다.

## 컴포넌트 계층
- `BattleView` (전투 화면): 전투 번호 `k / N` 표시, 입고 연출
  - `RequestPanel` (요청 패널): 활성 요청의 대상 아이템 이름, 남은 시간 표시 (AC-15-1)
- `SleepOverlay` (수면 화면): 남은 초 (30 → 0) 표시, 정리 UI 는 기존 U1 화면 유지 (AC-13-1, AC-13-2)
- `GameOverScreen` (게임오버 화면): 실패 누적 수 `F / 3` 표시, 새 게임 버튼 (US-16 체크리스트)

## 상태와 props
| 컴포넌트 | props (입력) | 상태 (내부) |
| --- | --- | --- |
| BattleView | battle_index, battle_total, is_visible | 입고 연출 중 여부 |
| RequestPanel | target_name, remaining_sec, status | 없음 (표시 전용) |
| SleepOverlay | remaining_sec | 없음 |
| GameOverScreen | failure_count, limit | 없음 |

## 사용자 상호작용 흐름
1. 던전 시작 → BattleView 가 `1 / N` 표시
2. 요청 발생 → RequestPanel 이 열리고 남은 시간이 줄어듦
3. 전투 종료 → 입고 아이템이 목록에 추가됨 (다음 전투 또는 완료)
4. 던전 완료 → SleepOverlay 30초 → 상점 호출 (U4 로 넘김)
5. 실패 3회 → GameOverScreen

## 검증 규칙 (화면)
- RequestPanel 은 요청이 ACTIVE 일 때만 보인다.
- SleepOverlay 가 열린 동안 BattleView 와 RequestPanel 은 숨긴다 (BR-U3-12).

## API 연동 지점 (내부 서비스 호출)
- DungeonFlow → RequestController: 요청 생성 · 취소 · 판정
- RequestController → StorageService (U1): 후보 조회, reserved 전환 · 해제
- RequestController → EconomyManager (U2): 성공 보상 지급 (골드, EXP)
- DungeonFlow → GameOver: F 가 3 에 도달하면 GAME_OVER 신호
