import 'package:dart_frog/dart_frog.dart';
// posts 단건 조회/수정/삭제 DB 함수.
import '_db.dart';
// PUT 입력(JSON) 검증 로직 공통 사용.
import '_post_input.dart';

typedef PostByIdFetcher = Future<Map<String, dynamic>?> Function(String id);
typedef PostByIdUpdater =
    Future<Map<String, dynamic>?> Function(
      String id,
      String title,
      String summary,
    );
typedef PostByIdDeleter = Future<bool> Function(String id);

// 테스트에서 DB 대신 가짜 함수로 교체할 수 있도록 열어둔 함수 포인터.
PostByIdFetcher fetchPostById = fetchPostByIdFromDb;
PostByIdUpdater updatePostById = updatePostInDb;
PostByIdDeleter deletePostById = deletePostByIdFromDb;

// /posts/:id 라우트 핸들러.
Future<Response> onRequest(RequestContext context, String id) async {
  // 메서드 정책: GET, PUT, DELETE만 허용.
  final method = context.request.method;
  if (method != HttpMethod.get &&
      method != HttpMethod.put &&
      method != HttpMethod.delete) {
    return Response.json(
      statusCode: 405,
      headers: {'Allow': 'GET, PUT, DELETE'},
      body: {
        'success': false,
        'message': 'GET, PUT, DELETE만 허용',
      },
    );
  }

  try {
    if (method == HttpMethod.put) {
      // 요청 body 검증(JSON 파싱 + title/summary 체크).
      final inputResult = await parsePostInput(context.request);
      if (inputResult.error != null) {
        return inputResult.error!;
      }
      final input = inputResult.input!;

      // DB UPDATE 실행. 대상이 없으면 null 반환.
      final updatedPost = await updatePostById(id, input.title, input.summary);
      if (updatedPost == null) {
        return Response.json(
          statusCode: 404,
          body: {'success': false, 'message': '패치노트 없음'},
        );
      }

      return Response.json(
        body: {'success': true, 'data': updatedPost},
      );
    }

    if (method == HttpMethod.delete) {
      // DB DELETE 실행. 삭제된 행이 없으면 404.
      final deleted = await deletePostById(id);
      if (!deleted) {
        return Response.json(
          statusCode: 404,
          body: {'success': false, 'message': '패치노트 없음'},
        );
      }

      return Response.json(
        body: {
          'success': true,
          'message': '삭제완료',
        },
      );
    }

    // method == GET
    final post = await fetchPostById(id);
    if (post == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': '패치노트 없음',
        },
      );
    }
    return Response.json(
      body: {
        'success': true,
        'data': post,
      },
    );
  } catch (_) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'DB 작업 실패',
      },
    );
  }
}
