import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/data/emotion.dart';

// 전체 감정 목록 불러오기 (기본 + 커스텀)
Future<List<Emotion>> loadEmotionList() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('customEmotions') ?? [];
  final custom = saved.map((e) => EmotionJson.fromJson(e)).toList();
  return [...predefinedEmotions, ...custom];
}

// 커스텀 감정 추가
Future<void> addCustomEmotion(Emotion emotion) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('customEmotions') ?? [];

  final existing = saved.map((s) => EmotionJson.fromJson(s)).toList();
  final alreadyExists = existing.any((e) => e.name == emotion.name);

  if (!alreadyExists) {
    saved.add(emotion.toJson());
    await prefs.setStringList('customEmotions', saved);
  }
}

// 커스텀 감정 제거
Future<void> removeCustomEmotion(String name) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('customEmotions') ?? [];

  saved.removeWhere((e) => EmotionJson.fromJson(e).name == name);
  await prefs.setStringList('customEmotions', saved);
}

// 감정 이름만 알아도 이모지 표현 가능
Future<List<Emotion>> mapNamesToEmotions(List<String> names) async {
  final all = await loadEmotionList(); // SharedPreferences에서 모든 감정 불러오기
  final emotionMap = { for (var e in all) e.name: e};

  return names.map((name) =>
  emotionMap[name] ??
      Emotion(id: '', name: name, emoji: '') // 매핑 실패 시 fallback
  ).toList();
}
