# U1 창고 · 조작 기능 설계 계획 (Functional Design Plan)

**unit**: U1 창고 · 조작 (Storage & Controls)
**기준**: `inception/application-design/unit-of-work.md` (U1 정의), `unit-of-work-story-map.md`, `user-stories/stories.md` (US-01 ~ US-08), `requirements/requirements.md` (FR-01 ~ FR-09, FR-29 조작 부분, FR-30 출력공간 이동, FR-31 배치 계산)

이 계획은 U1 의 비즈니스 규칙 중 명확하지 않은 부분을 정리한 것입니다. 각 질문의 `[Answer]:` 뒤에 선택지 문자를 적어 주세요. 맞는 선택지가 없으면 `X) Other` 를 고르고 내용을 함께 적어 주세요. 추천안이 있는 질문은 "추천" 으로 표시했습니다. 추천을 그대로 쓰면 "추천" 이라고 적어 주셔도 됩니다.

**생성 예정 산출물 (답변 후)**
- `aidlc-docs/construction/u1-storage-controls/functional-design/business-logic-model.md`
- `aidlc-docs/construction/u1-storage-controls/functional-design/business-rules.md`
- `aidlc-docs/construction/u1-storage-controls/functional-design/domain-entities.md`

---

## Question FD-U1-1: 무게 한도 경계값 판정
선반의 현재 무게 + 배치할 아이템 무게가 최대 무게와 **정확히 같을 때** 적재할까요?

A) 같으면 허용 (합계 ≤ 최대). 추천

B) 같으면 거부 (합계 < 최대)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question FD-U1-2: 한 번에 들 수 있는 아이템 수
플레이어가 한 번에 들 수 있는 아이템 수는 어떻게 할까요? (기획서 3.3: 기본 1개, 증강으로 늘릴 수 있음)

A) MVP 에서는 1개 고정. 증강 설계는 U2 에서 다룸. 추천

B) 처음부터 증강으로 늘릴 수 있는 값 (carry_capacity) 을 두고 기본값 1

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question FD-U1-3: 무게에 따른 이동 속도 공식
아이템 무게에 따라 이동 속도를 어떻게 줄일까요? (FR-08: 무거울수록 감소폭이 커짐)

A) 선형 감소: 속도 = 기본 속도 × (1 − 무게 ÷ 기준 무게 × 감소율). 감소율과 기준 무게는 설정값

B) 역수 감소: 속도 = 기본 속도 ÷ (1 + 무게 × 감소율). 가벼우면 거의 줄지 않음

C) 3단계 고정 배율: 경량 (×0.9), 중량 (×0.75), 고중량 (×0.5). 등급은 아이템 데이터에 둠. 추천

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question FD-U1-4: 바닥 아이템 줍기 거리
플레이어가 바닥 아이템을 주울 수 있는 거리는 어떻게 할까요? (US-05)

A) 플레이어 중심에서 48px 이내. 추천

B) 플레이어 중심에서 64px 이내

C) 아이템 이름 표시 (호버) 와 줍기 거리를 다르게 둠 (호버 64px, 줍기 48px)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question FD-U1-5: 바닥에 떨어진 아이템의 상태
무게 초과로 떨어진 아이템 (FR-07) 의 상태를 무엇으로 할까요? 현재 상태 목록은 `incoming`, `carried`, `stored`, `requested`, `sold`, `reserved` 입니다.

A) `incoming` 으로 두고 위치만 바닥 좌표로 바꿈. 추천 (상태 목록 변경 없음)

B) 새 상태 `dropped` 를 추가 (FR-09 상태 목록 변경)

C) `carried` 를 유지하고 손에서만 떨어뜨림

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question FD-U1-6: 맵 드롭 위치가 벽이나 시설과 겹칠 때
패널이 닫힌 상태에서 맵 드롭 (US-04) 하려는 위치가 벽이나 시설과 겹치면 어떻게 할까요?

A) 가장 가까운 빈 자리로 자동 보정해서 놓음. 추천

B) 드롭을 거부하고 아이템은 손에 그대로 둠

C) 드롭을 거부하고 아이템 상태를 `carried` 로 유지, 메시지 표시

X) Other (please describe after [Answer]: tag below)

[Answer]: X 무조건 케릭터 아래로 버려짐

---

## Question FD-U1-7: 선반 패널의 "3칸" 과 무게 한도의 관계
답변 Q8 에서 선반 패널에 "3칸" 이 보인다고 하셨습니다. 칸 수와 무게 한도를 어떻게 함께 쓸까요? (FR-06 은 무게 기준으로 정함)

A) 칸은 시각적 슬롯 3개. 칸마다 아이템 1개를 담고, 시설의 최대 무게 제한도 동시에 적용. 추천

B) 칸 수 없이 무게만 적용 (패널에는 칸 모양만 보여줌)

C) 칸 수는 시설 확장 (FR-24) 마다 늘어나고, 무게 한도와 함께 적용

X) Other (please describe after [Answer]: tag below)

[Answer]: 하나의 칸에 무게는 10으로 하고 회복약은 무게 1, 스크롤은 무게 1, 무기는 무게 3 이런식으로 계산하려고 했음.

**AI 해석 (사용자 확인 필요, FD-A1)**: 칸마다 무게 한도 10. 한 칸에 여러 아이템을 담을 수 있고, 칸 안 무게 합이 10을 넘으면 그 칸에는 적재할 수 없음. 시설의 최대 무게는 칸 수 × 10 (3칸이면 30). 회복약 1, 스크롤 1, 무기 3 은 아이템 무게 값.

---

## 추천안 채택 (사용자 "답변한 것 외에는 모두 추천대로" 응답)

- FD-U1-1: A (합계 ≤ 최대 이면 허용)
- FD-U1-2: A (1개 고정, 증강 설계는 U2 에서)
- FD-U1-3: C (3단계 배율 경량 ×0.9, 중량 ×0.75, 고중량 ×0.5)
- FD-U1-4: A (줍기 거리 48px)
- FD-U1-5: A (`incoming` 으로 두고 위치만 바닥 좌표로 변경)
- FD-U1-6: 사용자 답변 X (캐릭터 아래에 무조건 떨어짐). 벽 · 시설 겹침 보정은 하지 않음

## 확인 완료 (질문 없음)

- 적재 대상은 선반 (`StorageFacility`) 에 한정. 입력공간 · 출력공간 (`InputSpace`, `OutputSpace`) 도 같은 무게 규칙을 따름 (A-07)
- 상태 전환 규칙은 FR-09 의 6개 상태를 기준으로 함 (FD-U1-5 결과에 따라 달라질 수 있음)
- 줍기는 상호작용 키와 마우스 호버 클릭 두 방식 모두 가능 (D-16)
- 판매 요청 아이템은 출력공간으로만 이동 가능 (FR-30)
