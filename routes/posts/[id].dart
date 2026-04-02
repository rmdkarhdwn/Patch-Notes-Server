import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
// 변경 이유: 수정/삭제 결과를 파일에 저장해 서버 재시작 뒤에도 유지
import '_posts_data.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final posts = await loadPosts();

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final index = posts.indexWhere((p) => p['id'].toString() == id);
    if (index == -1) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': '패치노트 없음'},
      );
    }
    final oldPost = posts[index];
    final updatePost = <String, Object>{
      'id': oldPost['id']!,
      'title': (data['title'] ?? oldPost['title']) as String,
      'summary': (data['summary'] ?? oldPost['summary']) as String,
    };
    posts[index] = updatePost;
    await savePosts(posts);
    return Response.json(
      body: {'success': true, 'data': updatePost},
    );
  }

  final post = posts.firstWhere(
    (p) => p['id'].toString() == id,
    orElse: () => {},
  );
  if (post.isEmpty) {
    return Response.json(
      statusCode: 404,
      body: {
        'success': false,
        'message': '패치노트 없음',
      },
    );
  }
  if (context.request.method == HttpMethod.delete) {
    posts.removeWhere((p) => p['id'].toString() == id);
    await savePosts(posts);
    return Response.json(
      body: {
        'success': true,
        'message': '삭제완료',
      },
    );
  }
  return Response.json(
    body: {
      'success': true,
      'data': post,
    },
  );
}
