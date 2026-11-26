# U4 상점 기능 설계 계획 (Functional Design Plan)

**unit**: U4 상점 (Shop)
**기준**: `inception/application-design/unit-of-work.md` (U4 정의, UG-5 A), `unit-of-work-story-map.md`, `user-stories/stories.md` (US-18 ~ US-21, US-22 는 U2 에서 구현됨), `requirements/requirements.md` (FR-16, FR-17, FR-18, FR-19, FR-30, FR-31, D-18, A-07), 기획서 9.1 ~ 9.5 절
**의존**: U1 (ItemManager, 선반 · 입력 · 출력 공간 개념), U2 (EconomyManager 판매 · 구매 골드), U3 (던전 완료 신호, `DungeonManager.flow.state == SHOP_HANDOFF`)
**범위 밖**: 대량 상자 열기 연출 (상점 연출 후순위, 아래 질문 참고), 무기 · 방어구 구매 (FR-18 POC 제외)

이 계획은 U4 에서 명확하지 않은 규칙을 정리한 것입니다. 각 질문의 `[Answer]:` 뒤에 선택지 문자를 적어 주세요. 추천안은 "추천" 으로 표시했습니다. 추천을 그대로 쓰면 "추천 전부" 라고 적어 주셔도 됩니다.

**생성 예정 산출물 (답변 후)**
- `aidlc-docs/construction/u4-shop/functional-design/business-logic-model.md`
- `aidlc-docs/construction/u4-shop/functional-design/business-rules.md`
- `aidlc-docs/construction/u4-shop/functional-design/domain-entities.md`
- `aidlc-docs/construction/u4-shop/functional-design/frontend-components.md`

---

## 아직 열려 있는 항목 (미결)
- **P-02 / A-07**: 입력공간 · 출력공간의 위치, 용량, 시설 형태 (Q-U4-1, Q-U4-2)
- **V-3 (UG-5 A 로 해소)**: 입력공간이 가득 찬 상태의 구매 처리. 이 계획은 "구매 전에 여유를 확인해 막는다" 를 전제로 한다.

---

## Question FD-U4-1: 입력공간 (구매품이 쌓이는 곳)
입력공간의 형태와 용량을 어떻게 할까요? (P-02, A-07, FR-31)

A) 창고 방 안에 고정 위치 한 곳, 칸 단위가 아니라 **총 무게 한도** 로 용량 관리. 추천

B) 선반처럼 칸 여러 개로 나누고, 칸마다 무게 한도 (12) 적용

C) 입력공간 개념 없이 구매품을 바로 바닥에 무작위로 떨어뜨림 (용량 제한 없음)

X) Other (please describe after [Answer]: tag below)

[Answer]: C (입력공간 개념 없음, 구매품은 맵에 무작위로 떨어짐)

---

## Question FD-U4-2: 출력공간 (판매할 아이템을 모으는 곳)
출력공간의 형태와 용량을 어떻게 할까요? (P-02, A-07, FR-30)

A) 전달 선반과 같은 방식: 창고 방 안 고정 위치 한 곳, 아이템을 하나씩 넣는다. 용량 제한 없음 (요청 수 만큼만 들어감). 추천

B) 칸 여러 개 (선반처럼), 칸마다 무게 한도 적용

X) Other (please describe after [Answer]: tag below)

[Answer]: A (출력공간 = 전달 선반과 같은 방식, 아이템을 하나씩 넣음)

---

## Question FD-U4-3: 판매 요청 아이템 목록 (US-19 AC-19-1)
용사가 판매를 요청하는 아이템은 어떻게 정할까요?

A) 상점이 열릴 때 창고 (선반 · 바닥 · 들고 있는 것) 의 아이템 중에서 무작위로 정함. 개수는 던전 데이터 (던전 1 = 2개). 추천

B) 창고 아이템 중 가장 무거운 것부터 정함

C) 방문마다 판매 요청 목록을 고정 종류로 정함 (예: 회복약 1개)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (창고 아이템 중 무작위, 던전 1 = 2개)

---

## Question FD-U4-4: 판매가 (US-19 AC-19-2, 체크리스트 "판매가가 아이템마다 다르다")
판매가는 어떻게 정할까요?

A) 현재 U2 규칙 그대로 사용 (무게 × 10, 판매가 보너스 증강 적용). 추천

B) 아이템마다 데이터에 판매가를 적음 (`base_price`), 없으면 무게 × 10

X) Other (please describe after [Answer]: tag below)

[Answer]: A (현재 U2 판매가 규칙 사용). 향후 B (아이템별 판매가) 로 바꿀 예정

---

