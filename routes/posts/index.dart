// Dart Frog에서 제공하는 Request/Response 타입을 사용하기 위해 import
import 'package:dart_frog/dart_frog.dart';
// DB에서 posts 목록을 조회하는 함수.
import '_db.dart';
// POST body(title/summary) 검증 로직 공통 사용.
import '_post_input.dart';

typedef PostsFetcher = Future<List<Map<String, dynamic>>> Function();
typedef PostCreator = Future<Map<String, dynamic>> Function(
  String title,
  String summary,
);

// 테스트에서는 이 함수를 교체해서 DB 없이도 검증할 수 있다.
PostsFetcher fetchPosts = fetchPostsFromDb;
PostCreator createPost = createPostInDb;

// /posts 요청이 들어왔을 때 실행되는 핸들러 함수.
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method != HttpMethod.get && method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      headers: {'Allow': 'GET, POST'},
      body: {
        'success': false,
        'message': 'GET, POST만 허용',
      },
    );
  }

  try {
    if (method == HttpMethod.post) {
      final inputResult = await parsePostInput(context.request);
      if (inputResult.error != null) {
        return inputResult.error!;
      }
      final input = inputResult.input!;

      final newPost = await createPost(input.title, input.summary);
      return Response.json(
        body: {
          'success': true,
          'data': newPost,
        },
      );
    }

    // method == GET
    final posts = await fetchPosts();
    return Response.json(
      body: {
        'success': true,
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
