# Delete Confirmation Page Overrides

> **PROJECT:** KeyBox
> **Page Type:** Delete Confirmation (Inline, Non-Modal)

> Rules here **override** `../MASTER.md`. Unlisted rules follow Master.

---

## Design Principle

> **Loss Aversion** (Kahneman & Tversky 1979): 손실의 고통 = 이득의 기쁨 x 2. 파괴적 액션은 사용자가 결과를 명확히 인지한 후 확인하도록 설계.

> **Progressive Disclosure for Destructive Actions**: 별도 모달이 아닌 인라인 확인으로 컨텍스트 유지. macOS 네이티브 패턴에 부합.

---

## Interaction Flow

```
Step 1: [Delete] 버튼 클릭 (Detail pane 하단)
        ↓
Step 2: 인라인 확인 UI 표시 (Delete 버튼 위치에서 변환)
        ┌─────────────────────────────────────┐
        │ Delete "Stripe API Key"?            │
        │                                     │
        │              [Cancel]  [Delete]      │
        └─────────────────────────────────────┘
        ↓
Step 3a: [Cancel] → 원래 상태로 복귀 (150ms fade)
Step 3b: [Delete] → 삭제 실행 → Toast 알림
```

---

## Inline Confirmation Specs

### Trigger

| Property | Value |
|----------|-------|
| Trigger | Detail pane 하단의 Delete (ghost danger) 버튼 클릭 |
| Position | Delete 버튼이 있던 자리에서 인라인 확장 |
| Animation | `height: 0→auto` + `opacity: 0→1`, 150ms ease-out |

### Confirmation UI

| Element | Spec |
|---------|------|
| Container | `bg-red-950/20`, `border-1 border-red-500/30`, `rounded-lg`, `p-3` |
| Message | "Delete '[시크릿명]'?" — 14px Semibold, `text-primary` |
| Sub-message | 없음 (간결함 유지 — 시크릿명으로 충분한 컨텍스트 제공) |
| Cancel Button | Ghost button, `text-secondary`, left position |
| Delete Button | Danger button (`bg-red-600`, white text), right position |
| Button Height | 28px (desktop native density) |
| Layout | `flex items-center justify-between`, `gap-3` |

### Auto-Dismiss

| Property | Value |
|----------|-------|
| Timeout | 10초 후 자동으로 Cancel (실수 방지) |
| Outside click | 확인 UI 외부 클릭 시 Cancel |
| Escape key | Cancel |

---

## Post-Delete Behavior

| Step | Behavior |
|------|----------|
| 1. 삭제 요청 | 서버에 DELETE 요청 (Turbo Stream) |
| 2. 리스트 업데이트 | 삭제된 아이템이 리스트에서 슬라이드 아웃 (200ms) |
| 3. Detail pane | 다음 아이템 자동 선택. 아이템 없으면 Empty State 표시 |
| 4. Toast | "Deleted '[시크릿명]'" + Undo 링크 (3초) |

### Undo Toast

| Element | Spec |
|---------|------|
| Message | "Deleted '[시크릿명]'" — 14px, white |
| Undo link | "Undo" — 14px Semibold, `text-brand-400`, underline on hover |
| Duration | 3초 자동 사라짐 |
| Action | Undo 클릭 시 soft-delete 복원 |

---

## Animation

| Element | Transition | Duration |
|---------|-----------|----------|
| Confirmation appear | `height + opacity` | 150ms ease-out |
| Confirmation dismiss | `opacity → 0` | 100ms ease-in |
| List item removal | `height → 0` + `opacity → 0` | 200ms ease-in |
| Toast appear | `translateX(100% → 0)` | 300ms ease-out |

---

## Accessibility

- Confirmation 영역: `role="alertdialog"`, `aria-label="Confirm deletion"`
- Delete 버튼: `aria-label="Confirm delete [시크릿명]"`
- Cancel 버튼: 자동 포커스 (기본 액션을 비파괴적으로)
- 키보드: Enter = 포커스된 버튼 실행, Escape = Cancel

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|-----------|
| 별도 모달 팝업 | 인라인 확인 (컨텍스트 유지) |
| "정말 삭제하시겠습니까?" 장문 경고 | 시크릿명 포함 간결한 확인 |
| Delete 버튼에 자동 포커스 | Cancel에 포커스 (비파괴적 기본값) |
| 되돌리기 없는 즉시 삭제 | Soft delete + Undo toast |
