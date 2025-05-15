import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/data/diary_entry_repository.dart';
import 'package:gad_app_team/data/diary_entry_provider.dart';
import 'package:gad_app_team/data/weekly_entry_model.dart';
import 'package:gad_app_team/data/weekly_entry_repository.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/task_tile.dart';
import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/features/menu/diary/daily_diary_readonly.dart';
import 'package:gad_app_team/features/menu/diary/weekly_diary_readonly.dart';


class DiaryRecordScreen extends StatefulWidget {
  const DiaryRecordScreen({super.key});

  @override
  State<DiaryRecordScreen> createState() => _DiaryRecordScreenState();
}

class _DiaryRecordScreenState extends State<DiaryRecordScreen> {
  int _currentPage = 0;
  late final int _currentWeek;

  @override
  void initState() {
    super.initState();
    final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
    if (!dayCounter.isUserLoaded) return;
    _currentWeek = dayCounter.getWeekNumberFromJoin(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dailyRepo = Provider.of<DiaryEntryRepository>(context, listen: false);
      final weeklyRepo = Provider.of<WeeklyEntryRepository>(context, listen: false);

      final userId = userProvider.userId;

      // 전체 일기 데이터 세팅
      final allDaily = await dailyRepo.fetchAllEntriesForUser(userId);
      if (!mounted) return;
      Provider.of<AllDiaryEntriesProvider>(context, listen: false).setEntries(allDaily);

      final allWeekly = await weeklyRepo.fetchAllWeeklyEntriesForUser(userId);
      if (!mounted) return;
      Provider.of<AllWeeklyEntriesProvider>(context, listen: false).setEntries(allWeekly);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allDailyEntries = Provider.of<AllDiaryEntriesProvider>(context).entries;
    final allWeeklyEntries = Provider.of<AllWeeklyEntriesProvider>(context).entries;

    // 특정 주차의 일별 일기 가져오기
    List<DiaryEntryModel> getDailyEntriesForWeek(int weekNumber) {
      final start = (weekNumber - 1) * 7 + 1;
      final end = start + 6;
      return allDailyEntries.where((entry) {
        final idNum = int.tryParse(entry.id);
        return idNum != null && idNum >= start && idNum <= end;
      }).toList();
    }

    // 특정 주차의 주간 일기 가져오기
    WeeklyEntryModel? getWeeklyEntryForWeek(int weekNumber) {
      final weekId = weekNumber.toString().padLeft(3, '0');
      final matches = allWeeklyEntries.where((e) => e.id == weekId);
      return matches.isEmpty ? null : matches.first;
    }

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '지난 일기',
        //leadingIcon: Icons.storage_outlined,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder( // 각 주차의 일기 목록은 슬라이드로 구성
              itemCount: _currentWeek, // 1주차 ~ 현재 주차까지
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final weekId = index + 1;
                final dailyEntries = getDailyEntriesForWeek(weekId);
                final weeklyEntry = getWeeklyEntryForWeek(weekId);

                return Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: CardContainer(
                    title: '$weekId주차',
                    titleStyle: TextStyle(
                      fontSize: AppSizes.fontSize,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dailyEntries.isEmpty)
                          const Text('작성된 일별 일기가 없습니다.')
                        else
                          Column(
                            children: dailyEntries.map((entry) => TaskTile(
                              title: '${int.tryParse(entry.id)}일차 일기',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DailyDiaryReadOnly(entry: entry),
                                ),
                              ),
                            )).toList(),
                          ),
                        const SizedBox(height: AppSizes.space),
                        if (weeklyEntry == null)
                          const Text('작성된 주간 일기가 없습니다.')
                        else
                          TaskTile(
                            title: '주간 일기',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeeklyDiaryReadOnly(entry: weeklyEntry),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 슬라이드 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_currentWeek, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.fromLTRB(4,0,4,8),
                width: isActive ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.indigo : Colors.grey,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.space),
        ],
      ),
    );
  }
}
