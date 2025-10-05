import 'dart:ui'; // ← ぼかし用
import 'package:flutter/material.dart';

import '../services/todo_service.dart';
import '../widgets/todo_list.dart';
import 'add_todo_screen.dart';

// ★ 追加
import '../models/sort_option.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.todoService});
  final TodoService todoService;

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  Key _todoListKey = UniqueKey();

  // ★ 追加: 検索と並び替えの状態
  String _searchQuery = '';
  SortOption _sortOption = const SortOption(
    key: SortKey.dueDate,
    ascending: true,
  );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.white30,
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
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: TodoList(
                key: _todoListKey,
                todoService: widget.todoService,
                searchQuery: _searchQuery,
                sortOption: _sortOption,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: GlassExpandingFab(
        onAdd: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTodoScreen(todoService: widget.todoService),
            ),
          );
          if (updated == true) setState(() => _todoListKey = UniqueKey());
        },
        onImage: () {},
        onInbox: () {},
        mainColorBegin: Colors.blue,
        mainColorEnd: Colors.red,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      appBar: AppBar(
        backgroundColor: Colors.white30,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/ka-bi.png', // 画像のパス（pubspec.yamlにも登録しておく）
              height: 32, // お好みのサイズ
              width: 32,
            ),
            const SizedBox(width: 8), // 画像と文字の間隔
            const Text(
              'TODOリスト',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        // ★ 追加: 右上に並び替えメニュー
        actions: [
          PopupMenuButton<String>(
            tooltip: '並び替え',
            onSelected: (value) {
              if (value.startsWith('key:')) {
                final keyName = value.substring(4);
                final newKey = switch (keyName) {
                  'due' => SortKey.dueDate,
                  'title' => SortKey.title,
                  'done' => SortKey.completed,
                  _ => _sortOption.key,
                };
                setState(() {
                  _sortOption = _sortOption.copyWith(key: newKey);
                });
              } else if (value == 'asc') {
                setState(() {
                  _sortOption = _sortOption.copyWith(ascending: true);
                });
              } else if (value == 'desc') {
                setState(() {
                  _sortOption = _sortOption.copyWith(ascending: false);
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'key:due', child: Text('期限で並び替え')),
              const PopupMenuItem(value: 'key:title', child: Text('タイトルで並び替え')),
              const PopupMenuItem(value: 'key:done', child: Text('完了状態で並び替え')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'asc', child: Text('昇順')),
              const PopupMenuItem(value: 'desc', child: Text('降順')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],

        // ★ 追加: 下にガラス調の検索バーを載せる
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: .25),
                        Colors.white.withValues(alpha: .07),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'タイトルやメモを検索…',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: .25),
                    Colors.white.withValues(alpha: .07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: .35),
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
}

/// 丸い“ガラス”FAB（遷移時に背景へ影響させない版）
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.size,
    required this.icon,
    required this.onTap,
    this.iconSize,
    this.opacityLow = 0.10,
    this.blurSigma = 18,
    this.elevationColor,
    this.tooltip,
    this.foregroundColor,
    this.borderColor,
    super.key,
  });

  final double size;
  final IconData icon;
  final VoidCallback? onTap;
  final double? iconSize;
  final double opacityLow;
  final double blurSigma;
  final Color? elevationColor;
  final String? tooltip;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = ClipOval(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: opacityLow),
                    ],
                  ),
                  border: Border.all(
                    color: borderColor ?? Colors.white,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (elevationColor ?? Colors.black).withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: foregroundColor ?? Colors.white,
                    size: iconSize ?? (size * 0.44),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return content;
    return Tooltip(message: tooltip!, child: content);
  }
}

/// FancyFab の挙動（展開/格納アニメ）をガラス調に移植した FAB
class GlassExpandingFab extends StatefulWidget {
  const GlassExpandingFab({
    super.key,
    required this.onAdd,
    required this.onImage,
    required this.onInbox,
    this.mainColorBegin = Colors.blue,
    this.mainColorEnd = Colors.red,
    this.duration = const Duration(milliseconds: 500),
  });

  final VoidCallback onAdd;
  final VoidCallback onImage;
  final VoidCallback onInbox;

  /// メイン（トグル）FABの色アニメ開始/終了色
  final Color mainColorBegin;
  final Color mainColorEnd;

  final Duration duration;

  @override
  State<GlassExpandingFab> createState() => _GlassExpandingFabState();
}

class _GlassExpandingFabState extends State<GlassExpandingFab>
    with SingleTickerProviderStateMixin {
  bool _isOpened = false;
  late final AnimationController _ctrl;
  late final Animation<double> _animateIcon;
  late final Animation<double> _translate;
  late final Animation<Color?> _buttonColor;

  // 基準になるFABの高さ（移動量の係数に使う）
  static const double _fabHeight = 56.0;
  static const Curve _curve = Curves.easeOut;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}));
    _animateIcon = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);

    _buttonColor =
        ColorTween(
          begin: widget.mainColorBegin,
          end: widget.mainColorEnd,
        ).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 1.0, curve: Curves.linear),
          ),
        );

    _translate = Tween<double>(begin: _fabHeight, end: -14.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.75, curve: _curve),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpened) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    _isOpened = !_isOpened;
  }

  // 子ボタン（ガラス調・小さめ）
  Widget _miniButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _GlassCircleButton(
      size: 48,
      icon: icon,
      onTap: () {
        // 子を押したら閉じたいケースが多いので閉じる
        if (_isOpened) _toggle();
        onTap();
      },
      iconSize: 22,
      tooltip: tooltip,
    );
  }

  // メインのトグル（ガラス調 + 下地に色アニメのレイヤを追加）
  Widget _mainToggle() {
    final current = _buttonColor.value ?? widget.mainColorBegin;
    final brightness = ThemeData.estimateBrightnessForColor(current);
    final fg = brightness == Brightness.dark ? Colors.white : Colors.black87;
    final border = brightness == Brightness.dark
        ? Colors.white
        : Colors.black26;
    final menuOpacity = (1.0 - _animateIcon.value).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // 下地の色アニメーション（やりすぎないよう半透明）
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: current.withValues(alpha: 0.38),
          ),
        ),
        _GlassCircleButton(
          size: 64,
          icon: Icons.menu, // 実アイコンは AnimatedIcon で上書き
          onTap: _toggle,
          tooltip: 'Toggle',
          foregroundColor: fg.withValues(alpha: menuOpacity),
          borderColor: border,
        ),
        // AnimatedIcon を前面に
        IgnorePointer(
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _animateIcon,
                color: fg,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Transform で縦にせり上がる配置は FancyFab と同じ思想
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translate.value * 3.0,
            0.0,
          ),
          child: _miniButton(
            tooltip: 'Add',
            icon: Icons.add,
            onTap: widget.onAdd,
          ),
        ),
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translate.value * 2.0,
            0.0,
          ),
          child: _miniButton(
            tooltip: 'Image',
            icon: Icons.image,
            onTap: widget.onImage,
          ),
        ),
        Transform(
          transform: Matrix4.translationValues(0.0, _translate.value, 0.0),
          child: _miniButton(
            tooltip: 'Inbox',
            icon: Icons.inbox,
            onTap: widget.onInbox,
          ),
        ),
        // 一番下にトグル
        _mainToggle(),
      ],
    );
  }
}
