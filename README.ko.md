# durable_workflow

[![Dart](https://img.shields.io/badge/Dart-%5E3.4-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests: 324](https://img.shields.io/badge/Tests-324%20passed-brightgreen)](#테스트-결과)

**[English README](README.md)**

> Dart를 위한 크래시에 안전한 내구성 워크플로우 실행 라이브러리 — 로컬 SQLite 기반, 외부 인프라 불필요.

---

## 왜 durable_workflow인가?

현대 앱은 결제, 파일 업로드, 디바이스 프로비저닝, 데이터 파이프라인 등 다단계 프로세스를 실행합니다. 이러한 프로세스가 중간에 크래시되면 일관성이 깨진 상태가 되며 복구가 어렵습니다.

**durable_workflow**는 워크플로우의 모든 단계를 로컬 데이터베이스에 영속화하여 이 문제를 해결합니다. 크래시나 재시작이 발생하면, 마지막으로 완료된 단계부터 자동으로 재개됩니다. 클라우드 서비스, 메시지 큐, 외부 의존성이 필요 없습니다.

**핵심 장점:**

- **제로 인프라** — 로컬 SQLite만으로 디바이스에서 완전히 실행
- **크래시 복구** — 중단된 지점에서 정확히 재개
- **보상 처리 (Saga)** — 실패 시 완료된 단계를 자동으로 역순 롤백
- **순수 Dart** — 서버, 데스크톱, CLI, Flutter 모두 지원

---

## 패키지

| 패키지 | 설명 |
|--------|------|
| [`durable_workflow`](durable_workflow/) | 순수 Dart 코어 엔진 (제로 의존성) |
| [`durable_workflow_sqlite`](durable_workflow_sqlite/) | sqlite3 FFI 기반 SQLite 영속성 |
| [`durable_workflow_drift`](durable_workflow_drift/) | Drift ORM 영속성 (리액티브 쿼리) |
| [`durable_workflow_examples`](durable_workflow_examples/) | 실제 유즈케이스 카탈로그 (7개 카테고리) |
| [`durable_workflow_flutter`](durable_workflow_flutter/) | Flutter 플랫폼 어댑터 (WorkManager / BGTask) |

---

## 설치

`pubspec.yaml`에 패키지를 추가하세요:

```yaml
dependencies:
  durable_workflow: ^0.1.0
  durable_workflow_sqlite: ^0.1.0   # SQLite 영속성
  # 또는
  durable_workflow_drift: ^0.1.0    # Drift ORM 영속성
```

> **시스템 요구사항:** SQLite FFI 바인딩을 위해 `libsqlite3-dev`가 필요합니다.
>
> ```bash
> # Ubuntu / Debian
> sudo apt-get install libsqlite3-dev
>
> # macOS (시스템에 포함됨)
> # 추가 설치 불필요
> ```

---

## 빠른 시작

### 인메모리 (테스트 / 프로토타이핑)

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

final engine = DurableEngineImpl(store: InMemoryCheckpointStore());

final result = await engine.run<String>('greet', (ctx) async {
  final name = await ctx.step('fetch', () async => 'World');
  return 'Hello, $name!';
});

print(result); // Hello, World!
engine.dispose();
```

### SQLite 영속성 사용 (프로덕션)

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

final store = SqliteCheckpointStore.file('workflows.db');
final engine = DurableEngineImpl(store: store);

final result = await engine.run<String>('order', (ctx) async {
  // Step 1: 검증 — 완료 시 영속화
  final validated = await ctx.step('validate', () => validateOrder(input));

  // Step 2: 결제 — 롤백을 위한 보상 처리 포함
  final payment = await ctx.step('pay',
    () => chargePayment(validated.amount),
    compensate: () => refundPayment(payment.txId),
    retry: RetryPolicy.exponential(maxAttempts: 3),
  );

  // Step 3: 24시간 대기 — 프로세스 재시작에도 유지
  await ctx.sleep('wait_shipping', Duration(hours: 24));

  // Step 4: 외부 이벤트 대기
  final confirmed = await ctx.waitSignal<bool>('delivery_confirmed');

  return 'Order ${confirmed ? "delivered" : "pending"}';
});

engine.dispose();
store.close();
```

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| **체크포인트 / 재개** | 각 단계가 영속화되며, 크래시 복구 시 마지막 체크포인트에서 재개 |
| **재시도 정책** | 지터(jitter) 포함 지수 백오프, 단계별 설정 가능 |
| **Saga 보상** | 실패 시 완료된 단계를 역순으로 롤백 |
| **지속형 타이머** | `ctx.sleep()`이 DB에 영속화되어 프로세스 재시작에도 유지 |
| **지속형 시그널** | `ctx.waitSignal()` + `engine.sendSignal()`로 외부 이벤트 조율 |
| **복구 스캐너** | 재시작 시 중단된 워크플로우를 자동 감지 및 재개 |
| **플러그형 영속성** | `CheckpointStore` 인터페이스 — InMemory, SQLite, Drift 교체 가능 |
| **제로 의존성** | 코어 패키지에 외부 의존성 없음 |

---

## 아키텍처

```
┌──────────────────────────────────────────────────────────┐
│                       사용자 코드                         │
│   engine.run('order', (ctx) async {                      │
│     await ctx.step('pay', () => charge(...));             │
│     await ctx.sleep('wait', Duration(hours: 24));        │
│     await ctx.waitSignal('confirmed');                   │
│   });                                                    │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│                   DurableEngineImpl                       │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  │
│  │ StepExecutor │ │ TimerManager │ │  SignalManager    │  │
│  │ 체크포인트/   │ │ dart:async + │ │  Completer<T> +   │  │
│  │ 재개 루프     │ │ DB 영속화    │ │  DB 영속화        │  │
│  └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘  │
│         │                │                   │            │
│  ┌──────▼───────┐ ┌──────▼───────────────────▼─────────┐ │
│  │RetryExecutor │ │         RecoveryScanner             │ │
│  │ 백오프 +     │ │ RUNNING/SUSPENDED 워크플로우 스캔    │ │
│  │ 지터         │ │ 타이머/시그널 복원 → 재개             │ │
│  └──────┬───────┘ └───────────────────────────────────┘  │
│         │                                                │
│  ┌──────▼───────┐                                        │
│  │    Saga      │                                        │
│  │ Compensator  │ 실패 시 역순 보상 실행                   │
│  └──────────────┘                                        │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│              CheckpointStore (추상 인터페이스)              │
│                                                          │
│  InMemory (테스트) │ SQLite (프로덕션) │ Drift (리액티브)  │
└──────────────────────────────────────────────────────────┘
```

---

## 유즈케이스

[`durable_workflow_examples`](durable_workflow_examples/) 패키지에 7개 카테고리의 실제 예제가 포함되어 있습니다:

| 카테고리 | 예제 |
|----------|------|
| **이커머스** | 환불 보상이 포함된 다단계 결제 |
| **파일 동기화 & 업로드** | 재개 가능한 청크 업로드 |
| **IoT & 디바이스** | 다단계 디바이스 프로비저닝 워크플로우 |
| **금융 & 뱅킹** | KYC 인증, P2P 송금, 규제 워크플로우 |
| **데스크톱 앱** | 장기 실행 설치 작업, DB 마이그레이션, 배치 처리 |
| **메시징 & 채팅** | 보장된 메시지 전달, 오프라인 큐 |
| **헬스케어** | 환자 등록, 처방 워크플로우 |

---

## 테스트 결과

```
durable_workflow:          234개 테스트 ✅  (단위 + 통합)
durable_workflow_sqlite:    59개 테스트 ✅
durable_workflow_drift:     31개 테스트 ✅
──────────────────────────────────────
합계:                      324개 테스트 ✅
```

CI는 **Ubuntu latest**에서 Dart **stable** 및 **beta** SDK로 실행됩니다. 최소 커버리지 기준: **70%**.

---

## 프로젝트 구조

```
durable_workflow/
├── durable_workflow/              순수 Dart 코어 (제로 의존성)
│   ├── lib/src/
│   │   ├── model/                 도메인 모델 (불변, JSON 직렬화 가능)
│   │   ├── context/               WorkflowContext 인터페이스 + 구현
│   │   ├── engine/                실행 엔진 (7개 컴포넌트)
│   │   └── persistence/           CheckpointStore 인터페이스 + InMemory 구현
│   ├── test/                      234개 테스트 (단위 + 통합)
│   └── example/                   실행 가능한 예제
├── durable_workflow_sqlite/       SQLite 영속성 구현
│   ├── lib/src/                   SqliteCheckpointStore + 스키마 + 마이그레이션
│   └── test/                      59개 테스트
├── durable_workflow_drift/        Drift ORM 영속성 구현
│   ├── lib/src/                   DriftCheckpointStore + 테이블 + 리액티브 쿼리
│   └── test/                      31개 테스트
├── durable_workflow_flutter/      Flutter 플랫폼 어댑터 (Phase 2)
├── durable_workflow_examples/     실제 유즈케이스 카탈로그
│   └── lib/src/                   7개 카테고리의 워크플로우 예제
└── docs/                          설계 문서
```

---

## 문서

| 문서 | 설명 |
|------|------|
| [코어 패키지](durable_workflow/README.md) | API 레퍼런스 및 시작 가이드 |
| [SQLite 패키지](durable_workflow_sqlite/README.md) | SQLite 영속성 설정 |
| [Drift 패키지](durable_workflow_drift/README.md) | Drift ORM 영속성 설정 |
| [Flutter 패키지](durable_workflow_flutter/README.md) | Flutter 라이프사이클 어댑터 및 위젯 |
| [예제](durable_workflow_examples/README.md) | 실제 유즈케이스 카탈로그 |

---

## 기여하기

```bash
# 저장소 클론
git clone https://github.com/brody-0125/durable_workflow.git
cd durable_workflow

# 시스템 의존성 설치 (Linux)
sudo apt-get install libsqlite3-dev

# 특정 패키지 테스트 실행
cd durable_workflow
dart pub get
dart analyze --fatal-warnings
dart test
```

---

## 라이선스

MIT — 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
