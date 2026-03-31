import 'package:dart_frog/dart_frog.dart';

final posts = [
  {
    'id': 1,
    'title': 'v1.0.0 출시',
    'summary': '첫 릴리즈',
  },
  {
    'id': 2,
    'title': 'v1.1.0 업데이트',
    'summary': '버그 수정',
  },
];

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'success': true,
      'data': posts,
    },
  );
}