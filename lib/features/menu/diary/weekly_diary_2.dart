import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/weekly_entry_repository.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/emotion_selector.dart';

// 주간 일기 2단계 : 감정 선택
class WeeklyDiaryScreen2 extends StatefulWidget {
  const WeeklyDiaryScreen2({super.key});

  @override
  State<WeeklyDiaryScreen2> createState() => _WeeklyDiaryScreen2State();
}

class _WeeklyDiaryScreen2State extends State<WeeklyDiaryScreen2> {
  List<String> selectedEmotions = [];
  final TextEditingController _controller = TextEditingController(); // ✅ 텍스트 컨트롤러
  final ScrollController _textFieldScrollController = ScrollController(); // ✅ 별도 스크롤컨트롤러

  bool get _isValid => selectedEmotions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final dayCounter = Provider.of<UserDayCounter>(context, listen: false);

    if (!dayCounter.isUserLoaded) return;
    final currentWeek = dayCounter.getWeekNumberFromJoin(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final weeklyRepo = Provider.of<WeeklyEntryRepository>(context, listen: false);
      final weeklyNow = await weeklyRepo.fetchWeeklyDiaryByWeekId(
        userId: userId,
        weekId: currentWeek.toString().padLeft(3, '0'),
      );
      if (weeklyNow != null) {
        if (!mounted) return;
        Provider.of<WeeklyEntryByCurrentWeekProvider>(context, listen: false).setEntry(weeklyNow);
      }
    });

    final previousEmotions = Provider.of<WeeklyEntryNotifier>(context, listen: false).entry?.emotions ?? [];
    selectedEmotions = [...previousEmotions];

    final previousNote = Provider.of<WeeklyEntryNotifier>(context, listen: false).entry?.weeklyNote ?? '';
    _controller.text = previousNote; // ✅ 텍스트 세팅
  }

  void _goToStep3() {
    if (!_isValid) return;

    context.read<WeeklyEntryNotifier>().updateEmotionsAndScore(
      selectedEmotions,
      0.0,
    );

    Navigator.pushNamed(context, '/weekly_diary_3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(
        title: '주간 일기 (2/3)',
        confirmOnBack: true,
        confirmOnHome: true,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(
          onBack: () => Navigator.pop(context),
          onNext: _isValid ? _goToStep3 : null,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            // 1단계 주간 일기 읽기
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 360),
              child: Scrollbar(
                controller: _textFieldScrollController,
                thumbVisibility: true,
                radius: const Radius.circular(12),
                child: SingleChildScrollView(
                  controller: _textFieldScrollController,
                  child: TextField(
                    controller: _controller,
                    readOnly: true,
                    maxLines: null,
                    expands: false,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            borderSide: const BorderSide(color: AppColors.white),
                          ),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space),

            // 질문 문구
            Container(
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '이번주는 어떤 '),
                    TextSpan(
                      text: '감정',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black,
                        decorationThickness: 1,
                      ),
                    ),
                    const TextSpan(text: '이 들었었나요?'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSizes.space),

            // 감정 선택기
            EmotionSelector(
              mode: EmotionSelectorMode.slide,
              selectedEmotions: selectedEmotions,
              onChanged: (updatedList) {
                setState(() {
                  selectedEmotions = updatedList;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFieldScrollController.dispose();
    super.dispose();
  }
}