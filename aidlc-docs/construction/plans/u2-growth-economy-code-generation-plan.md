# U2 성장 · 경제 코드 생성 계획

**기준**: unit-of-work.md (U2), stories.md (US-09, US-10, US-22), FR-10, 11, 19, 23, 24, D-20, NFR-04, NFR-09
**의존**: U1 (ItemManager, FacilityState). Functional Design 은 생략 (UG-4 A) 이므로 규칙을 이 계획에 적는다.
**범위 밖**: 상점 방문 흐름과 구매 품목 추첨 (U4), 저장 (U5)

## 제안 수치 (모두 데이터 파일에서 조정 가능)

| 항목 | 제안 |
| --- | --- |
| 수납 EXP | 무게 × 5, 아이템마다 최초 1회 (FR-10) |
| 다음 레벨 필요 EXP | 50 + 25 × (레벨 - 1). 남은 EXP 는 이월 |
| 시작 골드 | 100 (튜토리얼 확인용) |
| 판매가 | 무게 × 10 (아이템별 데이터로 변경 가능) |
| 가방 확장 (1 → 5) | 100, 200, 400, 800 골드 |
| 선반 추가 구매 (3칸, 최대 36) | 150 골드, 최대 4개 |
| 선반 칸 추가 (3 → 6칸, 칸당 12) | 100, 200, 300 골드 |

## 증강 (레벨업마다 후보 3개 중 1개, 한 화면 중복 없음, 최대치 도달 시 제외)

| 증강 | 효과 | 최대 |
| --- | --- | --- |
| 운반 배수 | 2배만 등장, 보유하면 3배만 등장, 이후 등장 안 함 (D-20) | 2회 |
| 이동 속도 | +10% | 5회 |
| EXP 보너스 | +20% | 5회 |
| 판매가 보너스 | +10% | 5회 |

무게와 무관한 속도 (D-19) 는 유지한다. 기획서의 정리 전문가, 자동 정렬, 순간 이동 보관, 요청 탐색 보조는 이후로 미룬다. 모두 최대치면 선택 화면을 건너뛴다.

## 질문

### Question U2-1
시설 구매 · 확장은 언제 할 수 있을까요?

A) 언제든지 메뉴 (C 키) 에서 구매. 추천

B) 상점 방문 (U4) 때만 구매

X) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question U2-2
선반 확장 방식은 무엇으로 할까요?

A) 선반 추가 구매와 칸 추가 둘 다. 추천

B) 선반 추가 구매만

C) 칸 추가만

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## 단계

- [x] Step 1: 순수 규칙 `scripts/economy/gold_ledger.gd`, `scripts/growth/exp_calculator.gd`, `scripts/growth/augment_pool.gd` (FR-10, 11, 19, NFR-04)
- [x] Step 2: 데이터 `data/augments/augments.json`, `data/economy/economy.json`
- [x] Step 3: `autoload/economy_manager.gd`. 골드 증감, EXP, 레벨업, 판매, 구매, 증강 적용 (US-09, US-10, US-22)
- [x] Step 4: U1 연결. 수납 시 EXP 지급, `SOLD` 상태 추가, 선반 여러 개와 칸 추가 지원 (FR-23, 24)
- [x] Step 5: UI. 골드 · 레벨 · EXP 표시, 증강 선택 (게임 일시정지), 시설 구매 메뉴. 숫자 키는 4~6칸까지 확장
- [x] Step 6: 예시 테스트 (US-09, US-10, US-22 인수 조건) 와 PBT
- [x] Step 7: 튜토리얼 통합 테스트, code-summary.md, 상태 · 감사 기록

## 테스트 가능한 속성 (PBT-01)

| 대상 | 속성 | 분류 |
| --- | --- | --- |
| GoldLedger | 잔액 ≥ 0, 실패 시 잔액 불변, 무작위 명령이 모델과 일치 | 불변 조건, 상태 기반 |
| ExpCalculator | EXP 를 나눠 주어도 한 번에 주어도 결과가 같음, 남은 EXP < 필요 EXP | 교환 법칙, 불변 조건 |
| AugmentPool | 중복 없음, 최대치 증강 제외, 개수 ≤ 3 | 불변 조건 |
| 수납 EXP | 같은 아이템을 반복 수납해도 총 EXP 동일 | 멱등성 |
