# 스킬 강제 호출 규칙

적용 가능한 스킬이 있다면 반드시 호출할 것.
이 규칙은 모든 작업에 예외 없이 적용됩니다.

> **정본 주의 (2026-07)**: 작업 유형→스킬 라우팅의 정본은 CLAUDE.md "AI 개발 도구 스택" 절.
> 아래 매핑의 구세대 커맨드(`/plan`·`implement`·`/bugfix`·`/verify`·`/wrap-up`·`/tdd`·팀 워크플로우)는
> deprecated — 정본 대응: 계획=`/autoplan`, 버그=`/investigate`, 리뷰=`/review`,
> TDD·디버깅·검증=superpowers 스킬, 교훈 기록=`/ce-compound`.
> **"적용 스킬 반드시 호출" 원칙 자체와 Red Flags·예외 조건은 그대로 유효하다.**

## 스킬 우회 금지 사유 (Red Flags)

다음 변명이 떠오르면 오히려 스킬을 호출해야 하는 신호:
- "간단한 질문이니까" — 간단해 보여도 스킬이 엣지케이스를 잡음
- "먼저 맥락을 좀 더 파악하고" — 스킬이 맥락 파악을 체계적으로 도움
- "이건 스킬 쓰기엔 과하다" — 판단은 스킬 실행 후에
- "이미 알고 있으니까" — 체계적 확인이 기억보다 안전

## 의무 적용 매핑

| 작업 유형 | 필수 스킬 | 비고 |
|----------|----------|------|
| 새 기능 시작 | `/plan` (Phase 0 브레인스토밍 포함) | 5줄 이하 단순 변경은 면제 |
| 기능 구현 | `implement` | Phase 0 설계 합의 완료 필수 (hard gate) |
| 버그 수정 | `/bugfix` | 근본 원인 추적 의무 |
| 리팩토링 | `code-review` → 수정 → `/verify` | 현황 파악 후 수정 |
| PR 전 | `/verify` | 5단계 전체 검증 |
| 작업 완료 | `/ce-compound` (교훈 기록) | 커밋·푸시는 사용자 명시 지시 시에만 (CLAUDE.md git 규율) |
| 테스트 추가 | `/tdd` | RED→GREEN→REFACTOR (flutter_test) |
| Flutter 위젯 추가 | `flutter-expert` / `flutter-architecture` | 아키텍처 패턴 준수 |
| Riverpod 상태 관리 | `flutter-riverpod-expert` | Provider 패턴 준수 |
| Drift DB 작업 | `dart-drift` | 테이블/DAO/마이그레이션 |
| 보안 점검 | `security-audit` | PR 전 또는 주기적 |
| 팀 기반 기능 개발 | `parallel-feature-development` + 팀 워크플로우 | Medium+ 스코프 기능 |
| 팀 기반 코드 리뷰 | review-team 워크플로우 | PR 전 전문가 병렬 리뷰 |
| 복잡 버그 수정 | `parallel-debugging` | 3회 실패 시 또는 다중 레이어 버그 |

## 도메인 감지 시 추가 의무

작업 유형 매핑(위 테이블)에 더해, 요청에서 도메인 키워드 감지 시:

1. **Standard 자동 READ**: 해당 도메인의 Standard 파일을 읽고 상세 패턴 참조
   - Widget/UI/Theme → `.claude/standards/flutter-widgets.md` READ
   - Architecture/Provider/Drift/Encryption → `.claude/standards/flutter-architecture.md` READ
   - Testing → `.claude/standards/flutter-testing.md` READ
2. **에이전트 고려**: 리뷰/팀 컨텍스트에서 도메인 전문 에이전트 활용 검토

### 도메인별 자동 라우팅

| 도메인 | 감지 키워드 | 스킬 | 에이전트 | Standard (자동 READ) |
|--------|-----------|------|---------|---------------------|
| **Widget/UI** | 위젯, 화면, 스크린, UI, Theme, 테마, 접근성, 애니메이션 | `flutter-expert` `flutter-adaptive-ui` `flutter-animations` | ui-ux-expert | `flutter-widgets.md` |
| **Architecture** | Provider, Notifier, 아키텍처, 상태관리, Riverpod, GoRouter | `flutter-architecture` `flutter-riverpod-expert` | planner, code-review-expert | `flutter-architecture.md` |
| **Database** | Drift, DAO, 테이블, 쿼리, SQLCipher, 마이그레이션 | `dart-drift` | data-integrity-expert | `flutter-architecture.md` |
| **Security** | 암호화, 보안, 마스터키, AES, 복호화, encryption | `security-audit` | security-expert | `flutter-architecture.md` |
| **Testing** | 테스트, 커버리지, TDD, mocktail, flutter_test | `/tdd` `flutter-testing` | qa-engineer | `flutter-testing.md` |
| **Performance** | 성능, 리빌드, const, select, 메모리 | `performance-check` | performance-expert | `flutter-architecture.md` |

## 예외 조건 (이것만 면제)

- 사용자가 명시적으로 "스킬 없이" 또는 "빠르게" 요청한 경우
- 1줄 오타/설정 수정
- 순수 탐색/조사 작업 (코드 변경 없음)
