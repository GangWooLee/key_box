# Rails 에러 처리 패턴

## rescue 범위 규칙

### 최소 범위 원칙

rescue는 예외를 발생시키는 **특정 메서드 내부**에 배치. 호출하는 컨트롤러 액션을 감싸지 않음.

```ruby
# ❌ 컨트롤러 액션 전체를 감싸면 redirect/render 누락
def complete_step
  upsert_entry(step_index)
  redirect_to next_path, status: :see_other
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error e.message
  # ← redirect 실행 안 됨! 204 No Content 반환
end

# ✅ 실패 가능한 메서드 내부에서 rescue
def complete_step
  upsert_entry(step_index)
  redirect_to next_path, status: :see_other
end

private

def upsert_entry(step_index)
  entry = Model.find_or_initialize_by(...)
  entry.save!
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error "[Context] Save failed: #{e.message}"
  # 컨트롤러의 redirect는 정상 실행됨
end
```

### 예외별 처리 전략

| 예외 | 위치 | 처리 |
|------|------|------|
| `RecordNotFound` | Controller (before_action) | 404 렌더링 |
| `RecordInvalid` | 실패 메서드 내부 | 로그 + graceful fallback |
| `RecordNotUnique` | 실패 메서드 내부 | retry (bounded) |
| `Faraday::Error` | Service 객체 내부 | 사용자 친화 메시지 반환 |

### Bounded Retry 패턴

```ruby
MAX_RETRY = 3

def create
  retries ||= 0
  # ... 작업 ...
rescue ActiveRecord::RecordNotUnique
  retries += 1
  retry if retries <= MAX_RETRY
  Rails.logger.error "[Context] Max retries exceeded"
end
```

### Graceful Degradation 원칙

저장 실패가 사용자 진행을 차단해서는 안 됨:
- 보조 데이터(대화 기록, 추적 정보) 저장 실패 → 로그 + 계속 진행
- 핵심 데이터(결과물, 사용자 정보) 저장 실패 → 에러 표시 + 재시도 안내
