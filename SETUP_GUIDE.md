# 원카드 게임 설정 가이드

## 완료된 기능

### ✅ 아키텍처
- **Clean Architecture** 패턴 적용
  - Domain Layer: 비즈니스 로직과 모델
  - Data Layer: Firebase Firestore 데이터 접근
  - Presentation Layer: UI와 상태 관리

### ✅ 데이터 모델
- `Card`: 카드 (무늬, 숫자)
- `Player`: 플레이어 (손패, 상태)
- `GameState`: 게임 상태 (덱, 진행 상황, 특수 효과)

### ✅ 게임 로직
- 카드 섞기 및 배분
- 플레이 가능 여부 체크
- 특수 카드 효과 (A, 7, J)
- 게임 진행 및 승리 판정

### ✅ 상태 관리
- **Riverpod** 사용
- Provider와 StateNotifier로 상태 관리
- Firebase 실시간 동기화

### ✅ Firebase 연동
- Firestore를 통한 실시간 게임 상태 저장
- 게임 생성, 업데이트, 조회
- 멀티플레이어 지원

### ✅ UI 화면
- **HomeScreen**: 플레이어 이름 입력 및 게임 시작
- **GameScreen**: 게임 보드, 카드 뭔치, 상대방 정보

## 실행 방법

### 1. Firebase 설정 (필수)

Firebase가 설정되지 않으면 게임이 정상 작동하지 않습니다.

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 설정
flutterfire configure
```

**Firebase Console 설정:**
1. https://console.firebase.google.com 에서 프로젝트 생성
2. Firestore Database 생성
3. Security Rules 설정:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /games/{gameId} {
         allow read, write: if true;  // 개발용 - 프로덕션에서는 보안 강화 필요
       }
     }
   }
   ```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 앱 실행

```bash
# 웹
flutter run -d chrome

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

## 게임 플레이 방법

1. 앱 실행
2. 두 플레이어 이름 입력
3. "게임 시작" 버튼 클릭
4. 각 플레이어는 순서대로 카드를 낼 수 있음
   - 같은 무늬 또는 같은 숫자의 카드
   - 낼 카드가 없으면 "카드 뽑기" 버튼 클릭
5. 카드가 먼저 0장이 된 플레이어 승리

## 특수 카드

- **A (에이스)**: 다음 플레이어를 건너뜀
- **7**: 다음 플레이어가 2장의 카드를 뽑음
- **J (잭)**: 진행 방향 변경

## 기술 스택

- Flutter 3.0+
- Riverpod 2.x (상태 관리)
- Firebase Firestore (실시간 DB)
- Equatable (모델 비교)
- UUID (게임 ID 생성)

## 참고사항

- 현재는 1:1 플레이어 모드만 지원 (추후 확장 가능)
- Firebase 없이 실행 시 에러 발생 가능
- 실제 배포 시 Security Rules 보강 필요

