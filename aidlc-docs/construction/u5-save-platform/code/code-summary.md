# U5 저장 · 플랫폼 코드 요약

**계획**: `construction/plans/u5-save-platform-code-generation-plan.md`
**검증**: Godot 4.7.2 headless. `PBT seed=20261124 tests=74 failed=0`. 메인 씬 300 프레임 실행 오류 없음.

## 스토리별 파일

| 스토리 | 파일 | 테스트 |
| --- | --- | --- |
| SYS-01 던전 완료 시 자동 저장 | scripts/save/save_data.gd, autoload/save_service.gd, autoload/dungeon_manager.gd (`save_point("dungeon_clear")`), scripts/ui_dungeon/dungeon_ui.gd (`shop_clear`) | test_save_flow, test_save_properties |
| SYS-01 복원 | scripts/save/save_data.gd (restore), scripts/storage/storage_room.gd (restore_layout), scripts/storage/tutorial_storage.gd (이어하기 / 새 게임) | test_save_flow |
| 보호 (BR-U5-03~05) | scripts/save/save_codec.gd (HMAC-SHA256 서명, 파일은 open_encrypted_with_pass 로 암호화) | test_save_codec |
| BR-U5-07 게임오버 삭제 | scripts/ui_dungeon/dungeon_ui.gd (`_on_game_over`) | test_save_flow |
| SYS-04 화면 · 언어 설정 | scripts/ui/settings_panel.gd (F2, 전체 화면 전환, 한국어 표시). 해상도 1280x720 · keep 는 project.godot 기존 설정 | 수동 |

## 기존 파일 수정
- `project.godot`: `SaveService` 오토로드 등록
- `dungeon_manager.gd`: 던전 완료 저장 지점
- `dungeon_ui.gd`: 상점 완료 저장, 게임오버 삭제, 이어하기 진입점 (`resume_at_shop`, `resume_next_dungeon`)
- `storage_room.gd`: 선반 배치 캡처 · 복원, 설정 패널 생성
- `tutorial_storage.gd`: 튜토리얼 완료 플래그, 저장 있으면 이어하기 / 새 게임 선택
- `tests/run_tests.gd`: 테스트 전후 저장 파일 삭제 (튜토리얼이 이어하기 화면으로 가지 않도록)

## 한계 · 후속
- 웹 내보내기 · 불러오기 (SYS-02) 는 제외 (FD-U5-5 B). 웹 빌드 설정 · itch.io 업로드 (SYS-03) 는 빌드 단계.
- HMAC 키와 암호화 키는 소스 상수다. 개인용 수준 보호.
- 전체 화면 전환은 데스크톱에서 확실히 동작. 웹은 브라우저 정책을 따른다.
- 진행 중 퀘스트 · 판매 퀘스트는 저장하지 않는다 (BR-U5-06).
- 이어하기 화면 · 설정 패널의 실제 배치는 화면에서 확인 필요.
