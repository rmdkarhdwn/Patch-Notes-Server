import 'package:dart_frog/dart_frog.dart';
// POST body(title/summary) 검증 로직 공통 사용.
import '_post_input.dart';
// 게시글 파일 저장소 입출력 함수(load/save).
import '_posts_data.dart';

// /posts/create 라우트 핸들러.
Future<Response> onRequest(RequestContext context) async {
  // 이 엔드포인트는 POST만 허용.
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'POST만 허용'},
    );
  }

  // JSON 파싱 + 타입/필수값 검증.
  final inputResult = await parsePostInput(context.request);
  if (inputResult.error != null) {
    return inputResult.error!;
  }
  final input = inputResult.input!;

  // 새 게시글 생성.
  final newPost = <String, Object>{
    'id': DateTime.now().millisecondsSinceEpoch,
    'title': input.title,
    'summary': input.summary,
  };

  // 기존 목록을 읽고 새 글을 추가한 뒤 파일에 저장.
  final posts = await loadPosts();
  posts.add(newPost);
  await savePosts(posts);

  // 생성 결과 반환.
  return Response.json(
    body: {
      'success': true,
      'data': newPost,
    },
  );
}
