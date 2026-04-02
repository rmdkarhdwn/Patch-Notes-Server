import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

// POST/PUT 본문에서 실제로 필요한 필드만 담는 모델.
class PostInput {
  const PostInput({
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;
}

// 파싱 결과를 한 타입으로 다루기 위한 래퍼.
// 성공이면 input, 실패면 error(Response)가 채워진다.
class PostInputResult {
  const PostInputResult.success(this.input) : error = null;
  const PostInputResult.failure(this.error) : input = null;

  final PostInput? input;
  final Response? error;
}

// 요청 body(JSON)를 읽고 title/summary를 검증한다.
Future<PostInputResult> parsePostInput(Request request) async {
  final body = await request.body();

  Map<String, dynamic> data;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return PostInputResult.failure(
        Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'JSON 객체 형식이어야 합니다.'},
        ),
      );
    }
    data = decoded;
  } on FormatException {
    return PostInputResult.failure(
      Response.json(
        statusCode: 400,
        body: {'success': false, 'message': '잘못된 JSON 형식입니다.'},
      ),
    );
  }

  final title = data['title'];
  final summary = data['summary'];

  if (title is! String || summary is! String) {
    return PostInputResult.failure(
      Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'title, summary는 문자열이어야 합니다.'},
      ),
    );
  }

  final normalizedTitle = title.trim();
  final normalizedSummary = summary.trim();
  if (normalizedTitle.isEmpty || normalizedSummary.isEmpty) {
    return PostInputResult.failure(
      Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'title, summary는 필수값입니다.'},
      ),
    );
  }

  return PostInputResult.success(
    PostInput(title: normalizedTitle, summary: normalizedSummary),
  );
}
