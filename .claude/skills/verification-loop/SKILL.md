---
name: verification-loop
description: "Rails 코드베이스 종합 검증 루프. 빌드, 린트, 테스트, 보안 순차 검증."
---

# 검증 루프 스킬

## 6단계 순차 검증

### Phase 1: 빌드 검증
```bash
bin/rails runner "puts 'Build OK'"
```
**실패 시 즉시 중단** — 빌드가 깨진 상태에서 후속 검증은 무의미합니다.

### Phase 2: 린트 검사
```bash
# RuboCop (설치된 경우)
bundle exec rubocop --format simple 2>/dev/null || echo "RuboCop 미설치"

# ERB 린트 (설치된 경우)
bundle exec erb_lint --lint-all 2>/dev/null || echo "erb_lint 미설치"
```

### Phase 3: 테스트 실행
```bash
bin/rails test
```
- 통과/실패 비율 기록
- 실패한 테스트의 파일:라인 번호 수집

### Phase 4: 시스템 테스트
```bash
bin/rails test:system
```

### Phase 5: 보안 스캔
```bash
# Brakeman (설치된 경우)
bundle exec brakeman -q --no-pager 2>/dev/null || echo "Brakeman 미설치"

# 하드코딩된 시크릿 검색
grep -rn "password.*=.*['\"]" --include="*.rb" app/ config/ | grep -v "test\|spec\|password_digest\|has_secure_password\|_param"

# 디버그 코드 검색
grep -rn "binding\.pry\|binding\.irb\|byebug\|debugger" --include="*.rb" app/
```

### Phase 6: Diff 리뷰
```bash
git diff --stat
git diff --name-only
```
- 의도하지 않은 변경 식별
- 에러 처리 누락 확인

## 검증 보고서

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 검증 결과
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
빌드:       ✅ 통과 / ❌ 실패
린트:       ✅ 0건 / ⚠️ N건 경고 / ❌ N건 오류
테스트:     ✅ X개 통과 / ❌ Y개 실패
시스템:     ✅ 통과 / ❌ 실패 / ⏭️ 건너뜀
보안:       ✅ 이상 없음 / ⚠️ N건 경고
Diff:       N개 파일 변경
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR 준비:    ✅ 가능 / ❌ 수정 필요
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 실행 타이밍
- 기능 구현 완료 후
- 컴포넌트 단위 작업 완료 후
- PR 생성 전 (필수)
- 작업 전환 시
