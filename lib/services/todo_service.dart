import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static const String _storageKey = 'todos';
  final SharedPreferences _prefs;

  TodoService(this._prefs);

  /// TODOリストの読み込み（tags対応・後方互換）
  Future<List<Todo>> getTodos() async {
    final String? todosJson = _prefs.getString(_storageKey);
    if (todosJson == null || todosJson.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(todosJson);

      return decoded.where((item) => item is Map<String, dynamic>).map<Todo>((
        item,
      ) {
        final map = item as Map<String, dynamic>;
        return Todo(
          id: map['id'] as String?,
          title: map['title'] as String? ?? '',
          detail: map['detail'] as String? ?? '',
          dueDate:
              DateTime.tryParse(map['dueDate'] as String? ?? '') ??
              DateTime.now(),
          isCompleted: map['isCompleted'] as bool? ?? false,
          // ★ ここがポイント：tags を復元（無ければ []）
          tags:
              (map['tags'] as List?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const [],
        );
      }).toList();
    } catch (_) {
      // 破損データなどは空で返す
      return [];
    }
  }

  /// TODOリストの保存（tags含む）
  Future<void> saveTodos(List<Todo> todos) async {
    // モデルに toJson() があるなら：todo.toJson() を使うのがベスト
    final List<Map<String, dynamic>> jsonData = todos.map((t) {
      return {
        'id': t.id,
        'title': t.title,
        'detail': t.detail,
        'dueDate': t.dueDate.toIso8601String(),
        'isCompleted': t.isCompleted,
        // ★ ここがポイント：tags を保存
        'tags': t.tags,
      };
    }).toList();

    final String encoded = jsonEncode(jsonData);
    await _prefs.setString(_storageKey, encoded);
  }
}
