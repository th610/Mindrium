import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/data/diary_entry_repository.dart';

class DiaryEntryNotifier extends ChangeNotifier {
  final DiaryEntryRepository repository;
  final String userId;
  final int daysSinceJoin;

  DiaryEntryModel? _entry;
  DiaryEntryModel? get entry => _entry;

  DiaryEntryNotifier({
    required this.repository,
    required this.userId,
    required this.daysSinceJoin,
  });

  // Firestore에서 오늘 일기 불러오기
  Future<void> loadTodayEntry() async {
    final result = await repository.fetchEntryByDaysSinceJoin(
      userId: userId,
      id: daysSinceJoin.toString().padLeft(3, '0'),
    );
    _entry = result;
    notifyListeners();
  }

  // 일기 저장 (감정, 메모, 사진 포함)
  Future<void> save({
    required List<String> emotions,
    required String note,
    required File? localPhotoFile,
  }) async {
    final now = DateTime.now();
    PhotoModel? photo;

    // 1. 사진 업로드
    if (localPhotoFile != null) {
      final photoId = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('diary_photos/$photoId.png');
      await ref.putFile(localPhotoFile);
      final url = await ref.getDownloadURL();

      photo = PhotoModel(
        id: photoId,
        path: url,
        timestamp: now,
      );
    }

    // 2. 모델 구성
    final newEntry = DiaryEntryModel(
      id: daysSinceJoin.toString().padLeft(3, '0'),
      userId: userId,
      date: now,
      emotion: emotions,
      note: note,
      photo: photo,
    );

    // 3. Firestore에 저장
    await repository.saveEntry(newEntry);

    // 4. 상태 갱신
    _entry = newEntry;
    notifyListeners();
  }

  // 상태 초기화
  void clear() {
    _entry = null;
    notifyListeners();
  }

  // 외부 모델로 초기화 (예: 읽기 모드 진입 시)
  void initialize(DiaryEntryModel model) {
    _entry = model;
    notifyListeners();
  }
}

// 전체 일기 로딩
class AllDiaryEntriesProvider extends ChangeNotifier {
  final DiaryEntryRepository repository;
  final String userId;

  List<DiaryEntryModel> _entries = [];
  List<DiaryEntryModel> get entries => _entries;

  AllDiaryEntriesProvider({
    required this.repository,
    required this.userId,
  });

  Future<void> load() async {
    _entries = await repository.fetchAllEntriesForUser(userId);
    notifyListeners();
  }

  void clear() {
    _entries = [];
    notifyListeners();
  }

  void setEntries(List<DiaryEntryModel> entries) {
    _entries = entries;
    notifyListeners();
  }
}

// 오늘 일기 존재 여부
class DiaryEntryExistsTodayProvider extends ChangeNotifier {
  final DiaryEntryRepository repository;
  final String userId;

  bool? _exists;
  bool? get exists => _exists;

  DiaryEntryExistsTodayProvider({
    required this.repository,
    required this.userId,
  });

  Future<void> checkTodayEntry(DateTime today) async {
    final entry = await repository.fetchEntriesByDate(
      userId: userId,
      date: today,
    );
    _exists = entry != null;
    notifyListeners();
  }

  void clear() {
    _exists = null;
    notifyListeners();
  }
}

// 오늘 일기 로딩
class DiaryEntryTodayProvider extends ChangeNotifier {
  final DiaryEntryRepository repository;
  final String userId;

  DiaryEntryModel? _entry;
  DiaryEntryModel? get entry => _entry;

  DiaryEntryTodayProvider({
    required this.repository,
    required this.userId,
  });

  Future<void> load(DateTime today) async {
    _entry = await repository.fetchEntriesByDate(
      userId: userId,
      date: today,
    );
    notifyListeners();
  }

  void clear() {
    _entry = null;
    notifyListeners();
  }

  void setEntry(DiaryEntryModel model) {
    _entry = model;
    notifyListeners();
  }
}

// 이번주 일기 목록
class DiaryEntriesForCurrentWeekProvider extends ChangeNotifier {
  final DiaryEntryRepository repository;
  final String userId;

  List<DiaryEntryModel> _entries = [];
  List<DiaryEntryModel> get entries => _entries;

  DiaryEntriesForCurrentWeekProvider({
    required this.repository,
    required this.userId,
  });

  Future<void> load(int weekNumber) async {
    _entries = await repository.fetchEntriesByWeek(
      userId: userId,
      weekNumber: weekNumber,
    );
    notifyListeners();
  }

  void clear() {
    _entries = [];
    notifyListeners();
  }

  void setEntries(List<DiaryEntryModel> entries) {
    _entries = entries;
    notifyListeners();
  }
}
