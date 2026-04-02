import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/posts/[id].dart' as post_by_id_route;
import '../../../routes/posts/index.dart' as posts_index_route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

Future<String> _createRequestBody(Invocation _) async =>
    '{"title":"v1.2.0","summary":"성능 개선"}';
Future<String> _invalidJsonRequestBody(Invocation _) async => '{bad-json';
Future<String> _invalidTypeRequestBody(Invocation _) async =>
    '{"title":123,"summary":true}';
Future<String> _emptyValueRequestBody(Invocation _) async =>
    '{"title":"  ","summary":""}';
Future<String> _updateRequestBody(Invocation _) async =>
    '{"title":"v1.0.1 핫픽스","summary":"긴급 패치"}';
Future<String> _missingUpdateRequestBody(Invocation _) async =>
    '{"title":"x","summary":"y"}';

Map<String, dynamic> _toDynamicMap(Map<String, Object> post) =>
    Map<String, dynamic>.from(post);

const _initialPosts = <Map<String, Object>>[
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

List<Map<String, dynamic>> _fakeTable = [];

Future<List<Map<String, dynamic>>> _fakeFetchPosts() async =>
    _fakeTable.map(Map<String, dynamic>.from).toList();

Future<Map<String, dynamic>> _fakeCreatePost(
  String title,
  String summary,
) async {
  final nextId = _fakeTable.isEmpty
      ? 1
      : (_fakeTable
                  .map((post) => post['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1);
  final created = <String, dynamic>{
    'id': nextId,
    'title': title,
    'summary': summary,
  };
  _fakeTable.add(created);
  return Map<String, dynamic>.from(created);
}

Future<Map<String, dynamic>?> _fakeFetchPostById(String id) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return null;
  }
  for (final post in _fakeTable) {
    if (post['id'] == parsedId) {
      return Map<String, dynamic>.from(post);
    }
  }
  return null;
}

Future<Map<String, dynamic>?> _fakeUpdatePostById(
  String id,
  String title,
  String summary,
) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return null;
  }

  for (var i = 0; i < _fakeTable.length; i++) {
    final post = _fakeTable[i];
    if (post['id'] == parsedId) {
      final updated = <String, dynamic>{
        'id': parsedId,
        'title': title,
        'summary': summary,
      };
      _fakeTable[i] = updated;
      return Map<String, dynamic>.from(updated);
    }
  }
  return null;
}

Future<bool> _fakeDeletePostById(String id) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) {
    return false;
  }
  final before = _fakeTable.length;
  _fakeTable.removeWhere((post) => post['id'] == parsedId);
  return _fakeTable.length != before;
}

void main() {
  setUp(() {
    _fakeTable = _initialPosts.map(_toDynamicMap).toList();

    posts_index_route.fetchPosts = _fakeFetchPosts;
    posts_index_route.createPost = _fakeCreatePost;

    post_by_id_route.fetchPostById = _fakeFetchPostById;
    post_by_id_route.updatePostById = _fakeUpdatePostById;
    post_by_id_route.deletePostById = _fakeDeletePostById;
  });

  group('GET /posts', () {
    test('returns posts list.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect((body['data'] as List).length, equals(2));
    });

    test('returns 500 when db fetch fails.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);
      posts_index_route.fetchPosts = () => throw Exception('db error');

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.internalServerError));
      expect(body['success'], isFalse);
    });
  });

  group('POST /posts', () {
    test('returns 405 for non-POST/GET method.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.put);
      when(() => context.request).thenReturn(request);

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(response.headers['Allow'], equals('GET, POST'));
      expect(body['success'], isFalse);
    });

    test('creates a post for POST method.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_createRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['title'], equals('v1.2.0'));
      expect(_fakeTable.length, equals(3));
    });

    test('returns 400 for invalid JSON.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_invalidJsonRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['success'], isFalse);
    });

    test('returns 400 for invalid field types.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_invalidTypeRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['success'], isFalse);
    });

    test('returns 400 for empty required fields.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_emptyValueRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['success'], isFalse);
    });
  });

  group('GET /posts/:id', () {
    test('returns post when id exists.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['id'], equals(1));
    });

    test('returns 404 when id does not exist.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '999');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.notFound));
      expect(body['success'], isFalse);
    });

    test('returns 405 for unsupported method.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(response.headers['Allow'], equals('GET, PUT, DELETE'));
      expect(body['success'], isFalse);
    });
  });

  group('PUT /posts/:id', () {
    test('updates post when id exists.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.put);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_updateRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['title'], equals('v1.0.1 핫픽스'));
      expect(_fakeTable.first['title'], equals('v1.0.1 핫픽스'));
    });

    test('returns 404 when updating missing post.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.put);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_missingUpdateRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '999');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.notFound));
      expect(body['success'], isFalse);
    });

    test('returns 400 for invalid JSON.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.put);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_invalidJsonRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['success'], isFalse);
    });

    test('returns 400 for invalid field types.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.put);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_invalidTypeRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['success'], isFalse);
    });

    test('returns 400 for empty required fields.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.put);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_emptyValueRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['success'], isFalse);
    });
  });

  group('DELETE /posts/:id', () {
    test('deletes post when id exists.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(_fakeTable.where((post) => post['id'] == 1), isEmpty);
      expect(_fakeTable.length, equals(1));
    });

    test('returns 404 when deleting missing post.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => context.request).thenReturn(request);

      final response = await post_by_id_route.onRequest(context, '999');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.notFound));
      expect(body['success'], isFalse);
    });
  });
}
