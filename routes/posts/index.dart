// Dart Frog에서 제공하는 Request/Response 타입을 사용하기 위해 import
import 'package:dart_frog/dart_frog.dart';
// 변경 이유: 서버 재시작 후에도 유지되도록 파일 기반 posts 저장소를 사용
import '_posts_data.dart';

// /posts 요청이 들어왔을 때 실행되는 핸들러 함수
Future<Response> onRequest(RequestContext context) async {
  final posts = await loadPosts();

  // JSON 형태의 응답을 클라이언트에 반환
  return Response.json(
    // 응답 본문(body) 데이터
    body: {
      // 요청 처리 성공 여부
      'success': true,
      // 실제 응답 데이터(게시글 목록)
      'data': posts,
    },
  );
}
