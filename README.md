# KeyBox

macOS에서 API 키·토큰·비밀번호를 로컬로만 보관하는 시크릿 매니저.

## 왜 만들었나

개발하다 보면 API 키가 `.env`, 메모장, 클립보드, 슬랙 DM에 흩어진다. 클라우드
볼트를 쓰자니 계정과 구독이 필요하고, 내 키가 남의 서버에 올라간다. KeyBox는
반대로 간다 — **모든 것이 이 Mac 안에서 끝난다.** 네트워크 권한 자체가 없고,
데이터베이스 파일은 통째로 암호화되며, 마스터 비밀번호는 어디에도 저장되지 않는다.

## 어떻게 지키나

- **DB 전체 암호화** — SQLCipher(AES-256). 파일을 훔쳐가도 비밀번호 없이는
  `file is not a database` 에러만 본다.
- **키 계층** — 마스터 비밀번호 → PBKDF2(600k회) → HKDF로 DB 키와 랩핑 키를
  도메인 분리. 비밀번호를 바꾸면 전체 재암호화(rewrap+rekey)한다.
- **레코드 바인딩** — 각 시크릿 값은 자기 행 id·버전에 GCM AAD로 묶인다.
  백업에서 옛 암호문을 슬쩍 되돌려 넣으면 복호화가 거부된다(롤백 방어).
- **메모리 원칙** — 마스터 키는 잠금 해제 동안만 메모리에 있고, 잠그면 0으로
  덮어쓴다. 복호화 값은 로그에 찍지 않는다. 클립보드는 30초 뒤 비운다.
- **백업도 암호화** — 내보내기 아카이브는 값뿐 아니라 이름·메모 같은
  메타데이터까지 암호화한다(포맷 v3).

위협 경로별 방어·수용 판정은 [docs/security-threat-model.md](docs/security-threat-model.md)에 33개 경로로 정리했다.

## 시작하기

요구사항: macOS, Flutter 3.41+, CocoaPods.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift 코드 생성 (필수)
flutter run -d macos
```

실사용(dogfood)은 스크립트로:

```bash
scripts/dogfood.sh release   # HEAD 빌드 → 기존 앱 종료 → 재기동
```

빌드 없이 `open`으로 옛 .app을 띄우면 소스와 다른 바이너리를 테스트하게 된다 —
이 스크립트가 그 사고를 막는다.

## 테스트

```bash
flutter test                                  # 단위 + 위젯 (496건)
flutter test integration_test/<파일> -d macos  # cipher 실증 (파일당 1회 호출)
```

솔직한 한계 하나: macOS의 `flutter test`는 Apple 시스템 libsqlite3를 쓰기 때문에
`PRAGMA key`를 조용히 무시한다. 즉 **암호화 계층은 단위 테스트로 증명되지 않는다.**
실제 SQLCipher를 태우는 것은 `integration_test/`뿐이고, CI가 매 푸시마다 이를
실기로 돌린다(`.github/workflows/ci.yml`).

## 현재 상태

기준선 A(제작자 개인이 매일 쓰는 수준)는 도달했고 증거와 함께
[docs/completeness-scorecard.md](docs/completeness-scorecard.md)에 판정해 두었다.
남에게 설치를 권할 수준(기준선 B)까지는 격차가 남아 있다:

- **복구 수단 없음** — 마스터 비밀번호를 잊으면 데이터도 잃는다. 복구 코드는 미구현.
- **ad-hoc 서명** — Developer ID 서명·공증 전. Gatekeeper 경고가 뜬다.
- **회전 원자성** — 비밀번호 변경 중 크래시 창은 사전 자동백업으로 완화했을 뿐
  원자적이지 않다.

## 문서 지도

| 문서 | 내용 |
|---|---|
| [docs/design/DESIGN.md](docs/design/DESIGN.md) | 비주얼 디자인 정본 (V9) — 테마 토큰의 원천 |
| [docs/security-threat-model.md](docs/security-threat-model.md) | 공격자 관점 위협모델 33경로 |
| [docs/completeness-scorecard.md](docs/completeness-scorecard.md) | 완성도 판정 (증거 첨부) |
| [docs/qa-vision-e2e.md](docs/qa-vision-e2e.md) | 실앱 구동 비전 QA 루프 |
| [docs/_archive/](docs/_archive/) | 과거 과정 산출물 (정본 아님) |

스택: Flutter(macOS Desktop) · Riverpod · Drift + SQLCipher · pointycastle · GoRouter
