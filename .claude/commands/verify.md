---
description: "코드베이스 종합 검증을 실행합니다. 빌드, 정적 분석, 테스트, 코드 품질을 순차 검증합니다. 옵션: quick, full, pre-pr"
---

# 종합 검증 워크플로우

`$ARGUMENTS`에 따라 검증 범위를 결정합니다 (기본: full).

## 검증 순서

순차적으로 실행하며, **빌드 실패 시 즉시 중단**합니다.

### 1. 빌드 검증
```bash
flutter build macos --debug
```

### 2. 정적 분석 (quick 모드에서는 생략)
```bash
dart analyze
```

### 3. 테스트 실행
```bash
# quick 모드
flutter test test/core/

# full 모드
flutter test

# pre-pr 모드
flutter test --coverage
```

### 4. 코드 품질 (pre-pr 모드만)
```bash
# 자동 수정 가능한 이슈 확인
dart fix --dry-run

# 하드코딩된 시크릿 검색
grep -rn "password\|secret\|api_key\|token" --include="*.dart" lib/ | grep -v "test\|mock\|example\|\.g\.dart"
```

### 5. Git 상태 확인
```bash
git status
git diff --stat
```

## 결과 보고서

```
검증 결과 (모드: full)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
빌드:      ✅ / ❌
정적 분석: ✅ / ❌ / ⏭️ (건너뜀)
테스트:    ✅ X개 통과 / ❌ Y개 실패
코드 품질: ✅ / ❌ / ⏭️ (건너뜀)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR 준비: ✅ 가능 / ❌ 수정 필요
```

## 이슈 보고 기준
- 정적 분석 오류: 파일 경로와 라인 번호
- 테스트 실패: 테스트명과 에러 메시지
- 코드 품질: dart fix 제안 목록
