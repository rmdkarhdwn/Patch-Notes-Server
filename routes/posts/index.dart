// Dart Frog에서 제공하는 Request/Response 타입을 사용하기 위해 import
import 'package:dart_frog/dart_frog.dart';
// DB에서 posts 목록을 조회하는 함수.
import '_db.dart';

typedef PostsFetcher = Future<List<Map<String, dynamic>>> Function();

// 테스트에서는 이 함수를 교체해서 DB 없이도 검증할 수 있다.
PostsFetcher fetchPosts = fetchPostsFromDb;

// /posts 요청이 들어왔을 때 실행되는 핸들러 함수.
Future<Response> onRequest(RequestContext context) async {
  try {
    // DB에서 게시글 목록을 읽는다.
    final posts = await fetchPosts();

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
  } catch (_) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'DB 조회 실패',
      },
    );
  }
}
