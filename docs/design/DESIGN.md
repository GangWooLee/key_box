# Design System — key_box V9 «SLAB & BENCH»

> **단일 진실원천.** `lib/core/theme/*`는 이 문서의 컴파일 결과물이다 — 여기 없는 색·크기·폰트를 코드에 직접 쓰지 않는다. 디자인 변경 = 이 문서 먼저, 코드가 따라간다.
> 작성: 2026-07-13 `/design-consultation` (제안 + 독립 외부 관점 수렴 + 사용자 확정 D4~D7).

## Product Context
- **What**: macOS 로컬 전용 시크릿 매니저(Flutter Desktop). 클라우드에 시크릿을 올리지 않는 사람을 위한, 모든 바이트가 설명되는 볼트.
- **Who**: 개발자(저자 본인이 첫 사용자 — 통과 기준 "내 실제 AWS 키를 넣는다").
- **Positioning**: "1Password를 out-feature가 아니라 out-trust 한다."
- **기억점(모든 결정의 정렬축)**: **"금고인데 가볍다"** — 잠기면 금고의 무게, 열리면 데일리 도구의 경쾌함.

## Aesthetic Direction
- **Direction**: SLAB & BENCH — 기계공의 정밀 기기(machined instrument). 잠김 = 따뜻한 근흑색 슬래브(닫힌 금고 앞의 정적), 열림 = 따뜻한 본지(bone paper) 작업대(내 벤치의 밝음).
- **핵심 물성 규칙**: **온도는 항상 따뜻하게(인간·신뢰 신호), 무게(휘도)만 변한다(금고 신호).** cold 색 유입 금지(V8 교훈: cold 베이스 + warm 액센트 = 부조화).
- **Decoration level**: minimal — 장식 0. 타이포·정렬·공차가 전부.
- **신뢰 표현 원칙**: 보안 도상 영구 금지(자물쇠·방패·배지·트러스트 씰·경보색 없음). 신뢰는 침묵·정밀·상태의 정직한 가시화로만.
- **경쟁 차별(리서치 근거)**: 1Password(엔터프라이즈 배지월)·Bitwarden(템플릿 아이콘 그리드)·Proton Pass(보라 퍼널) 전부 "다크=시리어스" 보안 연극 + 파랑/보라. 우리는 휘도 반전 + 인광 그린 + 침묵.

## The Two States (이 시스템의 심장)
테마는 사용자 설정이 아니라 **잠금 상태**다. 앱이 상태로 빛을 바꾼다.

| | SEALED (잠김) — "The Slab" | OPEN (열림) — "The Bench" |
|---|---|---|
| 은유 | 닫힌 금고, 조밀한 무쇠 단일암 | 램프 켠 작업대, 본지 위의 부품들 |
| 적용 화면 | unlock, loading, vault-error | dashboard, detail, modals, onboarding(후반), audit |
| setup/onboarding | 슬래브에서 시작 → 첫 unlock 모션과 함께 벤치로 | |

## Color

### SEALED — Slab 팔레트
| Token | Hex | 용도 | 대비(on bg) |
|---|---|---|---|
| `slabBg` | `#0B0D08` | 배경 — 조밀한 단일암 | — |
| `slabSurface` | `#12160E` | 입력 필드·카드 | — |
| `slabElevated` | `#1B2113` | focus/hover 상승면 | — |
| `slabText` | `#E4E7DC` | 주 텍스트 | ~15:1 |
| `slabMuted` | `#79826C` | 보조 텍스트 | 4.8:1 |
| `slabAccent` | `#3E6B3A` | **파일럿 라이트(대기)** — 커서 점·포커스 링 | (비텍스트) |
| `slabLive` | `#5FB84E` | 점화 상태(focus 시 파일럿 밝아짐) | (비텍스트) |
| `slabError` | `#B87050` | 오답 — 웜 클레이. *경보가 아니라 침착* | 5.0:1 |
| `slabHairline` | `rgba(228,231,220,0.08)` | 기계 가공선 |

### OPEN — Bench 팔레트
| Token | Hex | 용도 | 대비(on canvas) |
|---|---|---|---|
| `benchCanvas` | `#EDE9DE` | 테이블 캔버스 — 웜 페이퍼 | — |
| `benchTray` | `#E3DECF` | 사이드바 — 가장 가라앉은 면 | — |
| `benchLamp` | `#F6F3EA` | 디테일 패널·선택 행·hover — **"램프 아래"(가장 밝음 = 손에 든 것)** | — |
| `benchInk` | `#1A1D14` | 주 텍스트(잉크) | ~13:1 |
| `benchMuted` | `#5E6454` | 보조 텍스트 | 5.1:1 |
| `benchAccent` | `#336E2C` | 액센트(텍스트 안전) — 링크·활성·주 버튼 | 4.6:1 |
| `benchLive` | `#5FB84E` | 라이브 글로우 — copied·활성 점·선택 엣지 | (비텍스트) |
| `benchError` | `#9A4A34` | 에러 — 산화 클레이 | 4.5:1 |
| `benchHairline` | `rgba(26,29,20,0.10)` | 구분선 |

