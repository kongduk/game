// Firebase 초기화는 더 이상 사용하지 않습니다.
// 프로젝트에서 Firebase 대신 SQLite를 사용하므로, 초기화는 no-op입니다.
Future<void> initializeFirebase() async {
  // no-op: keep API compatibility if some startup code calls this.
  return Future.value();
}
