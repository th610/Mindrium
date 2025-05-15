import 'package:flutter/material.dart';
import 'package:gad_app_team/data/weekly_entry_model.dart';
import 'package:gad_app_team/data/weekly_entry_repository.dart';

class WeeklyEntryNotifier extends ChangeNotifier {
  final WeeklyEntryRepository repository;
  final String userId;
  final String weekId;

  WeeklyEntryModel? _entry;
  WeeklyEntryModel? get entry => _entry;

  WeeklyEntryNotifier({
    required this.repository,
    required this.userId,
    required this.weekId,
  });

  // Firestore에서 이번주(오늘) 일기 불러오기
  Future<void> loadTodayEntry() async {
    final result = await repository.fetchWeeklyDiaryByWeekId(
      userId: userId,
      weekId: weekId,
    );
    _entry = result;
    notifyListeners();
  }

  // 초기 상태 설정 (예: 1단계에서 작성된 모델)
  void initializeEntry(WeeklyEntryModel model) {
    _entry = model;
    notifyListeners();
  }

  // 주간 요약 수정
  void updateWeeklyNote(String note) {
    if (_entry == null) return;
    _entry = _entry!.copyWith(weeklyNote: note);
    notifyListeners();
  }

  // 회고 수정
  void updateThoughtNote(String note) {
    if (_entry == null) return;
    _entry = _entry!.copyWith(thoughtNote: note);
    notifyListeners();
  }

  // 감정 + 불안 점수 수정
  void updateEmotionsAndScore(List<String> emotions, double score) {
    if (_entry == null) return;
    _entry = _entry!.copyWith(emotions: emotions, anxietyScore: score);
    notifyListeners();
  }

  // 상태 초기화
  void clearEntry() {
    _entry = null;
    notifyListeners();
  }

  // 저장 (Firestore로 전송)
  Future<void> save() async {
    if (_entry == null) return;
    await repository.saveWeeklyDiary(_entry!);
    notifyListeners();
  }
}

// 전체 주간 일기 로딩
class AllWeeklyEntriesProvider extends ChangeNotifier {
  final WeeklyEntryRepository repository;
  final String userId;

  List<WeeklyEntryModel> _entries = [];
  List<WeeklyEntryModel> get entries => _entries;

  AllWeeklyEntriesProvider({
    required this.repository,
    required this.userId,
  });

  Future<void> load() async {
    _entries = await repository.fetchAllWeeklyEntriesForUser(userId);
    notifyListeners();
  }

  void clear() {
    _entries = [];
    notifyListeners();
  }

  void setEntries(List<WeeklyEntryModel> entries) {
    _entries = entries;
    notifyListeners();
  }
}

// 현재 주차 주간 일기 로딩
class WeeklyEntryByCurrentWeekProvider extends ChangeNotifier {
  final WeeklyEntryRepository repository;
  final String userId;
  final int currentWeek;

  WeeklyEntryModel? _entry;
  WeeklyEntryModel? get entry => _entry;

  WeeklyEntryByCurrentWeekProvider({
    required this.repository,
    required this.userId,
    required this.currentWeek,
  });

  Future<void> load() async {
    final weekId = currentWeek.toString().padLeft(3, '0');
    _entry = await repository.fetchWeeklyDiaryByWeekId(
      userId: userId,
      weekId: weekId,
    );
    notifyListeners();
  }

  void clear() {
    _entry = null;
    notifyListeners();
  }

  void setEntry(WeeklyEntryModel model) {
    _entry = model;
    notifyListeners();
  }
}

// 현재 주차 주간 일기 존재 여부
class WeeklyEntryExistsProvider extends ChangeNotifier {
  final WeeklyEntryRepository repository;
  final String userId;

  bool? _exists;
  bool? get exists => _exists;

  WeeklyEntryExistsProvider({
    required this.repository,
    required this.userId,
  });

  Future<void> check(String weekId) async {
    final entry = await repository.fetchWeeklyDiaryByWeekId(
      userId: userId,
      weekId: weekId,
    );
    _exists = entry != null;
    notifyListeners();
  }

  void clear() {
    _exists = null;
    notifyListeners();
  }
}
