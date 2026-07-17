# KeyBox — High-Performance Design Reference Guide

이 문서는 KeyBox 애플리케이션의 시각적 기준(Visual Benchmark)을 설정하기 위해 제작되었습니다. AI 혹은 휴먼 디자이너가 시안을 제작할 때 흔히 범하는 '과도하게 둥근 모서리', '불필요한 애니메이션', '지나친 여백' 등을 지양하고 오직 **개발자 도구 (Developer Tools)** 로서의 기능미와 프로페셔널함에 집중합니다.

---

## 📸 Core UI References

### 1. Main Dashboard (2-Column Layout)
> **V4 전환 (2026-02-28):** 3-Column → 2-Column. 사이드바 제거, 폴더 내비게이션을 리스트 상단 드롭다운으로 이동.

1Password/Bitwarden 스타일의 2-Column 레이아웃. 왼쪽 리스트(320px, Vibrancy) + 오른쪽 디테일(fluid). 완전한 몰입형 다크 모드와 텍스트 기반의 고밀도 레이아웃.

![Main Dashboard Reference](file:///Users/igangu/key_box/docs/design/reference/mac_native_reference_1.png)

### 2. Command Palette (Cmd + K)
바탕화면 위에 떠오르는 신속 검색창. Raycast나 Spotlight처럼 미니멀하면서 배경 블러링(Vibrancy)을 제한적으로 활용해 가시성을 극대화함.

![Command Palette Reference](file:///Users/igangu/key_box/docs/design/reference/mac_native_reference_2.png)

### 3. Creation Modal (Sheet Style)
웹 브라우저의 전형적인 중앙 모달을 탈피하여, 창 윗부분에서 슬라이드 다운(Slide-down)되는 네이티브 Sheet 스타일 차용. 

**Progressive Disclosure UX (점진적 정보 노출):**
사용자의 인지 부하를 줄이기 위해 기본적으로 **Title(이름)**, **Description(설명)**, **Value(키 값)** 3가지 입력 필드만 노출됩니다. Type, Environment, Tags 등의 복잡한 설정은 폼 하단의 `Advanced Options ▼` (고급 설정) 토글을 눌렀을 때만 나타납니다.

![Sheet Modal Reference](file:///Users/igangu/key_box/docs/design/reference/mac_native_reference_3.png)

---

## 🚫 Anti-Patterns (지양해야 할 디자인)

위 레퍼런스들의 분위기를 유지하기 위해 **절대 금지**해야 하는 디자인 요소입니다:

1. **Heavy Rounded Corners**: `border-radius: 16px` 이상의 둥근 모서리 금지. 버튼은 최장 6px, 큰 컨테이너는 8px을 넘지 마십시오. (장난감 같은 인상을 줍니다)
2. **Neumorphism / Glassmorphism 남용**: 화면 전체가 번쩍이는 글래스 효과 금지. 컨텍스트가 덮어씌워질 때(예: 사이드바 배경, 모달 배경)만 제한적으로 사용하십시오.
3. **Fluffy Shadows**: 넓게 퍼지는 파스텔톤 그림자 금지. 그림자는 오직 팝업이 떠오르는 깊이감을 줄 때만 어둡고 샤프하게(0 4px 12px rgba(0,0,0,0.5)) 사용하십시오.
4. **Colorful Gradients**: 다채롭고 과한 그라데이션 금지. 유일한 포인트 컬러는 `Indigo-600(#4f46e5)`이며 나머지는 무채색 명도 조절로만 계층을 나눕니다.
5. **Low Information Density**: 여백이 너무 넓은 헐렁한 UI 금지. 개발자는 한 화면에서 최대한 많은 키와 정보를 읽고 싶어 합니다. 텍스트는 작고 촘촘하게 배치하십시오.
