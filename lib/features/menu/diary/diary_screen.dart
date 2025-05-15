import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/features/menu/diary/daily_diary_screen.dart';
import 'package:gad_app_team/features/menu/diary/weekly_diary_readonly.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/data/diary_entry_provider.dart';
import 'package:gad_app_team/data/weekly_entry_model.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';

// contents와 일기 화면들 간의 gate 역할을 함 (UI 없음)
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasInitialized) {
      _hasInitialized = true;
      final navigator = Navigator.of(context);
      final dayCounter = context.watch<UserDayCounter>();
      final weeklyProvider = context.watch<WeeklyEntryByCurrentWeekProvider>();
      final diaryProvider = context.watch<DiaryEntryNotifier>();

      // 사용자 정보가 준비 안 되었을 경우
      if (!dayCounter.isUserLoaded) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final isWeeklyDay = dayCounter.daysSinceJoin % 7 == 0;

      // build 직후에 navigation 수행
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (isWeeklyDay) {
          // 이번 주 주간일기 로딩
          final weekly = weeklyProvider.entry;
          if (weekly == null) {
            navigator.pushReplacementNamed('/weekly_diary_1');
          } else {
            final result = await _askToViewWeekly(weekly);
            if (!mounted) return;
            if (result) {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => WeeklyDiaryReadOnly(entry: weekly),
                ),
              );
            } else {
              navigator.pop();
            }
          }
        } else {
          // 일별 일기 로딩
          final entry = diaryProvider.entry;
          if (entry == null) {
            navigator.pushReplacementNamed('/daily_diary');
          } else {
            final result = await _askToModifyDaily(entry);
            if (!mounted) return;
            if (result) {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DailyDiaryScreen(entry: entry), // 있으면 수정 모드
                ),
              );
            } else {
              navigator.pop();
            }
          }
        }
      });
    }

    return const Scaffold(); // 화면 자체는 없고 gate 역할만
  }

  // 일별 일기 수정 여부 팝업
  Future<bool> _askToModifyDaily(DiaryEntryModel entry) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('이미 작성된 일기'),
        content: const Text('오늘 걱정 일기를 이미 작성했어요. 수정하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나가기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('수정하기'),
          ),
        ],
      ),
    ) ??
        false;
  }

  // 주간 일기 열람 여부 팝업
  Future<bool> _askToViewWeekly(WeeklyEntryModel entry) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('이번 주 일기 확인'),
        content: const Text('이번 주 주간일기를 이미 작성했어요. 내용을 확인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나가기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인하기'),
          ),
        ],
      ),
    ) ??
        false;
  }
}


