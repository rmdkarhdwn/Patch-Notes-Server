# my_server

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

An example application built with dart_frog

## Run

```bash
dart_frog dev
```

## Posts API

- `GET /posts`: 게시글 목록 조회
- `POST /posts/create`: 게시글 생성
- `GET /posts/:id`: 게시글 단건 조회
- `PUT /posts/:id`: 게시글 수정
- `DELETE /posts/:id`: 게시글 삭제
- `/posts/:id` 허용 메서드: `GET`, `PUT`, `DELETE` (그 외 `405`)

### Create

```bash
curl -X POST http://localhost:8080/posts/create \
  -H "Content-Type: application/json" \
  -d '{"title":"v1.2.0","summary":"성능 개선"}'
```

### Update

```bash
curl -X PUT http://localhost:8080/posts/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"v1.2.1","summary":"핫픽스"}'
```

### Delete

```bash
curl -X DELETE http://localhost:8080/posts/1
```

[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
