# 스토리 → unit 매핑 (Unit of Work Story Map)

**기준**: `user-stories/stories.md` (스토리 26개), `application-design/unit-of-work.md`

## 1. 스토리별 unit 배정

| 스토리 | 제목 | 주 unit | 보조 unit | 관련 FR |
| --- | --- | --- | --- | --- |
| US-01 | 신규 플레이어 튜토리얼 | U1 | U2 | FR-02, FR-03, FR-29 |
| US-02 | 아이템 목록을 항상 보며 정리 | U1 | - | FR-02 |
| US-03 | 선반에 아이템 적재 | U1 | - | FR-03, D-14 |
| US-04 | 맵에 아이템 버리기 | U1 | - | FR-04, D-14 |
| US-05 | 바닥 아이템 줍기 | U1 | - | FR-05, D-16 |
| US-06 | 무게 초과 시 낙하 | U1 | - | FR-06, FR-07, D-09 |
| US-07 | 무거운 아이템 이동 | U1 | - | FR-08 |
| US-08 | 벽과 시설에 막히는 이동 | U1 | - | FR-01 |
| US-09 | 수납으로 EXP 얻기 | U2 | U1 | FR-10 |
| US-10 | 레벨업 증강 선택 | U2 | - | FR-11 |
| US-11 | 던전 전투 진행 | U3 | - | FR-12, D-04 |
| US-12 | 던전 완료 판정 | U3 | - | FR-13, D-15 |
| US-13 | 30초 수면 중 정리 | U3 | U1 | FR-14, D-15 |
| US-14 | 미정리 아이템 누적 | U3 | U1 | FR-15, D-15 |
| US-15 | 용사 긴급 요청 대응 | U3 | U2 | FR-20, FR-22 |
| US-16 | 요청 실패 누적과 게임오버 | U3 | - | FR-21, D-06 |
| US-17 | 요청 중 아이템 보호 | U3 | U1 | FR-23, D-14 |
| US-18 | 던전 완료 후 상점 방문 | U4 | U3 | FR-16, FR-17, D-18 |
| US-19 | 판매 요청에 응하기 | U4 | U1 | FR-30, FR-23 |
| US-20 | 구매품 입력공간에 받기 | U4 | U1 | FR-18, FR-31, D-18 |
| US-21 | 골드 부족 시 구매 실패 | U4 | U2 | FR-19 |
| US-22 | 시설 구매와 확장 | U2 | U1 | FR-24 |
| SYS-01 | 던전 완료 시 자동 저장 | U5 | U3 | FR-25, NFR-03 |
| SYS-02 | 웹 세이브 내보내기 · 불러오기 | U5 | - | FR-26, D-03 |
| SYS-03 | 웹 배포 | U5 | - | NFR-06, NFR-07, NFR-08 |
| SYS-04 | 화면과 언어 설정 | U5 | - | FR-27, FR-28, D-10, D-11 |

## 2. unit 별 스토리 목록 (요약)

| unit | 주 스토리 | 개수 |
| --- | --- | --- |
| U1 창고 · 조작 | US-01, US-02, US-03, US-04, US-05, US-06, US-07, US-08 | 8 |
| U2 성장 · 경제 | US-09, US-10, US-22 | 3 |
| U3 던전 · 요청 | US-11, US-12, US-13, US-14, US-15, US-16, US-17 | 7 |
| U4 상점 | US-18, US-19, US-20, US-21 | 4 |
| U5 저장 · 플랫폼 | SYS-01, SYS-02, SYS-03, SYS-04 | 4 |
| **합계** | | **26** |

## 3. FR 커버리지 점검

| FR | 담당 unit | 스토리 |
| --- | --- | --- |
| FR-01 | U1 | US-08 |
| FR-02 | U1 | US-01, US-02 |
| FR-03 | U1 | US-01, US-03 |
| FR-04 | U1 | US-04 |
| FR-05 | U1 | US-05 |
| FR-06 | U1 | US-06 |
| FR-07 | U1 | US-06 |
| FR-08 | U1 | US-07 |
| FR-09 | U1 | (상태는 US-02 ~ US-06 전체에서 검증) |
| FR-10 | U2 | US-09 |
| FR-11 | U2 | US-10 |
| FR-12 | U3 | US-11 |
| FR-13 | U3 | US-12 |
| FR-14 | U3 | US-13 |
| FR-15 | U3 | US-14 |
| FR-16 | U4 | US-18 |
| FR-17 | U4 | US-18 |
| FR-18 | U4 | US-20 |
| FR-19 | U4 | US-21 |
| FR-20 | U3 | US-15 |
| FR-21 | U3 | US-16 |
| FR-22 | U3 | US-15 |
| FR-23 | U3 | US-17 |
| FR-24 | U2 | US-22 |
| FR-25 | U5 | SYS-01 |
| FR-26 | U5 | SYS-02 |
| FR-27 | U5 | SYS-04 |
| FR-28 | U5 | SYS-04 |
| FR-29 | U1 | US-01 |
| FR-30 | U4 | US-19 |
| FR-31 | U4 | US-20 |

**결과**: FR-01 ~ FR-31 모두 하나의 주 unit 에 배정되어 있다. FR-09 는 스토리가 직접 다루지 않고 US-02 ~ US-06 의 인수 조건으로 검증한다 (스토리 보완 필요 여부는 승인 단계에서 확인).

## 4. NFR 연결

| NFR | 담당 unit | 검증 방법 |
| --- | --- | --- |
| NFR-01 (60 FPS) | 전체 | Performance Validation |
| NFR-02 (웹 로딩) | U5 | Performance Validation |
| NFR-03 (저장 무결성) | U5 | SYS-01 AC 3, 10회 왕복 테스트 |
| NFR-04 (골드 단일 원본) | U2 | 코드 검사 (직접 대입 0건) |
| NFR-05 (데이터 분리) | U1 | ItemData 와 ItemInstance 분리 확인 |
| NFR-06 (itch.io zip) | U5 | SYS-03 AC 1 |
| NFR-07 (스레드 미사용) | U5 | SYS-03 AC 2 |
| NFR-08 (Compatibility) | U5 | SYS-03 AC 2 |
| NFR-09 (PBT) | 각 unit | unit 별 tests/unit/ (unit-of-work.md 4절) |
