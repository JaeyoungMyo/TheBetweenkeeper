# 배포 계획 (Deployment Plan) — 데스크톱 Windows, zip 직접 전달

**결정 (사용자 답변)**
- 대상 OS: Windows 만 (추천안)
- 배포 방식: zip 파일로 직접 전달 (추천안)
- 웹 빌드, itch.io, GitHub Release: 이번 범위 제외

## 배포 산출물
- `아공간관리인-windows.zip`
  - `아공간관리인.exe` (실행 파일)
  - `아공간관리인.pck` (게임 데이터, Windows 는 exe 옆에 있어야 함)
  - 필요 시 `.dll` (없으면 생략)

## 빌드 절차 (Godot 4.7.2 에디터, Windows PC)
1. Godot 에디터에서 프로젝트 열기 (`project.godot`)
2. 메뉴 **프로젝트 → 내보내기 (Export)**
3. 프리셋 추가 → **Windows Desktop**
4. 옵션
   - 내보내기 경로: `build/windows/아공간관리인.exe`
   - 렌더러: Compatibility (프로젝트 설정 그대로, NFR-08)
   - 콘솔 창 숨김: 켬 (릴리스용)
5. **내보내기 템플릿** 이 없으면 에디터가 설치를 안내하므로 그 안내를 따른다 (Godot 4.7.2 용)
6. 내보내기 실행 → `build/windows/` 생성
7. `build/windows` 폴더를 zip 으로 묶음 → `아공간관리인-windows.zip`

## 검증 체크리스트 (배포 전, Windows PC)
- [ ] exe 를 더블클릭하면 튜토리얼 화면이 뜬다
- [ ] 튜토리얼 완료 → 던전 1 자동 시작 (TEST.md 1 · 2 · 3 항목)
- [ ] F2 설정 패널, 전체 화면 전환이 동작한다
- [ ] 저장 파일 생성 (`%APPDATA%/Godot/app_userdata/아공간 관리인/save.dat`) 후 재실행 시 이어하기가 뜬다
- [ ] 다른 PC (또는 깨끗한 폴더) 에서 zip 을 풀어도 실행된다

## 알려진 제약
- Windows SmartScreen 이 서명 없는 exe 에 경고를 띄울 수 있다 ("추가 정보 → 실행").
- 코드 서명은 이번 범위에서 하지 않는다.
- 저장 키는 소스 상수 (개인용 수준, U5 가정 1).

## 다음 단계
- 빌드 · 검증은 Windows PC 에서 사람이 직접 한다 (AI 는 이 환경에서 Windows 빌드를 할 수 없음, 템플릿 · 실행 환경 없음).
- 빌드 후 zip 과 검증 결과를 알려 주면 `deployment-execution-summary.md` 를 작성한다.
