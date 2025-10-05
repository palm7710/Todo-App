enum SortKey { dueDate, title, completed }

class SortOption {
  final SortKey key;
  final bool ascending;
  const SortOption({required this.key, required this.ascending});

  SortOption copyWith({SortKey? key, bool? ascending}) =>
      SortOption(key: key ?? this.key, ascending: ascending ?? this.ascending);
}
