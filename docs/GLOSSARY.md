# 용어집

설계 문서(ARCHITECTURE·SECURITY·PRD·CONTRACTS)에서 풀어 쓰지 않고 쓰는 용어의
정의. 본문에서 처음 만나면 여기로 오면 된다.

**마스터 비밀번호 (master password)** — 사용자가 기억하는 유일한 비밀.
디스크 어디에도 저장되지 않으며, 모든 키가 여기서 파생된다.

**PDK (Password-Derived Key)** — 마스터 비밀번호를 PBKDF2에 통과시켜 얻는
32바이트 키. 직접 쓰이지 않고 HKDF의 입력이 된다.

**PBKDF2** — 비밀번호를 키로 바꾸는 표준 함수. 같은 계산을 수십만 번(이 앱은
600,000회) 반복시켜 무차별 대입 한 번의 비용을 비싸게 만든다.

**salt** — 비밀번호마다 섞는 32바이트 난수. 비밀이 아니다 — 목적은 미리 계산한
표(레인보우 테이블)를 무력화하는 유일성이지 은닉이 아니다.

**HKDF** — 하나의 키에서 용도별 하위 키를 안전하게 뽑는 함수. 용도 라벨(info)이
다르면 결과 키가 완전히 달라져, 한 키가 유출돼도 다른 용도의 키를 역산할 수 없다.
이 분리를 **도메인 분리**라 부른다.

**dbKey** — PDK에서 HKDF로 파생한 DB 전용 키. SQLCipher가 DB 파일 전체를
암호화하는 데 쓴다.

**KEK (Key-Encryption Key)** — PDK에서 HKDF로 파생한 래핑 전용 키. MEK를
감싸는(암호화하는) 데만 쓴다.

**MEK (Master Encryption Key)** — 시크릿 값을 실제로 암호화하는 32바이트
난수 키. 볼트 생성 때 한 번 만들어지고, KEK로 감싸(wrapped) DB 안에 저장된다.
비밀번호를 바꿔도 MEK 자체는 다시 감싸기만 하면 되므로 전체 데이터 재암호화가
필요 없다 — 이것이 MEK를 두는 이유다.

**wrap / unwrap** — 키를 다른 키로 암호화해 보관하는 것(wrap), 꺼내 푸는 것
(unwrap). "wrappedMek"은 KEK로 감싼 MEK.

**AES-256-GCM** — 이 앱의 대칭 암호. 암호화와 동시에 위·변조를 탐지하는
인증 태그를 만든다. 태그 검증에 실패하면 복호화 자체가 거부된다.

**AAD (Additional Authenticated Data)** — GCM 암호문에 함께 봉인하는 문맥
데이터. 이 앱은 각 시크릿의 행 id와 버전을 AAD로 묶는다 — 암호문을 다른 행이나
과거 버전 자리에 옮겨 심으면 태그 검증이 실패한다(치환·롤백 방어).

**recordVersion** — 시크릿 값이 바뀔 때마다 1씩 오르는 정수. AAD에 들어가므로
"옛 암호문을 되돌려 넣는" 롤백이 탐지된다.

**SQLCipher** — SQLite DB 파일 전체를 암호화하는 확장. 올바른 키 없이 열면
파일이 DB인지조차 알 수 없다(`file is not a database`).

**PRAGMA key / rekey** — SQLCipher에 키를 공급하는 명령(key)과 파일 전체를
새 키로 다시 암호화하는 명령(rekey).

**cipher 하드핀 (hard-pin)** — SQLCipher의 페이지 크기·HMAC 종류 같은 온디스크
파라미터를 코드에서 고정 선언하는 것. 라이브러리 기본값이 바뀌어도 기존 볼트를
계속 열 수 있고, 다운그레이드된 파라미터를 거부한다.

**sidecar** — DB 옆에 두는 작은 평문 JSON(`key_box.vault.json`). salt와 KDF
파라미터만 담는다. DB를 열려면 salt가 필요한데 salt를 DB 안에만 두면 순환이
생기므로 밖에 둔다. 비밀은 담지 않는다.

**.kbx** — 백업/내보내기 아카이브 파일. 포맷 v3부터 값뿐 아니라 이름·메모 등
메타데이터도 MEK로 암호화한다.

**키 회전 (rotation)** — 마스터 비밀번호 변경. 새 salt로 새 PDK/KEK/dbKey를
만들고, MEK를 다시 감싸고(rewrap), DB를 rekey한다. 시크릿 값 자체는 그대로다.

**zero-out** — 민감한 바이트 배열(Uint8List)을 쓰고 난 뒤 0으로 덮어쓰는 것.
Dart의 가비지 컬렉터는 즉시 회수를 보장하지 않으므로 직접 지운다. 불변인
Dart String에는 원리적으로 불가능하다 — 이 한계는 SECURITY.md가 다룬다.

**dogfood** — 만든 사람이 자기 실사용 데이터로 직접 쓰는 것. 이 프로젝트의
완성도 기준선 A가 "저자가 매일 dogfood할 수 있는 상태"다.

**기준선 A / B** — A = 저자 개인 실사용 가능(도달·실증됨). B = 남에게 설치를
권할 수 있는 배포 품질(복구 코드·Developer ID 서명·공증 등이 남음).
판정과 증거는 `completeness-scorecard.md`.

**entitlements** — macOS 앱이 OS에 선언하는 권한 목록. 이 앱의 Release 빌드에는
네트워크 권한이 없다.

**hardened runtime / get-task-allow** — macOS의 프로세스 보호 장치와, 디버거
부착을 허용하는 예외 플래그. 정식 서명(Developer ID) 전의 ad-hoc 빌드는
get-task-allow가 자동으로 붙어 메모리 덤프 방어가 미완성이다(수용된 B 격차).

**Drift / DAO** — 이 앱의 DB 라이브러리(Drift)와, 테이블별 쿼리 창구 객체(DAO,
Data Access Object). 모든 SQL은 DAO를 통해 파라미터화되어 나간다.

**Riverpod / provider** — 상태 관리 라이브러리와 그 단위. UI는 provider를
구독(watch)하고, provider는 DB 스트림이나 다른 provider에서 파생된다.