## Question FD-U4-5: 판매 확정 시 요청 외 아이템 (US-19 AC-19-3)
출력공간에 요청되지 않은 아이템이 있으면 어떻게 할까요?

A) 판매되지 않고 출력공간에 그대로 남는다. 다음 방문 전까지 플레이어가 꺼낸다 (창고로 되돌림). 추천

B) 판매 확정 때 요청 외 아이템을 창고로 자동 되돌린다

X) Other (please describe after [Answer]: tag below)

[Answer]: X (요청 외 아이템은 맵 어딘가로 자동 이동. 입력공간과 동일 방식)

---

## Question FD-U4-6: 구매 품목 추첨 (FR-18, US-20 AC-20-3)
구매 품목과 수량은 어떻게 정할까요?

A) 상점 데이터의 품목 목록에 가중치를 두고, 방문마다 정해진 개수 (던전 1 = 4개) 를 가중치로 뽑는다. 같은 품목이 여러 번 나올 수 있다. 추천

B) 가중치로 품목을 정하고, 수량은 품목마다 범위 (예: 1~3) 에서 무작위

C) 품목은 고정 목록, 플레이어 골드 한도 안에서 가능한 만큼 구매

X) Other (please describe after [Answer]: tag below)

[Answer]: A (가중치 품목 목록에서 방문마다 정해진 개수 뽑기)

---

## Question FD-U4-7: 구매 비용과 골드 부족 (US-21)
구매 비용은 어떻게 차감하고, 골드가 부족하면 어떻게 할까요?

A) 품목 하나씩 비용이 있고, 구매 목록 전체의 합계를 확정 시 한 번에 차감. 합계가 골드보다 크면 방문 전체가 실패 (골드와 아이템 변화 없음). 추천

B) 품목을 뽑을 때마다 차감. 부족하면 그 품목만 건너뜀

X) Other (please describe after [Answer]: tag below)

[Answer]: B (품목을 뽑을 때마다 차감, 골드가 부족하면 그 품목만 건너뜀)

---

## Question FD-U4-8: 입력공간이 가득 찼을 때 구매 (UG-5 A)
입력공간에 구매품을 넣을 여유가 부족하면 어떻게 할까요?

A) 구매 확정 전에 구매품 수량 전체를 넣을 여유를 확인하고, 부족하면 구매를 막고 메시지를 띄운다. 골드는 차감하지 않는다. 추천

B) 여유만큼만 사고, 나머지는 골드를 돌려준다

X) Other (please describe after [Answer]: tag below)

[Answer]: X (입력공간은 없음. 구매품은 맵에 무작위로 떨어짐)

---

## Question FD-U4-9: 구매품과 다음 던전 신규 아이템의 관계 (D-18)
다음 던전의 신규 아이템 (U3 입고) 은 어디서 나오게 할까요?

A) 상점 구매품 = 다음 던전의 신규 아이템. 던전 입고 신호를 받아 구매품을 입력공간에 넣는다. 추천 (U3 의 무작위 입고는 대체)

B) 던전 입고는 그대로 무작위 생성, 상점 구매품은 별도 추가 (두 경로)

X) Other (please describe after [Answer]: tag below)

[Answer]: B (던전 입고는 무작위 생성, 상점 구매품은 별도 경로. 향후 던전 스타일 · 난이도별 드롭 테이블로 변경 예정)

---

## Question FD-U4-10: 대량 상자 (9.3 mix, FR-17)
대량 상자 구매품 (상자 한 개를 열면 같은 종류가 쏟아짐) 을 이번 범위에 넣을까요?

A) 이번 U4 에서는 제외. 개별 아이템 구매만 구현하고, 상자는 후속 작업으로 남김. 추천

B) 포함. 상자 1개 (내부 품목 · 개수 요약 표시) 를 입력공간에 넣고, 열면 개별 인스턴스로 쏟아짐

X) Other (please describe after [Answer]: tag below)

[Answer]: A (상자 개념 없음. 대량 상자 구매품은 만들지 않음)

---

## Question FD-U4-11: 상점 화면 방식 (ShopView, 9.4 연출)
상점 화면은 어떤 형태로 할까요?

A) 기능 중심: 판매 요청 목록 · 구매 목록 · 골드 · 확정 버튼이 있는 패널. 연출은 후순위. 추천

B) 장면 중심: 용사가 들어오는 짧은 연출 뒤 패널 표시

X) Other (please describe after [Answer]: tag below)

[Answer]: A (기능 중심 패널, 연출은 후순위)

---

## 답변 기록
댓글로 받은 답변을 위와 같이 옮겼습니다. Q5 는 "맵 어딘가로 자동 이동", Q4 는 "현재 규칙 → 향후 아이템별 판매가" 로 해석했습니다.
