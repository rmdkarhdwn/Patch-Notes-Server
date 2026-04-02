import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
// 변경 이유: 수정/삭제 결과를 파일에 저장해 서버 재시작 뒤에도 유지
import '_posts_data.dart';

Future<Response> onRequest(RequestContext context, String id) async {
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

  final posts = await loadPosts();

  if (method == HttpMethod.put) {
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
      'title': title.trim(),
      'summary': summary.trim(),
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
  if (method == HttpMethod.delete) {
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
