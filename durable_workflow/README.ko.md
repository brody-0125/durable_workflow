# durable_workflow

**[English README](README.md)**

Dart를 위한 내구성 있는 워크플로우. 제로 의존성으로
체크포인트/재개 워크플로우 실행을 제공합니다.

## 주요 기능

- **체크포인트/재개** -- 워크플로우의 각 단계가 실행 전에 영속화됩니다.
  크래시 시 엔진이 완료된 단계를 캐시에서 재생하고 마지막 체크포인트부터 이어서 실행합니다.
- **재시도** -- 고정 간격 또는 지수 백오프 정책으로 단계별 재시도가 가능합니다.
- **Saga 보상** -- 각 단계에 `compensate` 콜백을 등록하면,
  실패 시 엔진이 역순으로 보상 작업을 실행합니다.
- **지속형 시그널** -- `ctx.waitSignal()`로 워크플로우를 일시 중단하고,
  `engine.sendSignal()`로 외부 이벤트가 도착할 때까지 대기합니다.
- **지속형 타이머** -- `ctx.sleep()`이 타이머 레코드를 영속화하여
  프로세스 재시작에도 지연이 유지됩니다.
- **플러그형 영속성** -- `CheckpointStore`를 구현하여 SQLite, Drift, Hive 등
  원하는 백엔드를 사용할 수 있습니다. 테스트 전용 `InMemoryCheckpointStore`
  (`package:durable_workflow/testing.dart`에서 import)와
  프로덕션용 `SqliteCheckpointStore`(`durable_workflow_sqlite`)를 기본 제공합니다.

## 시작하기

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart'; // InMemoryCheckpointStore (테스트 전용)

Future<void> main() async {
  final engine = DurableEngineImpl(store: InMemoryCheckpointStore());

  final result = await engine.run<String>('greet', (ctx) async {
    final name = await ctx.step<String>('fetch_name', () async => 'World');
    return 'Hello, $name!';
  });

  print(result); // Hello, World!
  engine.dispose();
}
```

## 설치

`pubspec.yaml`에 추가:

```yaml
dependencies:
  durable_workflow: ^0.1.0
```

SQLite 영속성이 필요한 경우:

```yaml
dependencies:
  durable_workflow_sqlite: ^0.1.0
```

## API 개요

### DurableEngine

최상위 오케스트레이터:

| 메서드 | 설명 |
|--------|------|
| `run<T>(type, body, {input, ttl, guarantee})` | 워크플로우 실행 |
| `sendSignal(execId, name, payload)` | 대기 중인 워크플로우에 시그널 전달 |
| `cancel(execId)` | 실행 중인 워크플로우 취소 |
| `observe(execId)` | 실행 상태 변경 스트림 |

### WorkflowContext

워크플로우 본문에 제공되는 컨텍스트:

| 메서드 | 설명 |
|--------|------|
| `step<T>(name, action, {compensate, retry, idempotencyKey, serialize, deserialize})` | 지속형 단계 실행 |
| `sleep(name, duration)` | 지정된 시간 동안 일시 중단 (지속형 타이머) |
| `waitSignal<T>(name, {timeout})` | 외부 시그널 대기 |

### CheckpointStore

영속성 인터페이스 -- 백엔드에 맞게 구현:

| 메서드 | 설명 |
|--------|------|
| `saveCheckpoint` / `loadCheckpoints` | 단계 체크포인트 CRUD |
| `saveExecution` / `loadExecution` | 실행 상태 CRUD |
| `saveTimer` / `loadPendingTimers` | 지속형 타이머 영속성 |
| `saveSignal` / `loadPendingSignals` | 시그널 영속성 |

### RecoveryScanner

엔진 시작 시 중단된 워크플로우를 재개:

```dart
final scanner = RecoveryScanner(store: store, engine: engine);
final result = await scanner.scan(workflowRegistry: {
  'order_processing': orderWorkflowBody,
});
print('재개: ${result.resumed.length}, 만료: ${result.expired.length}');
```

## 도메인 모델

### 실행 상태 전이도

```
PENDING → RUNNING → COMPLETED
                  → SUSPENDED → RUNNING (타이머/시그널)
                  → FAILED → COMPENSATING → FAILED (최종)
                  → CANCELLED
```

### Sealed 클래스

| 타입 | 변형 |
|------|------|
| `ExecutionStatus` | Pending, Running, Suspended, Completed, Failed, Compensating, Cancelled |
| `RetryPolicy` | RetryPolicyNone, RetryPolicyFixed, RetryPolicyExponential |

### 열거형 (Enum)

| 타입 | 값 |
|------|-----|
| `WorkflowGuarantee` | foregroundOnly, bestEffortBackground |
| `StepStatus` | intent, completed, failed, compensated |
| `TimerStatus` | pending, fired, cancelled |
| `SignalStatus` | pending, delivered, expired |

## 아키텍처

```
durable_workflow/
  lib/src/
    model/          # 값 객체: ExecutionStatus, RetryPolicy, StepCheckpoint 등
    context/        # WorkflowContext 인터페이스 + 구현
    engine/         # DurableEngine, StepExecutor, RetryExecutor, SagaCompensator,
                    #   TimerManager, SignalManager, RecoveryScanner
    persistence/    # CheckpointStore 인터페이스 + InMemoryCheckpointStore (테스트 전용)
  lib/
    testing.dart    # 테스트 전용 배럴 (InMemoryCheckpointStore export)
```

### 엔진 컴포넌트

| 컴포넌트 | 역할 |
|----------|------|
| `DurableEngineImpl` | 최상위 오케스트레이터 — 실행, 취소, 관찰, 시그널 |
| `StepExecutor` | 개별 단계의 체크포인트/재개 루프 |
| `RetryExecutor` | 지터가 포함된 지수 백오프 계산 |
| `SagaCompensator` | 역순 보상 실행 |
| `TimerManager` | 지속형 타이머 영속성 + dart:async 폴링 |
| `SignalManager` | Completer 기반 시그널 전달 + DB 영속성 |
| `RecoveryScanner` | 시작 시 RUNNING/SUSPENDED 실행 스캔 |

## 예제

완전한 실행 가능 예제는 [`example/order_processing.dart`](example/order_processing.dart)를
참조하세요.

## 테스트

```
모델 + 인터페이스 테스트:  100개
엔진 단위 테스트:           94개
영속성 테스트:              18개
통합 테스트:                22개
합계:                      234개
```

## 라이선스

라이선스 정보는 저장소 루트를 참조하세요.
