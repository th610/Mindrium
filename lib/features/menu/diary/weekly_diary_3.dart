import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/data/diary_entry_repository.dart';
import 'package:gad_app_team/data/diary_entry_provider.dart';
import 'package:gad_app_team/data/weekly_entry_repository.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';
import 'package:gad_app_team/data/emotion.dart';

import 'package:gad_app_team/utils/emotion_utils.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/diary_entry_dialog.dart';


// 주간 일기 3단계 : 불안 점수와 회고 입력
class WeeklyDiaryScreen3 extends StatefulWidget {
  const WeeklyDiaryScreen3({super.key});

  @override
  State<WeeklyDiaryScreen3> createState() => _WeeklyDiaryScreen3State();
}

class _WeeklyDiaryScreen3State extends State<WeeklyDiaryScreen3> {
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _textFieldScrollController = ScrollController();
  double _anxietyScore = 0.0;
  int _currentPage = 0;
  late int _currentWeek = 0;

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
    if (!dayCounter.isUserLoaded) return;
    _currentWeek = dayCounter.getWeekNumberFromJoin(DateTime.now());

    // provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final dailyRepo = Provider.of<DiaryEntryRepository>(context, listen: false);
      final weekDaily = await dailyRepo.fetchEntriesByWeek(userId: userId, weekNumber: _currentWeek);
      if (!mounted) return;
      Provider.of<DiaryEntriesForCurrentWeekProvider>(context, listen: false).setEntries(weekDaily);

      final weeklyRepo = Provider.of<WeeklyEntryRepository>(context, listen: false);
      final weeklyNow = await weeklyRepo.fetchWeeklyDiaryByWeekId(userId: userId, weekId: _currentWeek.toString().padLeft(3, '0'));
      if (!mounted) return;
      if (weeklyNow != null) Provider.of<WeeklyEntryByCurrentWeekProvider>(context, listen: false).setEntry(weeklyNow);
    });

    // 기존 회고 내용이 있다면 초기화
    final previous = Provider.of<WeeklyEntryNotifier>(context, listen: false).entry?.thoughtNote ?? '';
    _noteController.text = previous;
  }

  // 주간 일기 최종 저장
  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    final provider = context.read<WeeklyEntryNotifier>();

    // 회고 및 불안 점수 업데이트
    provider.updateThoughtNote(note);
    provider.updateEmotionsAndScore(
      provider.entry?.emotions ?? [],
      _anxietyScore,
    );

    await provider.save();
    await provider.loadTodayEntry();
    if (!mounted) return;

    final savedEntry = provider.entry;
    if (savedEntry != null && savedEntry.thoughtNote == _noteController.text.trim()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
          AlertDialog(
            title: const Text('저장 완료'),
            content: const Text('이번주 주간 일기가 저장되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).popUntil((route) => route.settings.name == '/contents'),
                child: const Text('확인'),
              ),
            ],
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<DiaryEntriesForCurrentWeekProvider>().entries;
    final isValid = _noteController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: '주간 일기 (3/3)',
        confirmOnBack: true,
        confirmOnHome: true,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(
          onBack: () => Navigator.pop(context),
          onNext: isValid ? _submit : null,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entries.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 9 / 16,
                      child: PageView.builder(
                        itemCount: entries.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Padding(
                            padding: const EdgeInsets.all(AppSizes.padding),
                            child: DiarySummaryCard(
                              entry: entry,
                              onTap: () => showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => DiaryEntryDialog(entry: entry),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.space),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(entries.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.all(AppSizes.padding),
                          width: isActive ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.black : Colors.grey,
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                        );
                      }),
                    ),
                  ],
                )
              else
                const Text(
                  '이번주 걱정일기가 없습니다.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.fontSize, color: Colors.black87),
                ),
              const SizedBox(height: AppSizes.space),

              const Text('이번주 불안 정도',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.fontSize, color: Colors.black87)),
              Row(
                children: [
                  const SizedBox(width: AppSizes.space),
                  Text(
                    _anxietyScore.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: AppSizes.fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space),
                  Expanded(
                    child: Slider(
                      value: _anxietyScore,
                      min: 0.0,
                      max: 5.0,
                      divisions: 5,
                      label: _anxietyScore.toInt().toString(),
                      inactiveColor: Colors.grey.shade400,
                      onChanged: (value) {
                        setState(() {
                          _anxietyScore = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space),

              const Text('이번주 회고',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.fontSize, color: Colors.black87)),
              const SizedBox(height: AppSizes.space),

              SizedBox(
                width: double.infinity,
                height: 200,
                child: Scrollbar(
                  controller: _textFieldScrollController,
                  thumbVisibility: true,
                  thickness: 7,
                  radius: const Radius.circular(8),
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _textFieldScrollController,
                    child: TextField(
                      controller: _noteController,
                      maxLines: null,
                      expands: false,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                          hintText: '이번주 나를 불안하게 했던 상황은...',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.black12),
                          ),
                        ),
                      onChanged: (text) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _textFieldScrollController.dispose();
    super.dispose();
  }
}

// 걱정 일기 요약 카드
class DiarySummaryCard extends StatelessWidget {
  final DiaryEntryModel entry;
  final VoidCallback? onTap;

  const DiarySummaryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHeight = MediaQuery.of(context).size.width * 9 / 16;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: const Color(0xFF4B5FD6), width: 1),
        ),
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${int.tryParse(entry.id).toString()}일차 걱정 일기',
                style: const TextStyle(
                    fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),

            const SizedBox(height: AppSizes.space),

            FutureBuilder<List<Emotion>>(
              future: mapNamesToEmotions(entry.emotion),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                final emotions = snapshot.data!;
                return Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: emotions.map((e) {
                    return Container(
                      padding: const EdgeInsets.all(AppSizes.padding),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                      child: Text(
                        e.name.length > 6 ? '${e.emoji} ${e.name.substring(0, 6)}…' :
                        '${e.emoji} ${e.name}',
                        style: const TextStyle(fontSize: AppSizes.fontSize),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSizes.space),

            Text(
              entry.note.length > 40 ? '${entry.note.substring(0, 90)}...' : entry.note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: AppSizes.fontSize, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
