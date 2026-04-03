# durable_workflow_flutter

[durable_workflow](../durable_workflow/)를 위한 Flutter 플랫폼 어댑터. 라이프사이클 인식 복구, 선택적 백그라운드 스케줄링, 워크플로우 모니터링 위젯을 제공합니다.

---

## 기능

| 기능 | 설명 |
|------|------|
| **포그라운드 복구** | 앱이 포그라운드로 복귀할 때 중단된 워크플로우를 자동 재개 |
| **백그라운드 어댑터** | WorkManager(Android) / BGTask(iOS) 통합을 위한 추상 인터페이스 |
| **DurableWorkflowProvider** | 엔진 초기화 + 라이프사이클 바인딩을 하나의 위젯으로 |
| **ExecutionMonitor** | `StreamBuilder` 기반 실시간 워크플로우 상태 위젯 |
| **ExecutionListTile** | 상태 아이콘, 취소/재시도 액션이 포함된 Material ListTile |

## 빠른 시작

```dart
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';

void main() {
  runApp(
    DurableWorkflowProvider(
      store: SqliteCheckpointStore(path: 'workflows.db'),
      workflowRegistry: {
        'order_processing': orderWorkflow,
      },
      child: const MyApp(),
    ),
  );
}

// 하위 위젯에서 엔진 접근
final engine = DurableWorkflowProvider.of(context);
await engine.run('order_processing', orderWorkflow);
```

## 아키텍처

```
DurableWorkflowProvider
├── DurableEngineImpl          (코어 엔진)
├── AppLifecycleObserver       (WidgetsBindingObserver)
│   ├── resumed → ForegroundRecovery.scan()
│   ├── paused  → BackgroundAdapter.scheduleRecovery()
│   └── detached→ dispose()
├── ForegroundRecovery         (디바운스된 RecoveryScanner)
└── BackgroundAdapter          (선택적, 플랫폼별)
    ├── WorkManagerAdapter     (Android - 사용자 구현)
    └── BgTaskAdapter          (iOS - 사용자 구현)
```

## 보장 수준 모델

| 수준 | 동작 |
|------|------|
| **포그라운드 내구성** | 앱 활성 중 워크플로우 완료 보장. 크래시 후 재시작 시 자동 재개. |
| **최선 노력 백그라운드** | WorkManager/BGTask가 복구를 시도. **보장 안 됨.** |
| **최소 1회 실행** | 멱등성 키로 중복 부작용 방지. |

> 백그라운드 실행은 최선 노력(best-effort)입니다. iOS ML 스케줄러와 Android OEM 배터리 최적화가 백그라운드 태스크 실행을 막을 수 있습니다.

## 의존성

```yaml
dependencies:
  flutter: sdk
  durable_workflow: path ../durable_workflow
```

플랫폼 플러그인(workmanager 등)은 직접 의존하지 않습니다. 사용자가 `BackgroundAdapter`를 구현하고 자신의 프로젝트에 플랫폼 플러그인을 추가합니다.

## 테스트

```bash
cd durable_workflow_flutter
flutter test
```
