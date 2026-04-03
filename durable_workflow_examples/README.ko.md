# durable_workflow_examples — 유즈케이스 카탈로그

**[English README](README.md)**

[`durable_workflow`](../durable_workflow/) 라이브러리의 유즈케이스 카탈로그.
7개 카테고리에 걸쳐 실제 지속형 워크플로우 패턴을 시연합니다.

## 카테고리 개요

| # | 카테고리 | 핵심 문제 | 대표 유즈케이스 |
|---|---------|-----------|---------------|
| 1 | [E-Commerce](#1-e-commerce) | 주문→결제→배송 멀티스텝 트랜잭션 | 체크아웃, 환불, 재고 차감 |
| 2 | [File Sync & Upload](#2-file-sync--upload) | 대용량 파일 청크 업로드/동기화 | 이력서 업로드, 클라우드 동기화 |
| 3 | [IoT & Device Provisioning](#3-iot--device-provisioning) | 디바이스 등록→설정→펌웨어 업데이트 | 스마트홈, BLE 프로비저닝 |
| 4 | [Finance & Banking](#4-finance--banking) | 송금→검증→정산 규제 준수 워크플로우 | KYC, P2P 송금, 적립 |
| 5 | [Desktop App](#5-desktop-app) | 설치→마이그레이션→설정 장시간 작업 | 인스톨러, DB 마이그레이션, 배치 |
| 6 | [Messaging & Chat](#6-messaging--chat) | 메시지 전송 보장, 오프라인 큐 | 메시지 재전송, 미디어 업로드 |
| 7 | [Healthcare](#7-healthcare) | 환자 등록→보험 확인→예약 다단계 접수 | 환자 온보딩, 처방 워크플로우 |

## 1. E-Commerce

### 문제 정의
체크아웃 플로우는 `재고 확인 → 결제 처리 → 주문 생성 → 배송 요청`의 멀티스텝 프로세스입니다.
중간 단계에서 앱이 크래시되면 결제는 되었으나 주문이 생성되지 않는 **불일치 상태**가 발생합니다.

### durable_workflow 적용 시 이점
- 각 단계(재고 확인, 결제, 주문 생성)가 **체크포인트**로 영속화
- 결제 성공 후 크래시 → 재시작 시 결제 단계는 **캐시에서 스킵**, 주문 생성부터 재개
- 배송 실패 시 **saga 보상**으로 결제 자동 환불

> 예제: [`lib/src/ecommerce/checkout_workflow.dart`](lib/src/ecommerce/checkout_workflow.dart)

## 2. File Sync & Upload

### 문제 정의
대용량 파일을 청크 단위로 업로드할 때, 중간에 네트워크 단절이나 앱 종료가 발생하면
처음부터 다시 시작해야 합니다.

### durable_workflow 적용 시 이점
- 각 청크 업로드가 **체크포인트된 단계**
- 100개 중 47번째 청크에서 크래시 → 재시작 시 48번째부터 재개
- 업로드 실패 → saga 보상으로 부분 업로드 정리

> 예제: [`lib/src/file_sync/chunked_upload_workflow.dart`](lib/src/file_sync/chunked_upload_workflow.dart)

## 3. IoT & Device Provisioning

### 문제 정의
디바이스 프로비저닝은 `탐색 → 인증 → 설정 → 펌웨어 업데이트 → 검증`의 다단계 과정입니다.
중간에 실패하면 디바이스가 알 수 없는 상태에 놓이게 됩니다.

### durable_workflow 적용 시 이점
- 각 프로비저닝 단계가 체크포인트되고 재시도 가능
- 펌웨어 업데이트 중 BLE 연결 끊김 → 마지막 성공 단계부터 재개
- 프로비저닝 실패 → saga 보상으로 디바이스를 공장 초기화 상태로 복원

> 예제: [`lib/src/iot_device/provisioning_workflow.dart`](lib/src/iot_device/provisioning_workflow.dart)

## 4. Finance & Banking

### 문제 정의
KYC 온보딩 같은 금융 워크플로우는 `신원 확인 → 문서 검증 → 리스크 평가 → 계좌 생성`을 포함합니다.
이 과정은 원자적으로 완료되어야 하며 규제를 준수해야 합니다.

### durable_workflow 적용 시 이점
- 각 검증 단계가 감사 추적과 함께 지속적으로 영속화
- 리스크 평가 중 앱 크래시 → 문서 재업로드 없이 재개
- 계좌 생성 실패 → saga 보상으로 모든 검증 기록 되돌림

> 예제: [`lib/src/finance/kyc_onboarding_workflow.dart`](lib/src/finance/kyc_onboarding_workflow.dart)

## 5. Desktop App

### 문제 정의
데스크톱 애플리케이션은 데이터베이스 마이그레이션, 데이터 임포트, 배치 처리 등
장시간 작업을 수행합니다. 중단되면 데이터 손상이나 불완전한 상태가 발생합니다.

### durable_workflow 적용 시 이점
- 각 마이그레이션/임포트 단계가 개별적으로 체크포인트됨
- 마이그레이션 중 프로세스 종료 → 재시작 시 정확한 단계부터 재개
- 마이그레이션 실패 → saga 보상으로 완료된 단계 롤백

> 예제: [`lib/src/desktop/data_migration_workflow.dart`](lib/src/desktop/data_migration_workflow.dart)

## 6. Messaging & Chat

### 문제 정의
오프라인 메시지 큐잉은 전송 보장이 필요합니다: `작성 → 암호화 → 미디어 업로드 → 전송 → 확인`.
단계 사이에 앱이 크래시되면 메시지가 유실될 수 있습니다.

### durable_workflow 적용 시 이점
- 메시지 전송 파이프라인이 체크포인트된 단계의 지속형 워크플로우
- 미디어 업로드 후 크래시 → 재시작 시 업로드 스킵, 전송 단계로 진행
- 지속형 시그널로 서버 전달 확인 대기 가능

> 예제: [`lib/src/messaging/offline_message_queue_workflow.dart`](lib/src/messaging/offline_message_queue_workflow.dart)

## 7. Healthcare

### 문제 정의
환자 온보딩은 `등록 → 보험 확인 → 동의 → 예약 스케줄링`을 포함합니다.
불완전한 온보딩은 누락된 기록과 스케줄링 실패로 이어집니다.

### durable_workflow 적용 시 이점
- 각 온보딩 단계가 지속적으로 영속화
- 보험 확인 중 앱 크래시 → 환자 데이터 재입력 없이 재개
- 스케줄링 실패 → saga 보상으로 관련 부서에 알림

> 예제: [`lib/src/healthcare/patient_onboarding_workflow.dart`](lib/src/healthcare/patient_onboarding_workflow.dart)

---

## 예제 실행 방법

```bash
# 전체 예제 실행
cd durable_workflow_examples
dart run lib/src/ecommerce/checkout_workflow.dart

# 각 카테고리별 예제
dart run lib/src/file_sync/chunked_upload_workflow.dart
dart run lib/src/iot_device/provisioning_workflow.dart
dart run lib/src/finance/kyc_onboarding_workflow.dart
dart run lib/src/desktop/data_migration_workflow.dart
dart run lib/src/messaging/offline_message_queue_workflow.dart
dart run lib/src/healthcare/patient_onboarding_workflow.dart
```

---

## 알려진 한계 및 API 개선 필요 사항

이 예제들은 `durable_workflow` 라이브러리의 현재 API를 있는 그대로 사용합니다.
실용적으로 인지해야 할 한계점들을 명시합니다.

### 1. ~~보상 클로저가 step 결과를 직접 캡처할 수 없음~~ (해결됨)

`compensate:`가 step 결과를 인자로 받도록 시그니처가 변경되었습니다 (`Future<void> Function(T result)?`):

```dart
final txId = await ctx.step<String>(
  'process_payment',
  () => processPayment(orderId, amount),
  compensate: (result) => refundPayment(result),
);
```

### 2. ~~커스텀 객체의 체크포인트 직렬화~~ (해결됨)

`WorkflowContext.step<T>()`에 `serialize`/`deserialize` 파라미터가 추가되어,
커스텀 객체의 체크포인트 저장 및 복구가 안전하게 지원됩니다.

```dart
final device = await ctx.step<DeviceInfo>(
  'ble_connect',
  () => scanAndConnect(targetMac),
  serialize: (info) => jsonEncode(info.toJson()),
  deserialize: (data) => DeviceInfo.fromJson(
    jsonDecode(data) as Map<String, dynamic>,
  ),
);
```

**적용된 예제:** IoT(`DeviceInfo`), Finance(`IdVerificationResult`)

### 3. 모든 예제가 InMemoryCheckpointStore 사용

프로세스 종료 시 전부 유실됩니다. 프로덕션에서는 `SqliteCheckpointStore`(`durable_workflow_sqlite`)
또는 `DriftCheckpointStore`(`durable_workflow_drift`)로 교체하세요.
`InMemoryCheckpointStore`는 테스트/시연 전용이며,
`package:durable_workflow/testing.dart`에서 import해야 합니다.

### 4. 동적 step 이름의 복구 안전성

루프 기반 step (`migrate_batch_$i`, `upload_chunk_$i`)은 파라미터가
크래시 전후로 동일해야 step 이름이 일치합니다. 프로덕션에서는 워크플로우
input을 체크포인트에 저장하여 보장해야 합니다.

---

## 프로젝트 구조

```
durable_workflow_examples/
└── lib/src/
    ├── ecommerce/       체크아웃 워크플로우
    ├── file_sync/       청크 업로드 워크플로우
    ├── iot_device/      디바이스 프로비저닝 워크플로우
    ├── finance/         KYC 온보딩 워크플로우
    ├── desktop/         데이터 마이그레이션 워크플로우
    ├── messaging/       오프라인 메시지 큐 워크플로우
    └── healthcare/      환자 온보딩 워크플로우
```

## 라이선스

라이선스 정보는 저장소 루트를 참조하세요.
