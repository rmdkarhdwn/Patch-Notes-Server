import 'package:dart_frog/dart_frog.dart';
// PUT 입력(JSON) 검증 로직 공통 사용.
import '_post_input.dart';
// 게시글 파일 저장소 입출력 함수(load/save).
import '_posts_data.dart';

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

  // 최신 게시글 목록을 파일에서 불러온다.
  final posts = await loadPosts();
  final index = posts.indexWhere((post) => post['id'].toString() == id);
  final hasPost = index != -1;

  if (method == HttpMethod.put) {
    // 먼저 대상 존재 여부 확인.
    if (!hasPost) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': '패치노트 없음'},
      );
    }

    // 요청 body 검증(JSON 파싱 + title/summary 체크).
    final inputResult = await parsePostInput(context.request);
    if (inputResult.error != null) {
      return inputResult.error!;
    }
    final input = inputResult.input!;

    // 해당 글을 새 데이터로 교체.
    final oldPost = posts[index];
    final updatePost = <String, Object>{
      'id': oldPost['id']!,
      'title': input.title,
      'summary': input.summary,
    };
    posts[index] = updatePost;
    await savePosts(posts);
    return Response.json(
      body: {'success': true, 'data': updatePost},
    );
  }

  // GET/DELETE에서도 먼저 대상 존재 여부를 체크.
  if (!hasPost) {
    return Response.json(
      statusCode: 404,
      body: {
        'success': false,
        'message': '패치노트 없음',
      },
    );
  }

  if (method == HttpMethod.delete) {
    // 해당 글 삭제 후 파일 저장.
    posts.removeAt(index);
    await savePosts(posts);
    return Response.json(
      body: {
        'success': true,
        'message': '삭제완료',
      },
    );
  }

  // method == GET
  final post = posts[index];
  return Response.json(
    body: {
      'success': true,
      'data': post,
    },
  );
}
