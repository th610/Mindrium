import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/activitiy_card.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';

import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/diary_entry_repository.dart';
import 'package:gad_app_team/data/diary_entry_provider.dart';
import 'package:gad_app_team/data/weekly_entry_repository.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';

/// 콘텐츠 메뉴 화면
class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
      final dailyRepo = Provider.of<DiaryEntryRepository>(context, listen: false);
      final weeklyRepo = Provider.of<WeeklyEntryRepository>(context, listen: false);

      final userId = userProvider.userId;
      final currentWeek = dayCounter.getWeekNumberFromJoin(DateTime.now());

      // 전체 일기 데이터 세팅
      final allDaily = await dailyRepo.fetchAllEntriesForUser(userId);
      if (!mounted) return;
      Provider.of<AllDiaryEntriesProvider>(context, listen: false).setEntries(allDaily);

      final allWeekly = await weeklyRepo.fetchAllWeeklyEntriesForUser(userId);
      if (!mounted) return;
      Provider.of<AllWeeklyEntriesProvider>(context, listen: false).setEntries(allWeekly);

      // 오늘 일기
      final todayEntry = await dailyRepo.fetchEntriesByDate(userId: userId, date: DateTime.now(),);
      if (todayEntry != null) {
        if (!mounted) return;
        Provider.of<DiaryEntryTodayProvider>(context, listen: false).setEntry(todayEntry);
      } else {
        if (!mounted) return;
        Provider.of<DiaryEntryTodayProvider>(context, listen: false).clear();
      }

      // 이번주 주간일기
      final thisWeekId = currentWeek.toString().padLeft(3, '0');
      final weeklyEntry = await weeklyRepo.fetchWeeklyDiaryByWeekId(userId: userId, weekId: thisWeekId,);
      if (weeklyEntry != null) {
        if (!mounted) return;
        Provider.of<WeeklyEntryByCurrentWeekProvider>(context, listen: false).setEntry(weeklyEntry);
      } else {
        if (!mounted) return;
        Provider.of<WeeklyEntryByCurrentWeekProvider>(context, listen: false).clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(title: '메뉴'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0,16,0,0),
        child: ListView(
          children: [
            ActivityCard(
              icon: Icons.menu_book,
              title: '교육',
              enabled: true,
              onTap: () => Navigator.pushNamed(context,'/education'),
            ),
            const SizedBox(height: AppSizes.space),
            ActivityCard(
              icon: Icons.self_improvement,
              title: '심신 이완',
              enabled: true,
              onTap: () => Navigator.pushNamed(context,'/breath_muscle_relaxation'),
            ),
            const SizedBox(height: AppSizes.space),
            ActivityCard(
              icon: Icons.edit_note,
              title: '걱정 일기',
              enabled: true,
              onTap: () => Navigator.pushNamed(context,'/diary_entry'),
            ),
            const SizedBox(height: AppSizes.space),
            ActivityCard(
              icon: Icons.healing,
              title: '노출 훈련',
              enabled: true,
              onTap: () => Navigator.pushNamed(context,'/exposure'),
            ),
            const SizedBox(height: AppSizes.space),
            ActivityCard(
              icon: Icons.calendar_month,
              title: '캘린더',
              enabled: true,
              onTap: () => Navigator.pushNamed(context,'/calendar'),
            ),
            const SizedBox(height: AppSizes.space),
            ActivityCard(
              icon: Icons.alarm,
              title: '알림',
              enabled: true,
              onTap: () => Navigator.pushNamed(context,'/notification'),
            ),
          ],
        ),
      ),
    );
  }
}