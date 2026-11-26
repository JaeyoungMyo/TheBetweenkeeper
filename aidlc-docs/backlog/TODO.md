# 나중에 할 일 (Backlog)

## 배포
- [ ] Windows PC 에서 Godot 4.7.2 로 Windows Desktop 프리셋 내보내기 → `아공간관리인-windows.zip` 만들기 (`operations/deployment/deployment-plan.md` 참고)
- [ ] 배포 전 검증 체크리스트 수행 후 `deployment-execution-summary.md` 작성

## 수동 테스트
- [ ] `TEST.md` 항목을 집에서 확인하고 문제는 번호와 함께 기록

## 커버리지
- [ ] PC 에서 커버리지 측정 (기준 80%) — `construction/build-and-test/coverage-hold.md` 참고

## 성능
- [ ] 기준 PC 사양 결정 후 NFR-01 (60 FPS) 측정 — `construction/build-and-test/performance-test-instructions.md` 참고

## 기능 (후속)
- [ ] 직업 도입 후 판매 규칙 변경 (자기 장비가 아닌 장비 전부 판매, BR-U4-08)
- [ ] 판매가 아이템별 `base_price` 로 변경 (BR-U4-09)
- [ ] 던전 2 이후 밸런스 값 조정 (퀘스트 · 판매 수량, 제한 시간, 입고 개수)
- [ ] 대량 상자 구매품 (제외됨, 필요 시 재검토)
- [ ] 영어 번역 (FR-28, MVP 이후)
- [ ] 웹 빌드 · itch.io 배포 (데스크톱 이후)
- [ ] 주문서 · 광석 상자 아이콘 칸 확인 (`data/items/*.tres` 의 `icon_cell`)
- [ ] 선반 아이템을 전달 선반으로 바로 옮기는 기능 (의도적으로 제외, 필요 시 재검토)

## 확인 필요 (가정)
- [ ] 판매 대상에서 물약 제외가 맞는지 (U4 가정)
- [ ] 구매 품목 가격 · 가중치 (회복약 30/5, 주문서 50/3, 광석 상자 120/2)
