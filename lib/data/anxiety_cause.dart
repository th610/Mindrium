class AnxietyCause {
  final String id;
  final String title;
  final String description;
  final double anxietyLevel;
  final String? fishEmoji;
  final List<String>? selectedEmotions;
  final String? photoPath; 

  const AnxietyCause({
    required this.id,
    required this.title,
    required this.description,
    required this.anxietyLevel,
    this.fishEmoji,
    this.selectedEmotions,
    this.photoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'anxietyLevel': anxietyLevel,
      'fishEmoji': fishEmoji,
      'selectedEmotions': selectedEmotions,
    };
  }

  factory AnxietyCause.fromJson(Map<String, dynamic> json) {
    return AnxietyCause(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      anxietyLevel: (json['anxietyLevel'] as num).toDouble(),
      fishEmoji: json['fishEmoji'] as String?,
      selectedEmotions: json['selectedEmotions'] as List<String>?,
    );
  }

  AnxietyCause copyWith({
    String? id,
    String? title,
    String? description,
    double? anxietyLevel,
    String? fishEmoji,
    List<String>? selectedEmotions,
  }) {
    return AnxietyCause(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      fishEmoji: fishEmoji ?? this.fishEmoji,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnxietyCause &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
