class RecommendationItem {
  const RecommendationItem({
    required this.id,
    required this.title,
    required this.trigger,
    this.isDone = false,
  });

  final String id;
  final String title;
  final String trigger;
  final bool isDone;

  RecommendationItem copyWith({bool? isDone}) {
    return RecommendationItem(
      id: id,
      title: title,
      trigger: trigger,
      isDone: isDone ?? this.isDone,
    );
  }
}