### 색 규율
- **액센트 면적 10% 이내**(onnydesign 콤보 02 원리). 같은 초록이 두 상태를 관통 — 잠기면 흐린 대기등 `#3E6B3A`, 열리면 살아있는 인광 `#5FB84E`. 색 자체가 상태 은유.
- **표면 위계 = tonal jump만**(다크 글래스모피즘 금지 — V8 확정). Bench의 빛 방향: tray(가라앉음) → canvas → lamp(손에 든 것). "빛은 지금 만지는 시크릿을 향한다."
- Semantic: success = 액센트와 동일 계열(`benchAccent`/`slabLive` — 신뢰는 한 색), warning 별도 도입 금지(파괴 확인은 다이얼로그 마찰로), error = 클레이 계열(붉은 경보 아님).
- Prod/Dev/Staging 배지: 색이 아니라 **무게**로 구분 — PROD는 잉크 600 웨이트, DEV/STG는 muted. 경보색 금지.

## Typography — IBM Plex 단일 패밀리
Plex의 설계 브리프("인간과 기계의 관계")가 제품 논지와 일치. Inter(무개성 기본값)·JetBrains Mono(중복 모노) 제거. **3패밀리 → 1패밀리 2서체.** SIL OFL 1.1, 로컬 번들(`assets/fonts/`).

| Role | Face·Weight | 규칙 |
|---|---|---|
| Display | **IBM Plex Mono** 600, +tracking(0.14~0.22em), UPPERCASE | 워드마크 `KEY_BOX`·잠금 화면·섹션 헤드. 모노=터미널 부트 스크린의 정밀 |
| Body/UI | **IBM Plex Sans** 400·500 | 라벨·내비·버튼·메타데이터 |
| Values | **IBM Plex Mono** 400·500 | **전 시크릿 값·타임스탬프·카운트·경로** — 0/O·1/l/I 구분은 기능 요건 |

- **지문**: 이 앱은 카테고리 누구보다 모노스페이스를 많이 쓴다. 그 절제가 세련이다.
- 필요 번들: Plex Mono Regular/Medium/SemiBold + Plex Sans Regular/Medium/SemiBold (6파일). 기존 Plex Mono 2웨이트에 SemiBold 추가.

### Scale (px)
| Step | px | 용도 |
|---|---|---|
| caption | 10–11 | 테이블 헤더(mono, +tracking, uppercase)·배지 |
| body-s | 12–12.5 | 테이블 행·메타 |
| body | 13 | UI 기본 |
| body-l | 14 | 입력·디테일 값 |
| title-s | 16 | 패널 제목 |
| title | 20 | 화면 제목 |
| display | 24–28 | 온보딩·빈 상태 |
행간: 본문 1.5, 테이블 1.35, 디스플레이 1.2. 모노 숫자 정렬은 Plex Mono 고정폭이 담당.

## Spacing — 8pt
- Base 8px. Scale: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · 2xl 48`.
- Density: comfortable — 단, 시크릿 테이블 행은 compact(수직 9~10px 패딩, 정보 밀도 우선).
- 토큰 파일: `lib/core/theme/spacing.dart` 신설. 인라인 EdgeInsets는 화면 터치 시 점진 회수.

## Layout
- **3-Column 고정**(재론 금지): Sidebar 200px(접힘 레일 48px) / Table fluid / Detail 340px. macOS 네이티브 문법(Finder·Keychain Access·Things).
- 정보량 비례 원칙: 영역 크기는 실제 정보량에 비례.
- **Radii**: `sm 4 · md 6 · lg 10` — macOS 결. 알약/버블 금지, `full`은 상태 점(dot)에만.
- Elevation: 그림자 최소(벤치에서 hairline+tonal로 대체, lamp 면에만 미세 그림자 허용). 슬래브는 그림자 0.

## Motion
- **Approach**: minimal-functional + 시그니처 1개.
- **시그니처 — "불이 들어온다"**: unlock 성공 → 320ms `easeOutExpo` 대각(좌상→우하) 광원 스윕이 슬래브를 벤치로 씻어냄. 콘텐츠는 제자리(슬라이드 금지 — 침착 유지), 표면 색만 스윕 전선 따라 lerp + 파일럿 라이트 `#3E6B3A→#5FB84E` 점화. 구현: 단일 `AnimationController(320ms)` + 대각 `LinearGradient`/`ShaderMask` reveal + 패널 ColorTween. reduce-motion 시 120ms 크로스페이드.
- 잠김(lock)은 **즉각**: 120ms 이내 슬래브 복귀(해제는 관대하게, 잠금은 즉각).
- Duration 스케일: micro 80ms(hover) · short 160ms(전개) · signature 320ms(unlock만). Easing: enter `easeOut`, exit `easeIn`, 이동 `easeInOut`.
- 오답 피드백: 입력 필드 수평 셰이크 3회 240ms + `slabError` 테두리 1s 유지.

## Components — 상태 매트릭스
공통: 최소 히트 영역 44×44. 전 컴포넌트 default/hover/pressed/focus/disabled 정의 필수.

