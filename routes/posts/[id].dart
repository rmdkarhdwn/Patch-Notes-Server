import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
// 변경 이유: 생성/삭제 결과가 모든 라우트에 동일하게 반영되도록 공통 저장소 사용
import '_posts_data.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.put) {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final index = posts.indexWhere((p) => p['id'].toString() == id);
    if (index == -1) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'data': '패치노트 없음'},
      );
    }
    final oldPost = posts[index];
    final updatePost = {
      'id': oldPost['id'],
      'title': data['title'] ?? oldPost['title'],
      'summary': data['summary'] ?? oldPost['summary'],
    } as Map<String, Object>;
    posts[index] = updatePost;
    return Response.json(
      body: {
        'success' : true,
        'data' : updatePost
      }
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
