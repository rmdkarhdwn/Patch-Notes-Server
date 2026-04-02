import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/posts/[id].dart' as post_by_id_route;
import '../../../routes/posts/_posts_data.dart';
import '../../../routes/posts/create.dart' as create_route;
import '../../../routes/posts/index.dart' as posts_index_route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

Future<String> _createRequestBody(Invocation _) async =>
    '{"title":"v1.2.0","summary":"성능 개선"}';

Future<String> _updateRequestBody(Invocation _) async =>
    '{"title":"v1.0.1 핫픽스","summary":"긴급 패치"}';

Future<String> _missingUpdateRequestBody(Invocation _) async =>
    '{"title":"x","summary":"y"}';
Future<String> _invalidJsonRequestBody(Invocation _) async => '{bad-json';
Future<String> _invalidTypeRequestBody(Invocation _) async =>
    '{"title":123,"summary":true}';
Future<String> _emptyValueRequestBody(Invocation _) async =>
    '{"title":"  ","summary":""}';

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

void main() {
  setUp(() async {
    postsFilePath = 'data/posts_test.json';
    await savePosts(_initialPosts.map(Map<String, Object>.from).toList());
  });

  tearDown(() async {
    final file = File(postsFilePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  group('GET /posts', () {
    test('returns posts list.', () async {
      final context = _MockRequestContext();
      final response = await posts_index_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);

      final data = body['data'] as List<dynamic>;
      expect(data.length, equals(2));
    });
  });

  group('POST /posts/create', () {
    test('returns 405 for non-POST method.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);

      final response = await create_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(body['success'], isFalse);
    });

    test('creates a post for POST method.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_createRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await create_route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final savedPosts = await loadPosts();

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['title'], equals('v1.2.0'));
      expect(savedPosts.length, equals(3));
    });

    test('returns 400 for invalid JSON.', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.post);
      // ignore: unnecessary_lambdas
      when(() => request.body()).thenAnswer(_invalidJsonRequestBody);
      when(() => context.request).thenReturn(request);

      final response = await create_route.onRequest(context);
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

      final response = await create_route.onRequest(context);
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

      final response = await create_route.onRequest(context);
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
      final savedPosts = await loadPosts();

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(data['title'], equals('v1.0.1 핫픽스'));
      expect(savedPosts.first['title'], equals('v1.0.1 핫픽스'));
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
      final savedPosts = await loadPosts();

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect(savedPosts.where((post) => post['id'] == 1), isEmpty);
      expect(savedPosts.length, equals(1));
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
