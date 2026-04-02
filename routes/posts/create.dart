import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
// 변경 이유: create 결과를 파일에 저장해 서버 재시작 뒤에도 유지
import '_posts_data.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'POST만 허용'},
    );
  }
  final body = await context.request.body();

  final data = jsonDecode(body) as Map<String, dynamic>;
  final newPost = <String, Object>{
    'id': DateTime.now().millisecondsSinceEpoch,
    'title': (data['title'] ?? '') as String,
    'summary': (data['summary'] ?? '') as String,
  };
  final posts = await loadPosts();
  posts.add(newPost);
  await savePosts(posts);

  return Response.json(
    body: {
      'success': true,
      'data': newPost,
    },
  );
}
