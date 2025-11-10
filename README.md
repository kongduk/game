# 원카드 게임 (OneCard Game)

Flutter와 Firebase를 사용한 멀티플레이어 원카드 게임입니다.

## 주요 기능

- **실시간 멀티플레이**: Firebase Firestore를 통한 실시간 게임 상태 동기화
- **원카드 게임 규칙**: 표준 원카드 게임 로직 구현
- **깔끔한 UI**: Material Design 3 기반의 모던한 인터페이스
- **상태 관리**: Riverpod을 사용한 효율적인 상태 관리

## 아키텍처

이 프로젝트는 Clean Architecture 패턴을 따릅니다:

### Domain Layer (도메인 레이어)
- **Models**: `Card`, `Player`, `GameState` 등 게임 도메인 모델
- **Services**: 게임 로직 구현 (`GameLogic`, `DeckManager`)

### Data Layer (데이터 레이어)
- **Repositories**: Firebase Firestore와의 데이터 통신 (`GameRepository`)

### Presentation Layer (프레젠테이션 레이어)
- **Screens**: 게임 화면 (`HomeScreen`, `GameScreen`)
- **Providers**: Riverpod을 사용한 상태 관리 (`game_provider.dart`)

## 게임 규칙

### 기본 규칙
- 각 플레이어는 시작할 때 7장의 카드를 받습니다
- 같은 무늬(Suit) 또는 같은 숫자(Rank)의 카드를 낼 수 있습니다
- 낼 카드가 없으면 덱에서 1장을 뽑습니다

### 특수 카드
- **A (에이스)**: 다음 플레이어를 건너뜁니다
- **7**: 다음 플레이어가 2장의 카드를 뽑아야 합니다
- **J (잭)**: 진행 방향이 바뀝니다

## 설치 및 실행

### 1. Flutter 설치
Flutter SDK가 설치되어 있어야 합니다.

### 2. Firebase 설정
Firebase를 사용한 실시간 게임을 위해서는 Firebase 설정이 필요합니다.

#### 옵션 1: FlutterFire CLI 사용 (권장)
1. Firebase Console (https://console.firebase.google.com)에서 새 프로젝트 생성
2. Firestore Database 활성화 (테스트 모드로 시작)
3. 터미널에서 다음 명령 실행:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

#### 옵션 2: 수동 설정
1. Firebase Console에서 프로젝트 생성
2. Firestore 활성화
3. `lib/firebase_options.dart` 파일의 `YOUR_*` 부분을 실제 Firebase 설정으로 교체

**참고**: Firebase 설정 없이도 로컬 테스트는 가능하지만, 멀티플레이어 기능은 사용할 수 없습니다.

### 3. 의존성 설치
```bash
flutter pub get
```

### 4. 앱 실행
```bash
flutter run
```

## 기술 스택

- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **Firebase Firestore**: 실시간 데이터베이스
- **Riverpod**: 상태 관리
- **Equatable**: 객체 동등성 비교

## 프로젝트 구조

```
lib/
├── main.dart                      # 앱 진입점
├── firebase_options.dart          # Firebase 설정
├── firebase_setup.dart           # Firebase 초기화
├── domain/                        # 도메인 레이어
│   ├── models/                    # 도메인 모델
│   │   ├── card.dart
│   │   ├── player.dart
│   │   └── game_state.dart
│   └── services/                  # 비즈니스 로직
│       ├── deck_manager.dart
│       └── game_logic.dart
├── data/                          # 데이터 레이어
│   └── repositories/
│       └── game_repository.dart   # Firebase 통신
└── presentation/                  # 프레젠테이션 레이어
    ├── app.dart
    ├── providers/
    │   └── game_provider.dart     # Riverpod providers
    └── screens/
        ├── home_screen.dart       # 홈 화면
        └── game_screen.dart       # 게임 화면
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

