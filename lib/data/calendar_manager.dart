import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppCalendarEntry {
  final String title;
  final String description;
  final DateTime date;
  final Map<String, String>? smartDetails;

  AppCalendarEntry({
    required this.title,
    required this.description,
    required this.date,
    this.smartDetails,
  });
}

class CalendarManager extends ChangeNotifier {
  final Map<DateTime, List<AppCalendarEntry>> _entries = {};

  Map<DateTime, List<AppCalendarEntry>> get entries => _entries;

  void addEntry(AppCalendarEntry entry) {
    final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
    _entries.putIfAbsent(key, () => []);
    _entries[key]!.add(entry);
    notifyListeners();
  }

  List<AppCalendarEntry> getEntriesForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _entries[key] ?? [];
  }

  Future<void> removeEntry(AppCalendarEntry entry) async {
    final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final list = _entries[key];
    if (list != null) {
      list.remove(entry);
      if (list.isEmpty) {
        _entries.remove(key);
      }
      notifyListeners();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final habitPlans = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habit_plans');

      final snapshot = await habitPlans.get();
      for (var doc in snapshot.docs) {
        if (doc.data()['목표의 내용'] == entry.title) {
          await doc.reference.delete();
          break;
        }
      }
    } catch (e) {
      debugPrint('Firestore 삭제 중 오류: $e');
    }
  }

  Future<void> loadEventsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habit_plans')
        .get();

    _entries.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final deadlineStr = data['기한'];
      final title = data['목표의 내용'] ?? doc.id;
      final description = title;

      final smartDetails = {
        '목표의 내용': data['목표의 내용']?.toString() ?? '',
        '측정 방법': data['측정 방법']?.toString() ?? '',
        '실현 가능성': data['실현 가능성']?.toString() ?? '',
        '관련성': data['관련성']?.toString() ?? '',
        '기한': deadlineStr?.toString() ?? '',
      };

      try {
        final date = DateTime.parse(deadlineStr);
        final key = DateTime(date.year, date.month, date.day);
        final entry = AppCalendarEntry(
          title: title,
          description: description,
          date: date,
          smartDetails: smartDetails,
        );

        _entries.putIfAbsent(key, () => []);
        _entries[key]!.add(entry);
      } catch (e) {
        debugPrint('날짜 파싱 실패: $deadlineStr');
      }
    }

    notifyListeners();
  }
}
