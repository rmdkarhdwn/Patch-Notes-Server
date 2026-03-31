import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
// 변경 이유: create 라우트도 공통 posts 저장소를 써야 목록/상세/삭제와 데이터가 일치함
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
  posts.add(newPost);
  return Response.json(
    body: {
      'success': true,
      'data': newPost,
    },
  );
}
