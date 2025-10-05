import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TodoCard({super.key, required this.todo, this.onToggle, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      child: Slidable(
        key: ValueKey('${todo.title}_${todo.dueDate.toIso8601String()}'),

        // 左：完了ボタン
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
          children: [
            AnimatedActionButton(
              color: Colors.green,
              icon: Image.asset(
                'assets/images/success_check.gif',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              label: '完了',
              onPressed: () => onToggle?.call(),
            ),
          ],
        ),

        // 右：削除ボタン
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
          children: [
            AnimatedActionButton(
              color: Colors.redAccent,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: '削除',
              onPressed: () => onDelete?.call(),
            ),
          ],
        ),

        // ── カード本体 ──────────────────────────────
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 星アイコン（トグル）
                  IconButton(
                    iconSize: 32,
                    icon: Image.asset(
                      'assets/images/star.png',
                      width: 32,
                      height: 32,
                    ),
                    onPressed: onToggle,
                  ),
                  const SizedBox(width: 8),
                  // テキスト部分
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            todo.title,
                            style: TextStyle(
                              color: todo.isCompleted
                                  ? Colors.grey
                                  : Colors.black87,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          Text(
                            todo.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.75),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('M月d日(E)', 'ja').format(todo.dueDate),
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.6),
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // タグ（あれば表示）
                          _TagWrap(tags: todo.tags),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedActionButton extends StatefulWidget {
  const AnimatedActionButton({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final Color color;
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  double _progress = 0.0;
  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (_) => widget.onPressed(),
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double width = 56 + (maxWidth - 56) * _progress;
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _progress = (details.localPosition.dx / maxWidth).clamp(
                  0.0,
                  1.0,
                );
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() => _progress = 0.0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              width: width,
              height: 56,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  if (_progress > 0.6) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags, this.max = 4});

  final List<String> tags;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final toShow = tags.take(max).toList();
    final remain = tags.length - toShow.length;

    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: [
        for (final t in toShow)
          Chip(
            label: Text(t, style: const TextStyle(fontSize: 12.5)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: StadiumBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: .35)),
            ),
            backgroundColor: Colors.white.withValues(alpha: .10),
          ),
        if (remain > 0)
          Chip(
            label: Text('+$remain', style: const TextStyle(fontSize: 12.5)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: StadiumBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: .35)),
            ),
            backgroundColor: Colors.white.withValues(alpha: .10),
          ),
      ],
    );
  }
}
