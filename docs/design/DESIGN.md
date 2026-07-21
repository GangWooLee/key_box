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

## The Three Surfaces (이 시스템의 심장 — Stage 2 shotgun 확정 D8·D9)
**잠금 상태가 1차, 사용자 모드가 2차.** 잠기면 무조건 슬래브. 열리면 사용자가 라이트(벤치)/다크(터미널)를 선택한다(theme_provider 유지).

| | SEALED — "The Slab" (고정) | OPEN·Light — "The Bench" | OPEN·Dark — "The Terminal" |
|---|---|---|---|
| 은유 | 닫힌 금고, 무쇠 단일암 | 램프 켠 작업대, 본지 위의 부품 | 밤의 작업실 — 슬래브가 반 단계 깨어난 세계 |
| 적용 | unlock, loading, vault-error | dashboard·detail·modals·audit (라이트 모드) | 동일 화면 (다크 모드) |
| 언락 모션 | — | 극적 휘도 반전(320ms 스윕) | 미묘한 톤 리프트 + 파일럿 점화(같은 320ms, 낙차만 작음) |

- Terminal은 D(피치블랙+라임)의 **구조**를 계승하되 색은 시스템 통일: 순수 무채·일렉트릭 라임 기각, 웜 근흑 계열 + 인광 그린 `#5FB84E`(D9 확정). **한 인광이 3표면을 관통한다.**
- setup/onboarding: 슬래브에서 시작 → 첫 unlock 모션과 함께 현재 모드의 열림 표면으로.

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
| `slabOnAccent` | `#E4E7DC` | accent 채움 위 라벨(라이브 링 등) | (fill 위 검증) |

### OPEN — Bench 팔레트
| Token | Hex | 용도 | 대비(on canvas) |
|---|---|---|---|
| `benchCanvas` | `#EDE9DE` | 테이블 캔버스 — 웜 페이퍼 | — |
| `benchTray` | `#E3DECF` | 사이드바 — 가장 가라앉은 면 | — |
| `benchLamp` | `#F6F3EA` | 디테일 패널·선택 행 — **"램프 아래"(가장 밝음 = 손에 든 것)** | — |
| `benchHover` | `#F2EEE4` | 행 hover(선택보다 반 단계 낮음 — "반 단계" 하드코딩 대체) | — |
| `benchInk` | `#1A1D14` | 주 텍스트(잉크) | ~13:1(캔버스)·15:1(램프) |
| `benchMuted` | `#5E6454` | 보조 텍스트 | 5.1:1(캔버스)·4.56:1(트레이) |
| `benchAccent` | `#336E2C` | 액센트(텍스트 안전) — 링크·활성·주 버튼 | 5.08:1(캔버스)·4.58:1(트레이) |
| `benchLive` | `#5FB84E` | 라이브 글로우 — copied·활성 점·선택 엣지 | (비텍스트) |
| `benchOnAccent` | `#F6F3EA` | benchAccent 채움 위 라벨 | 5.55:1(fill 위) ✓ |
| `benchError` | `#9A4A34` | 에러 — 산화 클레이 | 4.5:1 |
| `benchHairline` | `rgba(26,29,20,0.10)` | 구분선 |
| `benchScrim` | `rgba(26,29,20,0.40)` | 모달 dim(캔버스보다 어둡게) |

### OPEN·Dark — Terminal 팔레트 (Stage 2 신설)
슬래브의 작업 확장 — 잠김 대비 반 단계 밝은 웜 근흑. "빛은 지금 만지는 시크릿을 향한다" 방향 유지(tray 가장 어둡고 lamp 가장 밝음).

