import 'dart:io';

import 'package:postgres/postgres.dart';

String _env(
  String key,
  String fallback,
) => Platform.environment[key] ?? fallback;

int _envInt(String key, int fallback) {
  final value = Platform.environment[key];
  if (value == null) {
    return fallback;
  }
  return int.tryParse(value) ?? fallback;
}

// PostgreSQL 연결을 열고 posts 목록을 조회한다.
Future<List<Map<String, dynamic>>> fetchPostsFromDb() async {
  final conn = await _openConnection();

  try {
    final result = await conn.execute(
      'SELECT id, title, summary FROM posts ORDER BY id DESC',
    );
    return result.map((row) => row.toColumnMap()).toList();
  } finally {
    await conn.close();
  }
}

// id로 게시글 1개를 조회한다. 없으면 null.
Future<Map<String, dynamic>?> fetchPostByIdFromDb(String id) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return null;
  }

  final conn = await _openConnection();
  try {
    final result = await conn.execute(
      r'SELECT id, title, summary FROM posts WHERE id = $1',
      parameters: [parsedId],
    );
    if (result.isEmpty) {
      return null;
    }
    return result.first.toColumnMap();
  } finally {
    await conn.close();
  }
}

// id로 게시글을 수정하고 수정 결과를 반환한다. 없으면 null.
Future<Map<String, dynamic>?> updatePostInDb(
  String id,
  String title,
  String summary,
) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return null;
  }

  final conn = await _openConnection();
  try {
    final result = await conn.execute(
      r'UPDATE posts SET title = $1, summary = $2 WHERE id = $3 '
      'RETURNING id, title, summary',
      parameters: [title, summary, parsedId],
    );
    if (result.isEmpty) {
      return null;
    }
    return result.first.toColumnMap();
  } finally {
    await conn.close();
  }
}

// id로 게시글을 삭제한다. 삭제 성공 여부를 반환한다.
Future<bool> deletePostByIdFromDb(String id) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return false;
  }

  final conn = await _openConnection();
  try {
    final result = await conn.execute(
      r'DELETE FROM posts WHERE id = $1',
      parameters: [parsedId],
    );
    return result.affectedRows > 0;
  } finally {
    await conn.close();
  }
}

Future<Connection> _openConnection() {
  return Connection.open(
    Endpoint(
      host: _env('PG_HOST', 'localhost'),
      port: _envInt('PG_PORT', 5433),
      database: _env('PG_DATABASE', 'patch_notes'),
      username: _env('PG_USERNAME', 'oneriver'),
      password: _env('PG_PASSWORD', ''),
    ),
  );
}
