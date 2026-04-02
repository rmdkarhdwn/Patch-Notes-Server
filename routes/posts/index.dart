// Dart Frog에서 제공하는 Request/Response 타입을 사용하기 위해 import
import 'package:dart_frog/dart_frog.dart';
// 게시글 파일 저장소에서 목록을 읽기 위해 import.
import '_posts_data.dart';

// /posts 요청이 들어왔을 때 실행되는 핸들러 함수.
Future<Response> onRequest(RequestContext context) async {
  // 파일에서 게시글 목록을 읽는다.
  final posts = await loadPosts();

  // JSON 형태의 응답을 클라이언트에 반환.
  return Response.json(
    // body: 실제 클라이언트가 받는 JSON 내용.
    body: {
      // success: 요청 성공 여부.
      'success': true,
      // data: 게시글 목록 데이터.
      'data': posts,
    },
  );
}
