import 'dart:convert';
import 'dart:io';

// 변경 이유:
// 메모리 리스트만 쓰면 서버 재시작 시 데이터가 사라진다.
// 그래서 posts 데이터를 파일(data/posts.json)에 저장해 영속화한다.
String postsFilePath = 'data/posts.json';

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

Future<List<Map<String, Object>>> loadPosts() async {
  final file = File(postsFilePath);
  file.parent.createSync(recursive: true);

  if (!file.existsSync()) {
    file.writeAsStringSync(jsonEncode(initialPosts));
    return initialPosts.map(Map<String, Object>.from).toList();
  }

  final content = file.readAsStringSync();
  if (content.trim().isEmpty) {
    file.writeAsStringSync(jsonEncode(initialPosts));
    return initialPosts.map(Map<String, Object>.from).toList();
  }

  final decoded = jsonDecode(content);
  if (decoded is! List) {
    throw const FormatException('posts data must be a JSON array');
  }

  return decoded.map<Map<String, Object>>((entry) {
    final map = Map<String, dynamic>.from(entry as Map);
    return <String, Object>{
      'id': (map['id'] ?? 0) as Object,
      'title': (map['title'] ?? '').toString(),
      'summary': (map['summary'] ?? '').toString(),
    };
  }).toList();
}

Future<void> savePosts(List<Map<String, Object>> posts) async {
  final file = File(postsFilePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(posts));
}
