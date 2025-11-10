import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase가 설정되지 않은 경우 개발 모드로 계속 진행
    // 실제 환경에서는 Firebase 설정이 필요합니다
    print('Firebase initialization failed: $e');
  }
}
