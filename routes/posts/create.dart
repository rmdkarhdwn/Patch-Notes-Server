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

  Map<String, dynamic> data;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'JSON 객체 형식이어야 합니다.'},
      );
    }
    data = decoded;
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': '잘못된 JSON 형식입니다.'},
    );
  }

  final title = data['title'];
  final summary = data['summary'];
  if (title is! String || summary is! String) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'title, summary는 문자열이어야 합니다.'},
    );
  }
  if (title.trim().isEmpty || summary.trim().isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'title, summary는 필수값입니다.'},
    );
  }

  final newPost = <String, Object>{
    'id': DateTime.now().millisecondsSinceEpoch,
    'title': title.trim(),
    'summary': summary.trim(),
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
