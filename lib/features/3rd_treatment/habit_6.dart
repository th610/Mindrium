// Habit2Page with Firestore 저장 및 가독성 높은 구조
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/data/habit_provider.dart';
import 'package:gad_app_team/data/calendar_manager.dart';

class Habit6Page extends StatefulWidget {
  const Habit6Page({super.key});

  @override
  State<Habit6Page> createState() => _Habit6PageState();
}

class _Habit6PageState extends State<Habit6Page> {
  String? _selectedHabit;
  final Map<String, Map<String, TextEditingController>> _habitControllers = {};

  @override
  void dispose() {
    for (var fields in _habitControllers.values) {
      for (var controller in fields.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  TextEditingController _getController(String habit, String field) {
    _habitControllers.putIfAbsent(habit, () => {});
    _habitControllers[habit]!.putIfAbsent(field, () => TextEditingController());
    return _habitControllers[habit]![field]!;
  }

  void _addToCalendar() async {
    if (_selectedHabit == null) return;

    final title = _selectedHabit!;
    final description = _getController(title, 'goal').text;
    final deadlineStr = _getController(title, 'deadline').text;

    DateTime? date;
    try {
      date = DateTime.parse(deadlineStr);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기한 형식이 올바르지 않습니다. YYYY-MM-DD로 입력해 주세요.')),
      );
      return;
    }

    // 캘린더에 추가
    final calendarManager = context.read<CalendarManager>();
    calendarManager.addEntry(AppCalendarEntry(
      title: title,
      description: description,
      date: date,
      smartDetails: {
        '목표의 내용': _getController(title, 'goal').text,
        '측정 방법': _getController(title, 'measure').text,
        '실현 가능성': _getController(title, 'achievability').text,
        '관련성': _getController(title, 'relevance').text,
        '기한': _getController(title, 'deadline').text,
      },
    ));

    // Firestore에 저장
    final habitProvider = context.read<HabitProvider>();
    await habitProvider.saveHabitPlan(title, {
      '목표의 내용': _getController(title, 'goal').text,
      '측정 방법': _getController(title, 'measure').text,
      '실현 가능성': _getController(title, 'achievability').text,
      '관련성': _getController(title, 'relevance').text,
      '기한': _getController(title, 'deadline').text,
    });

    if (!mounted) return;
    // 사용자에게 피드백
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('[$title]이(가) 캘린더와 Firestore에 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    final defaultHabitIcons = {
      '수면': Icons.nightlight_round,
      '운동': Icons.fitness_center,
      '식습관': Icons.restaurant,
      '야외 활동': Icons.park,
      '디지털 노마드': Icons.laptop_mac,
    };

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '건강한 습관 만들기',
        confirmOnBack: true,
        confirmOnHome: true,
        onBack: () => Navigator.pop(context),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(
          rightLabel: '완료',
          onBack: () => Navigator.pop(context),
          onNext: () {
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          }
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            const ImageBanner(imageSource: ''),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSizes.space),
              child: Text(
                '선택한 생활 습관별로 계획을 작성해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 습관 선택 버튼
            Align(
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSizes.space,
                runSpacing: AppSizes.space / 2,
                children: habitProvider.selectedHabits.map((habit) {
                  final icon = defaultHabitIcons[habit] ?? habitProvider.getIconForHabit(habit);
                  final isSelected = _selectedHabit == habit;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedHabit = habit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.indigo100 : AppColors.white,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 24, color: AppColors.indigo),
                          const SizedBox(width: AppSizes.space / 2),
                          Text(
                            habit,
                            style: const TextStyle(
                              fontSize: AppSizes.fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSizes.space),

            // 선택된 습관 계획 입력 필드
            if (_selectedHabit != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
                child: Text(
                  '$_selectedHabit에 대한 구체적인 계획을 작성 해볼까요?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InputTextField(
                label: '목표의 내용', 
                controller: _getController(_selectedHabit!, 'goal'),
                fillColor: Colors.white,
              ),
              const SizedBox(height: AppSizes.space / 2),
              InputTextField(
                label: '측정 방법', 
                controller: _getController(_selectedHabit!, 'measure'),
                fillColor: Colors.white,
              ),
              const SizedBox(height: AppSizes.space / 2),
              InputTextField(
                label: '실현 가능성', 
                controller: _getController(_selectedHabit!, 'achievability'),
                fillColor: Colors.white,  
              ),
              const SizedBox(height: AppSizes.space / 2),
              InputTextField(
                label: '관련성', 
                controller: _getController(_selectedHabit!, 'relevance'),
                fillColor: Colors.white,  
              ),
              const SizedBox(height: AppSizes.space / 2),
              InputTextField(
                label: '기한', 
                controller: _getController(_selectedHabit!, 'deadline'),
                fillColor: Colors.white,
              ),
              const SizedBox(height: AppSizes.space),
            ],

            // 캘린더 버튼
            Material(
              color: AppColors.indigo50,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              child: InkWell(
                onTap: _addToCalendar,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, color: AppColors.indigo),
                      SizedBox(width: AppSizes.space),
                      Text(
                        '캘린더에 추가하기',
                        style: TextStyle(
                          color: AppColors.indigo,
                          fontSize: AppSizes.fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
