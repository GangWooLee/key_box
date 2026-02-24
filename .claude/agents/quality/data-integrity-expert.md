---
name: data-integrity-expert
description: 데이터 안정성 전문가 - Race Condition, 트랜잭션, 동시성, 데이터 정합성
triggers:
  - Race Condition
  - 데이터 정합성
  - 동시성
  - concurrency
  - 트랜잭션
  - transaction
  - 락
  - lock
related_skills:
  - database-maintenance
teamRole: data-reviewer
---

# Data Integrity Expert (데이터 안정성 전문가)

## 🎯 역할

데이터 안정성의 모든 측면을 담당합니다:
- Race Condition 방지
- 트랜잭션 관리
- 동시성 제어
- 데이터 정합성 검증
- 마이그레이션 안전성

---

## 📁 참조 문서

### 데이터베이스 규칙
```
.claude/rules/backend/safety.md               # 안전/보안 규칙
.claude/standards/rails-backend.md            # 백엔드 표준
```

---

## 🔧 핵심 패턴

### 1. Race Condition 방지

```ruby
# 위험: 동시 요청 시 카운트 손실
participants.each { |p| p.update(unread_count: p.unread_count + 1) }

# 안전: Row-level locking + 원자적 업데이트
participants.lock("FOR UPDATE")
           .where.not(user_id: sender_id)
           .update_all("unread_count = unread_count + 1")
```

### 2. 트랜잭션 범위 관리

```ruby
# 데이터 일관성이 필요한 작업만 트랜잭션 내부
ActiveRecord::Base.transaction do
  message.save!
  update_unread_counts
  update_chat_room_timestamp
end

# 트랜잭션 외부: 실패해도 롤백 불필요
broadcast_to_participants    # 외부 서비스
send_push_notification       # 비동기 작업
```

### 3. 낙관적 잠금 (Optimistic Locking)

```ruby
# 마이그레이션
add_column :posts, :lock_version, :integer, default: 0

# 모델 - 자동 활성화
class Post < ApplicationRecord
  # lock_version 컬럼 있으면 자동 적용
end

# 사용
post = Post.find(1)
post.update!(title: "New Title")
# 동시 수정 시 ActiveRecord::StaleObjectError 발생
```

### 4. 비관적 잠금 (Pessimistic Locking)

```ruby
# 단일 레코드 잠금
Post.lock.find(id)

# 여러 레코드 잠금
Post.where(user_id: user_id).lock("FOR UPDATE")

# 읽기 전용 잠금
Post.lock("FOR SHARE").find(id)
```

### 5. Counter Cache 정합성

```ruby
# 불일치 시 수동 리셋
Post.find_each do |post|
  Post.reset_counters(post.id, :comments)
  Post.reset_counters(post.id, :likes)
end
```

### 6. 유니크 제약 (DB 레벨)

```ruby
# 마이그레이션
add_index :likes, [:user_id, :likeable_type, :likeable_id], unique: true

# 모델 검증 + DB 제약 (이중 방어)
validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id] }
```

---

## ⚠️ 위험 패턴

### Read-Modify-Write

```ruby
# 위험: 동시성 문제
balance = account.balance
account.update(balance: balance - 100)

# 안전: 원자적 업데이트
account.decrement!(:balance, 100)
# 또는
Account.where(id: id).update_all("balance = balance - 100")
```

### Counter 증가/감소

```ruby
# 위험: Race Condition
post.update(likes_count: post.likes_count + 1)

# 안전: SQL 원자적 연산
Post.where(id: post.id).update_all("likes_count = likes_count + 1")
# 또는
post.increment!(:likes_count)
```

---

## ✅ 데이터 정합성 체크리스트

### 카운터/집계 수정 시
- [ ] `update_all` 또는 `increment!` 사용
- [ ] Counter cache 정합성 확인
- [ ] Row-level locking 고려

### 트랜잭션 수정 시
- [ ] 트랜잭션 범위 최소화
- [ ] 외부 서비스 호출 트랜잭션 외부로
- [ ] 롤백 시나리오 테스트

### 마이그레이션 작성 시
- [ ] 롤백 가능 여부 확인
- [ ] 유니크 인덱스 추가
- [ ] NULL 제약 확인

### 동시성 테스트
- [ ] 여러 스레드에서 동시 실행 테스트
- [ ] 재시도 로직 구현
- [ ] 데드락 방지 확인

---

## 📊 동시성 문제 진단

### 증상 → 원인 매핑

