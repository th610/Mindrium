import 'dart:convert';

class Emotion {
  final String id;
  final String name;
  final String emoji;
  bool isSelected;

  Emotion({
    required this.id,
    required this.name,
    required this.emoji,
    this.isSelected = false,
  });

  Emotion copyWith({
    String? id,
    String? name,
    String? emoji,
    bool? isSelected,
  }) {
    return Emotion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Emotion && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

extension EmotionJson on Emotion {
  String toJson() =>
      jsonEncode({
        'id': id,
        'name': name,
        'emoji': emoji,
        'isSelected': isSelected,
      });

  static Emotion fromJson(String jsonStr) {
    final json = jsonDecode(jsonStr);
    return Emotion(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      isSelected: json['isSelected'] ?? false,
    );
  }
}

// 미리 정의된 감정 목록
final List<Emotion> predefinedEmotions = [
  Emotion(id: '1', name: '슬퍼요', emoji: '😢'),
  Emotion(id: '2', name: '불안해요', emoji: '😰'),
  Emotion(id: '3', name: '무서워요', emoji: '😨'),
  Emotion(id: '4', name: '답답해요', emoji: '😮‍💨'),
  Emotion(id: '5', name: '화나요', emoji: '😠'),
  Emotion(id: '6', name: '우울해요', emoji: '😔'),
  Emotion(id: '7', name: '걱정돼요', emoji: '😟'),
  Emotion(id: '8', name: '초조해요', emoji: '😖'),
];
