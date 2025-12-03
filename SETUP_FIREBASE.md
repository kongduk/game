Firebase 설정 가이드

1) Firebase 프로젝트 생성
 - https://console.firebase.google.com/ 에서 새 프로젝트를 생성합니다.

2) 플랫폼 추가 및 설정
 - Android: 앱 패키지명을 `android/app/src/main/AndroidManifest.xml`의 package와 동일하게 설정하세요.
 - iOS: 번들 ID를 Xcode에 맞게 설정하세요.

3) FlutterFire CLI 사용 (권장)
 - FlutterFire CLI를 설치합니다 (자세한 내용: https://firebase.google.com/docs/flutter/setup#cli)
 - 프로젝트 루트에서:
   flutterfire configure
 - 이 명령은 `lib/firebase_options.dart` 파일을 자동으로 생성하거나 업데이트합니다.

4) 수동 설정 (CLI 사용 불가 시)
 - `lib/firebase_options.dart` 파일에 있는 각 플랫폼용 FirebaseOptions 상수에 프로젝트의 apiKey, appId, projectId 등 값을 채우세요.
 - web: apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket
 - android/iOS/macos/windows: apiKey, appId, messagingSenderId, projectId, storageBucket, iosBundleId(해당 플랫폼)

5) Firestore 활성화
 - Firebase 콘솔에서 Firestore를 활성화하세요. 규칙은 개발중에는 테스트 모드(모든 읽기/쓰기 허용)로 설정하고, 배포 전 보안 규칙을 업데이트하세요.

6) Android 관련
 - `android/app/google-services.json` 파일을 다운로드하여 `android/app/`에 넣으세요.
 - gradle 설정은 프로젝트에 이미 포함되어 있을 가능성이 높습니다. (build.gradle 등)

7) iOS 관련
 - `ios/Runner/GoogleService-Info.plist` 파일을 다운로드하여 Xcode 프로젝트에 추가하세요.

8) 의존성
 - `pubspec.yaml`에 다음 패키지들이 필요합니다:
   dependencies:
     firebase_core: ^2.0.0
     cloud_firestore: ^4.0.0
     flutter_riverpod: ^2.0.0
     path_provider: ^2.0.0

9) 실행
 - 의존성 설치 후 `flutter run`으로 앱을 실행하세요.

문제가 있거나 자동 생성 파일이 필요하면 알려주세요.
