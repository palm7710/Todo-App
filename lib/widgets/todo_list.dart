import 'package:flutter/material.dart';

import '../models/todo.dart'; // 作成したTodoクラス
import '../services/todo_service.dart'; // データ保存サービス
import '../widgets/todo_card.dart'; // 作成したTodoCardウィジェット
import '../models/sort_option.dart';

class TodoList extends StatefulWidget {
  const TodoList({
    super.key,
    required this.todoService,
    this.searchQuery = '',
    this.sortOption,
  });

  final TodoService todoService;
  final String searchQuery;
  final SortOption? sortOption;

  @override
  State<TodoList> createState() => TodoListState();
}

class TodoListState extends State<TodoList> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos(); // SharedPreferences から読み込み
  }

  Future<void> _loadTodos() async {
    final todos = await widget.todoService.getTodos();
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  // 追加画面から呼ばれる
  void addTodo(Todo newTodo) async {
    setState(() => _todos.add(newTodo));
    await widget.todoService.saveTodos(_todos);
  }

  Future<void> _toggleTodo(Todo todo) async {
    final updated = _todos
        .map(
          (t) => t.id == todo.id ? t.copyWith(isCompleted: !t.isCompleted) : t,
        )
        .toList();

    setState(() => _todos = updated);
    await widget.todoService.saveTodos(updated);
  }

  // チェック or 削除ボタンから呼ばれる
  Future<void> _deleteTodo(Todo todo) async {
    setState(() => _todos.removeWhere((t) => t.id == todo.id));
    await widget.todoService.saveTodos(_todos);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter and sort todos
    List<Todo> filteredTodos = _todos.where((todo) {
      if (widget.searchQuery.isEmpty) return true;

      final query = widget.searchQuery.toLowerCase();

      // 🔽 タイトル・詳細・タグ名をすべて対象にする
      final matchesTitle = todo.title.toLowerCase().contains(query);
      final matchesDetail = todo.detail.toLowerCase().contains(query);
      final matchesTag = todo.tags.any(
        (tag) => tag.toLowerCase().contains(query),
      );

      return matchesTitle || matchesDetail || matchesTag;
    }).toList();

    if (widget.sortOption != null) {
      filteredTodos.sort((a, b) {
        int comparison = 0;
        switch (widget.sortOption!.key) {
          case SortKey.dueDate:
            comparison = a.dueDate.compareTo(b.dueDate);
            break;
          case SortKey.title:
            comparison = a.title.compareTo(b.title);
            break;
          case SortKey.completed:
            comparison = a.isCompleted ? 1 : -1;
            if (b.isCompleted) comparison = -comparison;
            break;
        }
        return widget.sortOption!.ascending ? comparison : -comparison;
      });
    }

    return ListView.builder(
      itemCount: filteredTodos.length,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
      ),
      itemBuilder: (context, index) {
        final todo = filteredTodos[index];
        return Padding(
          padding: const EdgeInsets.all(0),
          child: TodoCard(
            todo: todo,
            onToggle: () => _toggleTodo(todo),
            onDelete: () => _deleteTodo(todo),
          ),
        );
      },
    );
  }
}
