import 'dart:convert';
import 'dart:io';

// 서버가 실제로 게시글 데이터를 읽고/쓰는 JSON 파일 경로.
// 테스트에서는 이 값을 테스트 파일 경로로 바꿔 사용한다.
String postsFilePath = 'data/posts.json';

// 파일이 비어 있거나 처음 생성될 때 넣을 기본 데이터.
const initialPosts = <Map<String, Object>>[
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

// 게시글 목록을 파일에서 읽어 메모리 리스트로 변환한다.
Future<List<Map<String, Object>>> loadPosts() async {
  final file = File(postsFilePath);

  // data/ 디렉터리가 없으면 생성.
  file.parent.createSync(recursive: true);

  // 파일이 없으면 기본 데이터로 새 파일을 만든다.
  if (!file.existsSync()) {
    file.writeAsStringSync(jsonEncode(initialPosts));
    return initialPosts.map(Map<String, Object>.from).toList();
  }

  // 파일 내용이 비었어도 기본 데이터로 복구.
  final content = file.readAsStringSync();
  if (content.trim().isEmpty) {
    file.writeAsStringSync(jsonEncode(initialPosts));
    return initialPosts.map(Map<String, Object>.from).toList();
  }

  final decoded = jsonDecode(content);
  if (decoded is! List) {
    throw const FormatException('posts data must be a JSON array');
  }

  // JSON(dynamic)을 앱에서 쓰기 쉬운 Map<String, Object>로 정규화.
  return decoded.map<Map<String, Object>>((entry) {
    final map = Map<String, dynamic>.from(entry as Map);
    return <String, Object>{
      'id': (map['id'] ?? 0) as Object,
      'title': (map['title'] ?? '').toString(),
      'summary': (map['summary'] ?? '').toString(),
    };
  }).toList();
}

// 현재 게시글 목록 전체를 JSON 파일로 저장한다.
Future<void> savePosts(List<Map<String, Object>> posts) async {
  final file = File(postsFilePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(posts));
}
