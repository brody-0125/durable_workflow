# durable_workflow_sqlite

**[English README](README.md)**

[`durable_workflow`](../durable_workflow/) 라이브러리를 위한 `CheckpointStore`의 SQLite 구현체.
[sqlite3](https://pub.dev/packages/sqlite3) FFI를 사용하여 고성능 로컬 영속성을 제공합니다.

## 주요 기능

- **SQLite3 FFI** -- `package:sqlite3`를 통한 네이티브 직접 접근, 플랫폼 채널 불필요
- **WAL 저널 모드** -- 읽기/쓰기 동시성으로 최적의 성능
- **자동 스키마 마이그레이션** -- `PRAGMA user_version` 기반 버전 관리
- **ACID 트랜잭션** -- 모든 쓰기가 `BEGIN IMMEDIATE`로 일관성 보장
- **파일 및 인메모리 모드** -- 프로덕션용 파일 기반, 테스트용 인메모리

## 시작하기

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

// 파일 기반 (프로덕션)
final store = SqliteCheckpointStore.file('workflows.db');
final engine = DurableEngineImpl(store: store);

final result = await engine.run<String>('my_workflow', (ctx) async {
  return await ctx.step('greet', () async => 'Hello!');
});

engine.dispose();
store.close();
```

```dart
// 인메모리 (테스트)
final store = SqliteCheckpointStore.inMemory();
```

## 설치

`pubspec.yaml`에 추가:

```yaml
dependencies:
  durable_workflow: ^0.1.0
  durable_workflow_sqlite: ^0.1.0
```

## SQLite 스키마

5개 테이블 + 5개 인덱스:

| 테이블 | 역할 |
|--------|------|
| `workflows` | 워크플로우 타입 정의 (id, type, version) |
| `workflow_executions` | 실행 인스턴스 (status, TTL, guarantee) |
| `step_checkpoints` | 각 단계의 INTENT/COMPLETED/FAILED/COMPENSATED 기록 |
| `workflow_timers` | 지속형 타이머 레코드 (fire_at, PENDING/FIRED) |
| `workflow_signals` | 외부 이벤트 레코드 (PENDING/DELIVERED/EXPIRED) |

### PRAGMA 설정

```sql
PRAGMA journal_mode = WAL;       -- 읽기/쓰기 동시성
PRAGMA foreign_keys = ON;        -- 참조 무결성
PRAGMA synchronous = NORMAL;     -- 쓰기 성능 (WAL 모드에서 안전)
PRAGMA busy_timeout = 5000;      -- 동시 접근 재시도 대기 5초
```

## API

### SqliteCheckpointStore

| 생성자 | 설명 |
|--------|------|
| `SqliteCheckpointStore(Database db)` | 이미 열린 데이터베이스로 생성 |
| `SqliteCheckpointStore.file(String path)` | 파일 기반 데이터베이스 열기 |
| `SqliteCheckpointStore.inMemory()` | 인메모리 데이터베이스 열기 |

| 메서드 | 설명 |
|--------|------|
| `close()` | 기본 데이터베이스 연결 닫기 |

모든 `CheckpointStore` 인터페이스 메서드가 구현되어 있습니다:
- `saveCheckpoint` / `loadCheckpoints` -- 단계 체크포인트 영속성
- `saveExecution` / `loadExecution` / `loadExecutionsByStatus` -- 실행 상태
- `saveTimer` / `loadPendingTimers` -- 지속형 타이머 영속성
- `saveSignal` / `loadPendingSignals` -- 시그널 영속성

### 스키마 유틸리티

| 내보내기 | 설명 |
|----------|------|
| `schemaVersion` | 현재 스키마 버전 번호 |
| `migrate(Database db)` | 보류 중인 스키마 마이그레이션 적용 |

## 테스트

```
SQLite 스토어 테스트: 59개 ✅
```

CRUD 작업, PRAGMA 검증, 스키마 마이그레이션, 외래 키 제약 조건, 엣지 케이스를 포함합니다.

## 라이선스

라이선스 정보는 저장소 루트를 참조하세요.
