# durable_workflow_drift

**[English README](README.md)**

[durable_workflow](../durable_workflow/)를 위한 `CheckpointStore`의 Drift ORM 구현체.

## 주요 기능

- **타입 안전 쿼리** — Drift의 쿼리 빌더와 코드 생성을 통한 타입 안전성
- **리액티브 스트림** — `watchExecution()`, `watchExecutionsByStatus()`, `watchCheckpoints()`로 실시간 UI 업데이트
- **자동 스키마 마이그레이션** — Drift 내장 마이그레이션 시스템
- **동일 스키마** — `durable_workflow_sqlite`와 동일한 5개 테이블, 인덱스, PRAGMA 설정
- **Flutter 호환** — `sqlite3_flutter_libs`로 모바일/데스크톱 지원

## 사용법

```dart
import 'package:drift/native.dart';
import 'package:durable_workflow_drift/durable_workflow_drift.dart';

// 데이터베이스 열기
final db = DurableWorkflowDatabase(NativeDatabase.createInBackground('workflow.db'));
final store = DriftCheckpointStore(db);

// DurableEngine과 함께 사용
final engine = DurableEngineImpl(store: store);

// Drift 전용: 리액티브 쿼리
store.watchExecution('exec-1').listen((execution) {
  print('Status: ${execution?.status}');
});
```

## 설치

```yaml
dependencies:
  durable_workflow_drift: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  drift_dev: ^2.22.0
```

코드 생성 실행:
```bash
dart run build_runner build
```

## 아키텍처

```
DriftCheckpointStore
  └─ DurableWorkflowDatabase (Drift @DriftDatabase)
       ├─ Workflows 테이블
       ├─ WorkflowExecutions 테이블
       ├─ StepCheckpoints 테이블
       ├─ WorkflowTimers 테이블
       └─ WorkflowSignals 테이블
```

## 테스트

```
Drift 스토어 테스트: 31개 ✅
```

스키마 검증, 전체 엔티티 CRUD 작업, 리액티브 쿼리, 전체 라이프사이클 통합, 엣지 케이스를 포함합니다.

## 라이선스

라이선스 정보는 저장소 루트를 참조하세요.
