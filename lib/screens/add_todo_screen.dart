import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spring_button/spring_button.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';

List<String> _parseTags(String raw) {
  final set = <String>{};
  for (final piece in raw.split(',')) {
    final t = piece.trim();
    if (t.isNotEmpty) set.add(t); // 重複自動除去
  }
  return set.toList();
}

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key, required this.todoService});
  final TodoService todoService;

  @override
  AddTodoScreenState createState() => AddTodoScreenState();
}

class AddTodoScreenState extends State<AddTodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  DateTime? _selectedDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateFormValid);
    _detailController.addListener(_updateFormValid);
    _dateController.addListener(_updateFormValid);
    _tagsController.addListener(_updateFormValid);
  }

  void _updateFormValid() {
    setState(() {
      _isFormValid =
          _titleController.text.isNotEmpty &&
          _detailController.text.isNotEmpty &&
          _selectedDate != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.white30, // ← 透過

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pastel.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            top: true,
            bottom: false, // ← SafeAreaでbottomは取らない
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                88,
                16,
                MediaQuery.viewPaddingOf(context).bottom + 24, // ← 自前で確保
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _GlassField(
                      radius: borderRadius,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: _glassInputDecoration(
                          label: 'タスクのタイトル',
                          hint: '20文字以内で入力してください',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'タイトルを入力してください';
                          if (v.characters.length > 20)
                            return 'タイトルは20文字以内にしてください';
                          return null;
                        },
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 詳細
                    _GlassField(
                      radius: borderRadius,
                      child: TextFormField(
                        controller: _detailController,
                        maxLines: 3,
                        decoration: _glassInputDecoration(
                          label: 'タスクの詳細',
                          hint: '入力してください',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '詳細を入力してください' : null,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 期日
                    _GlassField(
                      radius: borderRadius,
                      child: TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: _glassInputDecoration(
                          label: '期日',
                          hint: '年/月/日',
                          suffixIcon: const Icon(
                            Icons.event,
                            color: Colors.blueGrey,
                          ),
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                              _dateController.text =
                                  '${picked.year}'
                                  '/${picked.month.toString().padLeft(2, '0')}'
                                  '/${picked.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '期日を選択してください' : null,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    // 詳細 の次にこれを差し込む
                    const SizedBox(height: 16),
                    // タグ
                    _GlassField(
                      radius: borderRadius,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _tagsController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            decoration: _glassInputDecoration(
                              label: 'タグ（カンマ区切り）',
                              hint: '例：学校, Flutter, 趣味',
                              suffixIcon: const Icon(Icons.label),
                            ),
                            style: const TextStyle(color: Colors.black87),
                            // 検証は任意（空でもOKにするならnullでOK）
                            validator: (_) => null,
                            onChanged: (_) => setState(() {}), // 下のChipプレビューを更新
                          ),
                          const SizedBox(height: 8),
                          // 入力中のプレビュー（Chip表示）
                          Builder(
                            builder: (context) {
                              final tags = _parseTags(_tagsController.text);
                              if (tags.isEmpty) {
                                return Text(
                                  'カンマで区切って複数入力できます',
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: .55),
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 6,
                                runSpacing: -6,
                                children: tags.map((t) {
                                  return Chip(
                                    label: Text(t),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: .35,
                                        ),
                                      ),
                                    ),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: .10,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // 追加ボタン（パステルガラス）
                    _GlassButton(
                      label: 'タスクを追加',
                      onPressed: _isFormValid ? _saveTodo : null,
                      enabled: _isFormValid,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // AppBar：パステルガラス
      appBar: AppBar(
        title: const Text('新しいタスクを追加', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white30,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // ← 少し弱め
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTodo() async {
    if (_formKey.currentState!.validate()) {
      final tags = _parseTags(_tagsController.text); // ← 追加

      final newTodo = Todo(
        title: _titleController.text,
        detail: _detailController.text,
        dueDate: _selectedDate!,
        tags: tags, // ← 追加
      );

      final todos = await widget.todoService.getTodos();
      todos.add(newTodo);
      await widget.todoService.saveTodos(todos);

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _dateController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFormValid();
  }
}

/// ─────────────────────────────────────────────────────────────
/// ガラス風のコンテナ（入力欄用）
/// ─────────────────────────────────────────────────────────────

class _GlassField extends StatelessWidget {
  const _GlassField({required this.child, required this.radius});
  final Widget child;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            // ★ 白だけのグラデ（グレー禁止）
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.22), // 明るい白
                Colors.white.withValues(alpha: 0.08), // 透明寄りの白
              ],
            ),
            // ボーダーはごく薄い白
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            // 影はナシ or ほんの少しだけ白で
            boxShadow: const [],
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// ガラス風の大ボタン（ぷにぷに感＋黒影）
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      SpringButtonType.OnlyScale, // ← 押したらぷにっと沈む
      Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.10),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.black45,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
      onTap: enabled ? onPressed : null,
      scaleCoefficient: 0.92, // ← 押下時に0.92倍になる
      useCache: false, // ← 背景をキャッシュしない（ガラスUI向け）
    );
  }
}

InputDecoration _glassInputDecoration({
  required String label,
  required String hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    border: InputBorder.none,
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(
      color: Colors.black87, // ← 黒寄り
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(
      color: Colors.black.withValues(alpha: 0.55), // ← 薄めのグレー
    ),
    suffixIcon: suffixIcon == null
        ? null
        : IconTheme(
            data: const IconThemeData(color: Colors.black87),
            child: suffixIcon,
          ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}