| Token | Hex | 용도 | 대비(on canvas) |
|---|---|---|---|
| `termCanvas` | `#12140E` | 테이블 캔버스 | — |
| `termTray` | `#0E100A` | 사이드바 — 가장 가라앉은 면 | — |
| `termLamp` | `#22261A` | 디테일 패널·선택 행 — 밝은 방 대응 위해 확대(리뷰 §6f: 원래 `#1A1D14`는 캔버스와 ΔL 과소) | — |
| `termHover` | `#191C12` | 행 hover(선택보다 반 단계 낮음) | — |
| `termText` | `#E4E7DC` | 주 텍스트(슬래브와 공유) | ~14:1 |
| `termMuted` | `#909A80` | 보조 — **슬래브(#79826C)보다 밝게**: 램프(#22261A) 위 muted 텍스트가 4.5 미달이라 터미널 전용 값 | 6.29:1(캔버스)·5.23:1(램프) ✓ |
| `termAccent` | `#5FB84E` | 액센트 = 인광 라이브(다크 위 직접 사용) | ~7:1 |
| `termOnAccent` | `#0B0D08` | **termAccent 채움 위 라벨 = 다크 잉크**(D 변형이 증명한 조합) | ~7:1(fill 위) ✓ |
| `termError` | `#B87050` | 에러(슬래브와 공유) | 4.9:1 |
| `termHairline` | `rgba(228,231,220,0.08)` | 구분선 |
| `termScrim` | `rgba(4,5,3,0.55)` | 모달 dim — **캔버스보다 어둡게**(다크 위 잉크 40%는 분리 안 됨) |

### 색 규율
- **액센트 면적 10% 이내**(onnydesign 콤보 02 원리). 같은 초록이 두 상태를 관통 — 잠기면 흐린 대기등 `#3E6B3A`, 열리면 살아있는 인광 `#5FB84E`. 색 자체가 상태 은유.
- **표면 위계 = tonal jump만**(다크 글래스모피즘 금지 — V8 확정). Bench의 빛 방향: tray(가라앉음) → canvas → lamp(손에 든 것). "빛은 지금 만지는 시크릿을 향한다."
- Semantic: success = 액센트와 동일 계열(`benchAccent`/`slabLive` — 신뢰는 한 색), warning 별도 도입 금지(파괴 확인은 다이얼로그 마찰로), error = 클레이 계열(붉은 경보 아님). **터미널 예외**: `termAccent==termLive==#5FB84E`라 "action"과 "success"가 색으로 안 갈림 → 둘의 구분은 **모션**(copied=live 글로우 페이드)으로, 색 중복은 의도적.
- Prod/Dev/Staging 배지: 색이 아니라 **무게**로 구분 — PROD는 잉크색 텍스트 + `fontWeight 600`, DEV/STG는 muted 400. 경보색 금지. (Plex Sans SemiBold 번들 필수 — 아래 타이포 참조.)
- **hover/pressed 방향(리뷰 §6d)**: `밝기 ±6%`는 **OKLCH L 기준, 라벨 대비를 지키는 방향**. 어두운 채움(bench accent)은 hover=밝게, 밝은 채움(term accent)은 hover=어둡게(밝히면 라벨 대비 붕괴). 표면별로 방향이 반대임을 구현 시 준수.
- **모달 dim = 표면별 scrim 토큰**: 라이트는 `benchScrim`(잉크 40%, 캔버스보다 어둡게), 다크는 `termScrim`(캔버스보다 더 어두운 `rgba(4,5,3,0.55)`). 방향은 항상 카드 휘도의 **반대**로 — 다크에서 잉크 40%는 분리 안 됨.
- **마스킹 dot 개수 고정(보안)**: 값 마스킹 `••••`는 **값 길이와 무관하게 고정 개수**(예: 12개). 길이 노출 = 시크릿 길이 유출.

## Typography — IBM Plex 단일 패밀리
Plex의 설계 브리프("인간과 기계의 관계")가 제품 논지와 일치. Inter(무개성 기본값)·JetBrains Mono(중복 모노) 제거. **3패밀리 → 1패밀리 2서체.** SIL OFL 1.1, 로컬 번들(`assets/fonts/`).

| Role | Face·Weight | 규칙 |
|---|---|---|
| Display | **IBM Plex Mono** 600, +tracking(0.14~0.22em), UPPERCASE | 워드마크 `KEY_BOX`·잠금 화면·섹션 헤드. 모노=터미널 부트 스크린의 정밀 |
| Body/UI | **IBM Plex Sans** 400·500·**600** | 라벨·내비·버튼·메타데이터. 600은 PROD env 배지 전용(무게 구분) |
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
- **미세 단계(2026-07-13 design-review)**: `xxs 2 · xsm 6 · smd 12` — compact 데스크톱 UI가 실사용에서 6·12를 체계적으로 재사용함이 실측됨(17/44 인셋). 미세 단계는 컴포넌트 내부 간격 전용, 레이아웃 리듬은 8pt 본 스케일 유지.
- Density: comfortable — 단, 시크릿 테이블 행은 compact(수직 9~10px 패딩, 정보 밀도 우선).
- **버튼 높이 3단계(2026-07-13 확정)**: 인라인 32(테이블·디테일 액션) · 모달 36(sheet 폼) · 히어로 40(auth·온보딩 전폭). 이 밖의 높이 금지.
- 토큰 파일: `lib/core/theme/spacing.dart` 신설. 인라인 EdgeInsets는 화면 터치 시 점진 회수.

## Layout
- **3-Column 고정**(재론 금지): Sidebar 200px(접힘 레일 48px) / Table fluid / Detail 340px. macOS 네이티브 문법(Finder·Keychain Access·Things).
- 정보량 비례 원칙: 영역 크기는 실제 정보량에 비례.
- **Radii**: `sm 4 · md 6 · lg 10` — macOS 결. 알약/버블 금지, `full`은 상태 점(dot)에만.
- Elevation: 그림자 최소(벤치에서 hairline+tonal로 대체, lamp 면에만 미세 그림자 허용). 슬래브는 그림자 0.

## Motion
- **Approach**: minimal-functional + 시그니처 1개.
- **시그니처 — "불이 들어온다"**: unlock 성공 → 320ms `easeOutExpo` 대각(좌상→우하) 광원 스윕이 슬래브를 열림 표면으로 씻어냄. 콘텐츠는 제자리(슬라이드 금지 — 침착 유지), 표면 색만 스윕 전선 따라 lerp + 파일럿 라이트 `#3E6B3A→#5FB84E` 점화. **구현됨(2026-07-14)**: `lib/features/auth/presentation/widgets/unlock_sweep.dart` — 단일 `AnimationController(AppMotion.signature)` + 대각 `LinearGradient` 커버 리빌(slab-at-zero-alpha로 다크 프린지 제거). 표면 전환은 `surfaceThemeProvider`가 담당(스윕은 이미 그려진 새 표면을 드러냄). reduce-motion 시 `AppMotion.snap`(120ms) 균일 크로스페이드.
  - **라이트(벤치) 타깃**: 슬래브 `#0B0D08` → 벤치 `#EDE9DE` (극적 휘도 반전).
  - **다크(터미널) 타깃**: 슬래브 `#0B0D08` → 터미널 `#12140E` (미묘한 톤 리프트, 낙차 작음).
  - **첫 실행 히어로 규칙(리뷰 §3)**: setup 완료 후 **첫 스윕은 OS 다크 여부와 무관하게 벤치(라이트)로** 극적 반전을 보여준 뒤, 다음 부팅부터 사용자 모드(theme_provider) 추종. 첫인상 = 제품 은유이므로 muted 버전으로 시작하지 않는다. 단 **명시적 테마 선택은 히어로를 즉시 해제**한다(2026-07-19): 히어로 세션 중에도 사용자가 설정/토글로 모드를 고르면 그 선택이 바로 렌더에 반영된다 — 히어로는 기본값을 이기지만 명시적 의사는 못 이긴다.
- 잠김(lock)은 **즉각**: 120ms 이내 슬래브 복귀(해제는 관대하게, 잠금은 즉각).
- Duration 스케일: micro 80ms(hover) · short 160ms(전개) · signature 320ms(unlock만). Easing: enter `easeOut`, exit `easeIn`, 이동 `easeInOut`.
- 오답 피드백: 입력 필드 **수평 셰이크(진폭 8px, 3회, 240ms, easeInOut)** + `slabError` 테두리 1s 유지.

## Components — 상태 매트릭스
공통: **최소 히트 영역 32×32(macOS 데스크톱 포인터 밝힘 — 44는 터치 규칙)**. 전 컴포넌트 default/hover/pressed/focus/disabled 정의 필수. 색은 표면 토큰(slab*/bench*/term*)으로 참조 — 아래 규칙은 표면 무관 공통, **표면별 예외는 명시**.

| 컴포넌트 | default | hover | pressed | focus | disabled |
|---|---|---|---|---|---|
| 주 버튼(전진 동작만) | `accent` 채움 + **표면별 `onAccent` 라벨**(slab `#E4E7DC`·bench `#F6F3EA`·term `#0B0D08`) | **밝은 accent(term)는 어둡게, 어두운 accent(bench)는 밝게** — 항상 라벨 대비 유지 방향 | 반대 −6% | 2px 링 — **term은 `live`가 fill과 동일하므로 `termText #E4E7DC` 링** | 40% 불투명 |
| 보조 버튼 | 투명+`hairline` 테두리 | 표면 한 단계 상승 | tonal down | accent 링 | 40% |
| 고스트 | 텍스트 `accent` | 밑줄 | — | accent 링 | 40% |
| **파괴 버튼** | **아웃라인 `error`** (채움 금지) | error 7% 배경 | — | error 링 | 40% |
| 입력 | `surface`+hairline | — | — | `slabAccent`/`benchAccent`/`termAccent` 1px + 상승면 | 40% |
| 테이블 행 | canvas | `benchHover`/`termHover`(정의된 토큰) | — | 선택: `lamp` + 좌측 2px `live` 엣지 | — |
| 배지(type) | mono 10px, tonal 배경 | — | — | — | — |
| **배지(env)** | mono 10px 무배경 — **PROD=텍스트 잉크색+`fontWeight 600`, DEV/STG=muted 400**(색 아닌 무게로 구분). Plex Sans SemiBold 번들 필요 | — | — | — | — |
| **토스트** | `lamp` 카드 + hairline, 하단 우측 오프셋, mono 12px. "copied" 등 성공=accent 텍스트, 에러=error 텍스트 | — | — | — | 3s 후 페이드아웃(hover 시 일시정지) |
| **드롭다운/셀렉트** | `surface`+hairline, 우측 chevron(도상 예외 — 기능 필수), 선택값 mono | 표면 상승 | — | accent 1px 링 | 40%. 열림: `lamp` 팝오버, 선택 항목 accent 텍스트 |
| **컨텍스트 메뉴(우클릭)** | `lamp` 팝오버 + hairline, 항목 body 13px, 파괴 항목만 error 텍스트 | 항목 `hover` 배경 | — | 키보드 포커스 accent 배경 | — |
| **토글/스위치** | off=`muted` 트랙+`surface` 노브 / on=`accent` 트랙+`onAccent` 노브 | 트랙 밝기 이동 | — | accent 링 | 40% |
| **체크박스** | `surface`+hairline 사각(radii sm) / checked=`accent` 채움+`onAccent` 체크 | hairline 진하게 | — | accent 링 | 40% |
| **검색 필드**(⌘K) | 상단 바 상시 노출, `surface`+hairline, mono placeholder `⌘K — search…`, 좌측 돋보기(도상 예외) | — | — | accent 1px 링 | — |
| **스크롤바** | 오버레이형, 트랙 투명, 썸=`muted` 40%, hover 시 60%. macOS 네이티브 추종 | 썸 진하게 | — | — | — |
| **접힘 사이드바 레일(48px)** | **텍스트 잘림 방지 위해 각 섹션 첫 2글자 mono 이니셜**(예: `AL`·`PR`·`SS`) + 카운트. 도상 없음 — 침묵 원칙 유지 | 항목 `hover` 배경 | — | accent 좌측 엣지 | — |

## 보안 UX 원칙 (확정 — UI가 지켜야 할 계약)
1. **열기는 한 동작**: 마스터 비번 1회 = 유일한 관문. 2차 인증 없음. **Touch ID affordance 자리 예약**(unlock 화면 하단, 비활성 상태로 — C카드 구현 시 UI 재작업 방지).
2. **마찰은 파괴적 행동에만**: 삭제·초기화·export만 확인 다이얼로그. 조회·복사는 무마찰.
3. **보안 상태의 조용한 가시화**(장식이 아닌 정보): 클립보드 소거 카운트다운(conic ring), 자동잠금 잔여 시간, 마지막 백업 시각 — 디테일 패널 하단·mono·muted.
4. **잠금은 즉각, 해제는 관대하게**: 잠금 직후 unlock 화면 비번창 자동 포커스. 오답 시 셰이크 피드백. 오답 메시지는 침착("The vault stays sealed"), 클레이 색. N회 오답 후 backoff 카운트다운.
5. **편집 중 자동잠금 dirty-guard(리뷰 §3)**: sheet_modal에 미저장 변경이 있을 때 auto-lock 발화 시 **즉시 잠그지 않고** dirty 상태를 보존(비휘발 draft 또는 잠금 지연) — 침묵 데이터 손실 금지. 최소한 잠금 전 저장 경고.

## 화면별 적용 가이드
- **setup(Slab — unlock과 별개 화면, 리뷰 §3)**: 최초 볼트 생성. 비번 입력 + **확인 입력** + 강도 힌트(약하면 muted mono 한 줄, 차단은 아님) + 생성 버튼. unlock의 `MASTER PASSWORD · RETURN TO OPEN`과 다른 카피(`CREATE MASTER PASSWORD`). Touch ID affordance 자리는 여기에도 예약(비활성).
- **unlock(Slab)**: 중앙 단일 입력 + 파일럿 라이트 + mono 힌트 한 줄. 로고월·메뉴·크롬 없음. "아무것도 주의를 구걸하지 않는 것"이 신뢰 신호. **N회 오답 후 backoff**: 셰이크 + mono 카운트다운(`try again in 0:30`) — lockout도 침착 톤.
- **dashboard(Bench/Terminal)**: tray 사이드바(가라앉음) → canvas 테이블 → lamp 디테일. 선택 행 = lamp + live 엣지. **⌘K = 상단 바 상시 검색 필드**(모달 아님 — 리뷰 §4 확정).
- **detail**: 값은 mono 마스킹 기본(**고정 dot 개수**), reveal·copy는 고스트. **긴 값(JWT·JSON 400~2000자)**: reveal 시 mono 래핑 + 세로 스크롤(가로 스크롤 금지), 복사는 전체. 하단에 조용한 상태 정보 3종.
- **modals(sheet·folder·context)**: canvas/terminal-canvas 위 lamp 카드, dim은 표면별 scrim 토큰. 파괴 확인 다이얼로그만 error 아웃라인 버튼.
- **create/edit secret(sheet_modal — 리뷰 §2·§3 신설)**: lamp 카드에 세로 폼 —
  - 필드 순서: Name(text) → Value(멀티라인 mono, 마스킹 토글) → **Folder(드롭다운 — 생성 모드에서 Key Value 다음·Advanced 토글 앞에 상시 노출)** → Type(드롭다운: API/TOKEN/KEY/PWD/SSH) → Service(text) → Environment(드롭다운: PROD/DEV/STG) → Notes(옵션).
  - Folder 기본값: 현재 선택 폴더를 추종, 미선택(카테고리 뷰) 시 General을 명시 표시 — 무음 파일링 제거. 편집 모드에는 셀렉터 미표시(폴더 이동은 detail 칩 소관).
  - 라벨은 필드 위 mono caption(placeholder-as-label 금지 — 접근성). 검증: Name·Value 필수, 빈값 시 error 테두리 + mono 사유 한 줄.
  - dirty 상태: 저장 버튼 활성화(dirty 아니면 disabled). Cancel은 dirty면 확인 다이얼로그.
  - 하단 액션: `Save`(주 버튼) · `Cancel`(보조). Save 성공 → 토스트 + 모달 닫힘.
- **restore-from-backup(신설 — out-trust 유일 복구 경로, 리뷰 §3)**: **Slab 유지**(복구도 금고는 닫힌 상태). 3스텝 —
  ①파일 선택(`.kbx` 아카이브) ②마스터 비번 입력 ③무결성 검사 진행(conic ring, `VaultBackupService.verifyIntegrity` 결과) → 성공=벤치 진입 스윕 / 실패=클레이 톤 사유(손상·오답 구분). vault-error 화면에서 진입 가능.
- **settings(Bench/Terminal — 신설, 리뷰 §5)**: 3-Column 유지, 좌측 섹션 목록 + 우측 폼. 항목: 자동잠금 시간(드롭다운/슬라이더), 테마(라이트=벤치/다크=터미널/시스템 토글), reveal 기본값(토글), 비번 변경(→키 회전 플로우), export/백업. `auto-lock 12m` 등 목업에 노출된 값의 편집처.
- **onboarding**: 슬래브에서 시작(setup) → 완료 순간 시그니처 스윕과 함께 **벤치 진입(첫 실행은 라이트 고정)** — 첫 경험이 곧 제품 은유.
- **vault-error**: 슬래브 유지(금고는 닫혀 있음), 클레이 톤 사유 + 복구 행동(복원 화면 링크).
- **audit**: 벤치/터미널, 전체 mono 타임라인(장부의 물성).

### 빈/에러/오버플로 상태 (리뷰 §2 — 인광 서사로 통일)
| 상태 | 화면 | 사양 |
|---|---|---|
| **빈 볼트(0 시크릿)** | dashboard 첫 실행 | 히어로 스윕 목적지. 캔버스 중앙: 파일럿 라이트 점 + mono `THE BENCH IS CLEAR` + muted 한 줄(`your first secret goes here`) + 주 버튼 `+ New Secret` + `⌘N` 힌트. 공백 아님 |
| **빈 디테일(무선택)** | detail 340px 기본 | 부팅 직후 무선택 상태. muted mono `select a secret` + 파일럿 점(대기등). 340px가 비지 않게 |
| **0 검색 결과** | table | muted mono `no match for "<query>"` + `clear` 고스트. 입력어 에코 |
| **빈 폴더** | table(폴더 필터) | muted mono `this folder is empty` + `+ New Secret`(폴더 프리셋) |
| **인바운드 에러**(copy/decrypt/write 실패) | 토스트 | error 텍스트 토스트(§매트릭스), 슬래브 vault-error와 별개 |
| **긴 이름/값 오버플로** | table/detail | 테이블 name = 말줄임(…) + hover 툴팁 풀네임. detail value = 위 래핑 규칙 |

## Flutter 매핑 (lib/core/theme/ 컴파일 규칙)
- `colors.dart`: `AppColors`를 위 토큰명(slab*/bench*)으로 전면 재정의. 기존 `dark*`/`light*` 이름은 각각 slab*/bench*로 사상(위젯 426개 참조처는 화면별 적용 단계에서 전환).
- `typography.dart`: `AppTypography` — 위 Scale, `fontFamily: 'IBM Plex Sans'`/`'IBM Plex Mono'`.
- `spacing.dart`(신설): `AppSpacing.xs..xxl` + 미세 단계 `xxs/xsm/smd`.
- `motion.dart`(신설): `AppMotion.micro(80ms)/short(160ms)/signature(320ms)` — §Motion 컴파일. Duration 리터럴 금지.
- `app_theme.dart`: `AppTheme.sealed()`/`AppTheme.bench()`/`AppTheme.terminal()` — **AuthState가 1차 결정**(잠김=sealed 고정), 열림에서 `theme_provider`의 사용자 라이트/다크가 bench/terminal 선택(D8·D9 확정 — theme_provider 유지, system 모드는 OS 설정 추종).
- pubspec: google_fonts 없음 유지, **Plex Sans 3웨이트(400·500·600) + Plex Mono 3웨이트(400·500·600, 기존 2에 SemiBold 추가) 번들**, Inter·JetBrains Mono 제거.
- 3표면 각각 `onAccent`·`hover`·`scrim` 토큰 포함(위 팔레트). 컴포넌트 위젯은 현재 표면의 토큰 세트를 `Theme.of` 또는 표면 provider로 참조 — accent 채움 라벨은 반드시 `onAccent`(하드코딩 `#F6F3EA` 금지, 터미널에서 2.24:1 실패).

## NOT in scope (고려 후 명시적 연기)
- **다국어/RTL**: 현재 macOS 개인 도구, 영어·한국어 혼용. RTL 레이아웃 미대응(향후).
- **모바일/태블릿 반응형**: macOS 데스크톱 전용 — 3-Column 고정, 뷰포트 반응형 없음(창 최소폭만 정의).
- **멀티셀렉트·드래그 앤 드롭**: 벌크 삭제/이동은 후속(체크박스 토큰은 매트릭스에 선반영, 배선은 연기).
- **Touch ID 실동작**: affordance 자리만 예약, macOS Keychain 2팩터(C카드)는 후속.
- **트리 중첩 폴더 disclosure**: 현 폴더는 1-depth 가정, 중첩 트리 UI 연기.

## What already exists (재사용)
- V8 golden 베이스라인(`test/golden/goldens/`) — V9 "before" 대조군. 구현 후 갱신.
- 기존 화면 골격(`lib/features/*/presentation/`) — 레이아웃 3-Column은 유지, 토큰만 교체.
- `AuthState`·`theme_provider`·`ThemeMode` — 3표면 결정 로직의 기반(AuthState 1차 + theme_provider 2차).
- `VaultBackupService.verifyIntegrity`·아카이브 v2(`.kbx`) — restore 화면이 소비할 백엔드(이미 구현됨, UI만 신설).
- IBM Plex Mono 2웨이트 번들(`assets/fonts/`) — SemiBold·Plex Sans만 추가.

## Approved Mockups
| Screen | Path | Direction |
|---|---|---|
| dashboard+unlock (A 확정) | `~/.gstack/projects/GangWooLee-key_box/designs/v9-shotgun-20260713/variant-A.png` | SLAB & BENCH 라이트(벤치) 기준 |
| dashboard+unlock (D 다크 참조) | `.../variant-D.png` | 터미널 구조 계승(색은 인광 통일로 수렴) |
| 시스템 전체 시각 정본 | Artifact `keybox-v9-artifact.html`(3표면 토글) | 팔레트·타이포·컴포넌트·모션·보안UX |

## Decisions Log
| Date | Decision | Rationale |
|---|---|---|
| 2026-07-13 | SLAB & BENCH 방향 확정 (D4) | 제안·독립 외부 관점 수렴 + 기억점 "금고인데 가볍다" 직결. 경쟁 전부와 반대 방향(휘도 반전) |
| 2026-07-13 | 액센트 = 인광 그린 파일럿 라이트 (D5) | 두 상태 관통하는 "깨어나는" 서사, 보안도구 빨강 위험 회피. 크림슨(콤보01)·코발트(콤보07) 기각 |
| 2026-07-13 | IBM Plex 단일 패밀리 (D6) | "human-machine 관계" 설계 서사 일치, 3→1 패밀리 응집. Geist안 기각 |
| 2026-07-13 | 테마 = 잠금 상태 (라이트/다크 설정 아님) | 상태 대비가 제품 은유 그 자체 |
| 2026-07-13 | **(개정 D8·D9)** 3표면 체계 — 잠김 슬래브 고정 + 열림 벤치/터미널 사용자 전환 | Stage 2 shotgun: A 선호(4)+D(4) — "A↔D 라이트/다크 전환 느낌" 피드백. C 크림슨(1)·B 코발트(3) 탈락 |
| 2026-07-13 | Terminal은 인광 통일(라임 #2BEE34·순수무채 #141414 기각) | 온도·색 일관 — 한 인광이 3표면 관통 (D9) |
| 2026-07-13 | 보안 도상 영구 금지 | 카테고리 전체가 반대로 함 — 침묵이 차별화 |
| 2026-07-13 | **(리뷰 반영)** 표면별 `onAccent`/`focus`/`scrim`/`hover` 토큰 신설 | plan-design-review: 터미널 주 버튼 `#F6F3EA` on `#5FB84E` = 2.24:1 WCAG 실패 → `termOnAccent #0B0D08`(7.86:1). 2표면용 규칙이 3표면에서 붕괴 |
| 2026-07-13 | **(리뷰 반영)** 빈 상태 6종·시크릿 폼·복원·설정 화면 명세 | 리뷰: '룩북→빌드 스펙' 승격. 히어로 스윕 목적지(빈 볼트)·핵심 쓰기 경로·out-trust 복구 경로가 공백이었음 |
| 2026-07-13 | **(리뷰 반영)** 모순 3건 해소 | ⌘K=상시 검색필드(모달 아님)·히트영역 32px(데스크톱)·접힘 레일=mono 이니셜(아이콘 금지 유지). 첫 실행 히어로=벤치 고정 |
| 2026-07-13 | **(리뷰 반영)** 누락 컴포넌트 8종 매트릭스 추가 | 토스트·드롭다운·컨텍스트메뉴·토글·체크박스·검색필드·스크롤바·env배지·접힘레일 — 시크릿 매니저 필수 |
| 2026-07-13 | **(design-review 반영)** 모션 토큰·미세 spacing 단계·버튼 3단계 명문화 | Stage 5 감사: 모션만 토큰 레이어 부재(5건 오프스케일)·6/12 인셋 체계적 재사용·버튼 높이 32/36/40 실측 일관 — 스케일로 승격 |
| 2026-07-13 | **(design-review 반영)** dev 리셋 어포던스 = muted mono + 확인 게이트 | 실앱 첫인상: 클레이 아웃라인이 봉인 슬래브 최대 소음원. 파괴 마찰은 다이얼로그가 담당 |
| 2026-07-14 | **시그니처 스윕 구현(Phase B 마감)** | §Motion 유일 HIGH 갭 해소 — UnlockSweep 위젯(앱 builder 1회 래핑, 봉인→해제 전이 시 320ms easeOutExpo 대각 슬래브-지우기). slab-at-zero-alpha로 프린지 제거·reduce-motion 120ms 페이드·첫 실행 히어로=벤치 고정. 골든 `unlock_sweep_mid.png` 신설. `motion.dart` snap(120) 추가 |
| 2026-07-19 | **(QA 반영)** 히어로 예외 — 명시적 테마 선택 시 즉시 해제 | 실앱 QA: 셋업 직후 세션에서 Settings Dark·토글이 렌더에 무반응(히어로가 다음 잠금까지 themeMode를 가림). 히어로는 첫 노출 기본값 규칙이지 명시적 사용자 선택 차단이 아님 |