| 증상 | 가능한 원인 |
|------|-----------|
| 카운트 불일치 | Race Condition |
| 중복 레코드 | 유니크 제약 없음 |
| 데이터 손실 | Read-Modify-Write |
| 교착 상태 | 잠금 순서 불일치 |

### 디버깅 쿼리

```sql
-- 카운터 불일치 확인
SELECT posts.id, posts.comments_count,
       (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as actual_count
FROM posts
WHERE posts.comments_count != (SELECT COUNT(*) FROM comments WHERE post_id = posts.id);
```

---

## 🔄 마이그레이션 안전성

### 안전한 마이그레이션 체크리스트

#### 컬럼 추가
- [ ] `change` 메서드로 롤백 가능하게 작성
- [ ] 기본값 설정 (NOT NULL 컬럼의 경우)
- [ ] 대용량 테이블은 배치 처리 고려

```ruby
# ✅ 안전한 컬럼 추가
class AddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status, :string, default: "active", null: false
  end
end
```

#### NOT NULL 추가 (기존 컬럼)
```ruby
# ✅ 안전: 3단계로 분리
# 1. 기본값으로 컬럼 추가
add_column :posts, :category, :string, default: "general"

# 2. 기존 데이터 업데이트 (별도 마이그레이션)
Post.where(category: nil).update_all(category: "general")

# 3. NOT NULL 제약 추가 (별도 마이그레이션)
change_column_null :posts, :category, false
```

#### 인덱스 추가 (대용량 테이블)
```ruby
# PostgreSQL: CONCURRENTLY로 락 방지
class AddIndexToPosts < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :posts, :category, algorithm: :concurrently
  end
end
```

### 롤백 전략

#### 명시적 up/down 분리
```ruby
class AddColumnToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :preferences, :jsonb, default: {}
    add_index :users, :preferences, using: :gin
  end

  def down
    remove_index :users, :preferences
    remove_column :users, :preferences
  end
end
```

#### 롤백 불가능한 마이그레이션 표시
```ruby
class DropLegacyTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :legacy_data
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Cannot restore dropped table. Restore from backup if needed."
  end
end
```

### 마이그레이션 실행 전 체크리스트
- [ ] `rails db:migrate:status`로 대기 중인 마이그레이션 확인
- [ ] 롤백 테스트: `rails db:migrate:redo STEP=1`
- [ ] 프로덕션 적용 전 스테이징에서 테스트
- [ ] 대용량 테이블 변경 시 maintenance 모드 고려

---

## 📊 Counter Cache 정합성 검증

### 전체 카운터 검증 쿼리
```sql
-- posts.comments_count 검증
SELECT p.id, p.comments_count AS cached,
       (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS actual
FROM posts p
WHERE p.comments_count != (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id);

-- posts.likes_count 검증
SELECT p.id, p.likes_count AS cached,
       (SELECT COUNT(*) FROM likes l WHERE l.likeable_type = 'Post' AND l.likeable_id = p.id) AS actual
FROM posts p
WHERE p.likes_count != (SELECT COUNT(*) FROM likes l WHERE l.likeable_type = 'Post' AND l.likeable_id = p.id);

-- chat_rooms.unread_count 총합 검증
SELECT cr.id,
       (SELECT SUM(cp.unread_count) FROM chat_participants cp WHERE cp.chat_room_id = cr.id) AS unread_total
FROM chat_rooms cr;
```

### Rails Console에서 수동 리셋
```ruby
# 단일 모델 카운터 리셋
Post.find_each do |post|
  Post.reset_counters(post.id, :comments)
  Post.reset_counters(post.id, :likes)
end

# Polymorphic 카운터 리셋 (주의 필요)
Like.where(likeable_type: 'Post').group(:likeable_id).count.each do |post_id, count|
  Post.where(id: post_id).update_all(likes_count: count)
end
```

### 정기 검증 Rake Task
```ruby
# lib/tasks/counter_cache.rake
namespace :counter_cache do
  desc "Verify and fix all counter caches"
  task verify: :environment do
    # Comments count
    Post.find_each do |post|
      actual = post.comments.count
      if post.comments_count != actual
        puts "Post #{post.id}: #{post.comments_count} -> #{actual}"
        Post.reset_counters(post.id, :comments)
      end
    end

    puts "Counter cache verification complete!"
  end
end
```

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `database-maintenance` | DB 상태 점검 |

---

## 📚 참조 문서

- [CLAUDE.md](../../CLAUDE.md)
- [rules/backend/safety.md](../../rules/backend/safety.md)
