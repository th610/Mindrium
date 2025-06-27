import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/weekly_entry_model.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

// 주간 일기 1단계 : 텍스트 입력
class WeeklyDiaryScreen1 extends StatefulWidget {
  const WeeklyDiaryScreen1({super.key});

  @override
  State<WeeklyDiaryScreen1> createState() => _WeeklyDiaryScreen1State();
}

class _WeeklyDiaryScreen1State extends State<WeeklyDiaryScreen1> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _textFieldScrollController = ScrollController();

  // 현재 입력의 유효성 확인 (비어 있지 않음)
  bool get _isValid => _controller.text.trim().isNotEmpty;

  // '다음' 버튼 클릭 시 2단계 이동
  void _goToStep2() {
    if (!_isValid) return;

    final userId = context.read<WeeklyEntryNotifier>().userId;
    final weekId = context.read<WeeklyEntryNotifier>().weekId;

    final entry = WeeklyEntryModel(
      id: weekId,
      userId: userId,
      weeklyNote: _controller.text.trim(),
      thoughtNote: '',
      anxietyScore: 0.0,
      emotions: [],
      date: DateTime.now(),
    );

    context.read<WeeklyEntryNotifier>().initializeEntry(entry);
    Navigator.pushNamed(context, '/weekly_diary_2');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: '주간 일기 (1/3)',
        confirmOnBack: true,
        confirmOnHome: true,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(
          onBack: null,
          onNext: _isValid ? _goToStep2 : null,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            children: [
              // 기본 앱 이미지
              ImageBanner(
                imageSource: 'assets/image/weekly_diary.png',
                height: MediaQuery.of(context).size.width * 9 / 16,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: AppSizes.space),

              // 질문 문구
              Container(
                color: const Color(0xFFF5F5F5),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '이번주는 어떤 '),
                      TextSpan(
                        text: '불안',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF4B5FD6),
                          decorationThickness: 1,
                        ),
                      ),
                      const TextSpan(text: '한 일이 있었나요?'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: AppSizes.fontSize, height: 1.3, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSizes.space),

              // 입력 필드
              SizedBox(
                width: double.infinity,
                height: 360,
                child: Scrollbar(
                  controller: _textFieldScrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(12),
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _textFieldScrollController,
                    child: TextField(
                      controller: _controller,
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
}