| 컴포넌트 | default | hover | pressed | focus | disabled |
|---|---|---|---|---|---|
| 주 버튼(전진 동작만) | `accent` 채움, 텍스트 `#F6F3EA` | 밝기 +6% | 어둡게 −6% | 2px `live` 링 | 40% 불투명 |
| 보조 버튼 | 투명+`hairline` 테두리 | 표면 한 단계 상승 | tonal down | 링 | 40% |
| 고스트 | 텍스트 `accent` | 밑줄 | — | 링 | 40% |
| **파괴 버튼** | **아웃라인 `error`** (채움 금지) | error 7% 배경 | — | error 링 | 40% |
| 입력 | `surface`+hairline | — | — | `slabAccent`/`benchAccent` 1px + 상승면 | 40% |
| 테이블 행 | canvas | lamp 반 단계 | — | 선택: lamp + 좌측 2px `live` 엣지 | — |
| 배지(type) | mono 10px, tonal 배경 | — | — | — | — |

## 보안 UX 원칙 (확정 — UI가 지켜야 할 계약)
1. **열기는 한 동작**: 마스터 비번 1회 = 유일한 관문. 2차 인증 없음. **Touch ID affordance 자리 예약**(unlock 화면 하단, 비활성 상태로 — C카드 구현 시 UI 재작업 방지).
2. **마찰은 파괴적 행동에만**: 삭제·초기화·export만 확인 다이얼로그. 조회·복사는 무마찰.
3. **보안 상태의 조용한 가시화**(장식이 아닌 정보): 클립보드 소거 카운트다운(conic ring), 자동잠금 잔여 시간, 마지막 백업 시각 — 디테일 패널 하단·mono·muted.
4. **잠금은 즉각, 해제는 관대하게**: 잠금 직후 unlock 화면 비번창 자동 포커스. 오답 시 셰이크 피드백. 오답 메시지는 침착("The vault stays sealed"), 클레이 색.

## 화면별 적용 가이드
- **unlock(Slab)**: 중앙 단일 입력 + 파일럿 라이트 + mono 힌트 한 줄. 로고월·메뉴·크롬 없음. "아무것도 주의를 구걸하지 않는 것"이 신뢰 신호.
- **dashboard(Bench)**: tray 사이드바(가라앉음) → canvas 테이블 → lamp 디테일. 선택 행 = lamp + live 엣지. ⌘K 힌트는 mono placeholder.
- **detail**: 값은 mono 마스킹 기본, reveal·copy는 고스트. 하단에 조용한 상태 정보 3종.
- **modals(sheet·folder·⌘K)**: canvas 위 lamp 카드, dim은 잉크 40%(보라/블랙 아님). 파괴 확인 다이얼로그만 error 아웃라인 버튼.
- **onboarding**: 슬래브에서 시작(setup) → 완료 순간 시그니처 스윕과 함께 벤치 진입 — 첫 경험이 곧 제품 은유.
- **vault-error**: 슬래브 유지(금고는 닫혀 있음), 클레이 톤 사유 + 복구 행동.
- **audit**: 벤치, 전체 mono 타임라인(장부의 물성).

## Flutter 매핑 (lib/core/theme/ 컴파일 규칙)
- `colors.dart`: `AppColors`를 위 토큰명(slab*/bench*)으로 전면 재정의. 기존 `dark*`/`light*` 이름은 각각 slab*/bench*로 사상(위젯 426개 참조처는 화면별 적용 단계에서 전환).
- `typography.dart`: `AppTypography` — 위 Scale, `fontFamily: 'IBM Plex Sans'`/`'IBM Plex Mono'`.
- `spacing.dart`(신설): `AppSpacing.xs..xxl`.
- `app_theme.dart`: `AppTheme.sealed()`/`AppTheme.open()` — ThemeMode가 아니라 **AuthState가 테마를 결정**(`AuthUnlocked` → open). `theme_provider`의 사용자 다크/라이트 설정은 제거 대상(상태가 곧 테마).
- pubspec: google_fonts 없음 유지, Plex Sans 3웨이트 추가 번들, Inter·JetBrains Mono·IBM Plex Mono(기존 2웨이트) 정리.

## Decisions Log
| Date | Decision | Rationale |
|---|---|---|
| 2026-07-13 | SLAB & BENCH 방향 확정 (D4) | 제안·독립 외부 관점 수렴 + 기억점 "금고인데 가볍다" 직결. 경쟁 전부와 반대 방향(휘도 반전) |
| 2026-07-13 | 액센트 = 인광 그린 파일럿 라이트 (D5) | 두 상태 관통하는 "깨어나는" 서사, 보안도구 빨강 위험 회피. 크림슨(콤보01)·코발트(콤보07) 기각 |
| 2026-07-13 | IBM Plex 단일 패밀리 (D6) | "human-machine 관계" 설계 서사 일치, 3→1 패밀리 응집. Geist안 기각 |
| 2026-07-13 | 테마 = 잠금 상태 (라이트/다크 설정 아님) | 상태 대비가 제품 은유 그 자체 |
| 2026-07-13 | 보안 도상 영구 금지 | 카테고리 전체가 반대로 함 — 침묵이 차별화 |
