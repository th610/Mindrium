import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/data/habit_provider.dart';
import 'package:gad_app_team/data/calendar_manager.dart';

class Habit2Page extends StatefulWidget {
  const Habit2Page({super.key});

  @override
  State<Habit2Page> createState() => _Habit2PageState();
}

class _Habit2PageState extends State<Habit2Page> {
  String? _selectedHabit;
  final Map<String, int> _habitSteps = {};
  final Map<String, Map<String, TextEditingController>> _habitControllers = {};
  final Set<String> _completedHabits = {}; // ✅ 캘린더 추가 완료된 습관 기록

  final List<String> _steps = [
    'goal',
    'measure',
    'achievability',
    'relevance',
    'deadline',
  ];

  final Map<String, String> _stepLabels = {
    'goal': '목표의 내용',
    'measure': '측정 방법',
    'achievability': '실현 가능성',
    'relevance': '관련성',
    'deadline': '기한',
  };

  final Map<String, String> _stepDescriptions = {
    'goal': '이 습관을 통해 어떤 목표를 이루고 싶나요?',
    'measure': '성공 여부를 어떻게 판단할 수 있을까요?',
    'achievability': '당신이 이 목표를 실현할 수 있다고 생각하나요?',
    'relevance': '당신의 삶에 어떤 도움이 될까요?',
    'deadline': '언제까지 이 습관을 실천할 계획인가요?',
  };

  @override
  void dispose() {
    for (var fields in _habitControllers.values) {
      for (var controller in fields.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  int _getCurrentStep(String habit) => _habitSteps[habit] ?? 0;
  void _setNextStep(String habit) {
    setState(() {
      _habitSteps[habit] = (_getCurrentStep(habit) + 1).clamp(0, _steps.length - 1);
    });
  }

  TextEditingController _getController(String habit, String field) {
    _habitControllers.putIfAbsent(habit, () => {});
    _habitControllers[habit]!.putIfAbsent(field, () => TextEditingController());
    return _habitControllers[habit]![field]!;
  }

  bool _allFieldsCompleted(String habit) {
    return _steps.every((step) => _getController(habit, step).text.trim().isNotEmpty);
  }

  Future<void> _pickDate(String habit) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ko'),
    );

    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _getController(habit, 'deadline').text = formatted;
        _setNextStep(habit);
      });
    }
  }

  void _showSummaryDialog(String habit) {
    final details = _steps.map((key) =>
      '${_stepLabels[key]}: ${_getController(habit, key).text}').join('\n');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('[$habit] 계획'),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addToCalendar();
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCalendar() async {
    if (_selectedHabit == null) return;

    final habit = _selectedHabit!;
    final deadlineStr = _getController(habit, 'deadline').text;
    DateTime? date;
    try {
      date = DateTime.parse(deadlineStr);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기한 형식이 올바르지 않습니다. YYYY-MM-DD로 입력해주세요.')),
      );
      return;
    }

    final details = {
      for (var key in _steps)
        _stepLabels[key]!: _getController(habit, key).text,
    };

    context.read<CalendarManager>().addEntry(AppCalendarEntry(
      title: habit,
      description: details['목표의 내용']!,
      date: date,
      smartDetails: details,
    ));

    await context.read<HabitProvider>().saveHabitPlan(habit, details);

    setState(() {
      _completedHabits.add(habit); // ✅ 추가 완료 표시
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('[$habit]이(가) 저장되었습니다.')),
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

    final allCompleted = habitProvider.selectedHabits
        .every((habit) => _completedHabits.contains(habit));

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
            if (allCompleted) {
              Navigator.popUntil(
                context,
                (route) => route.settings.name == '/week3',
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 습관을 캘린더에 추가해야 완료할 수 있어요.')),
              );
            }
          }, // ✅ 캘린더 추가 완료 시에만 활성화
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
            Align(
              alignment: Alignment.center,
              child: Wrap(
                spacing: AppSizes.space,
                runSpacing: AppSizes.space / 2,
                children: habitProvider.selectedHabits.map((habit) {
                  final icon = defaultHabitIcons[habit] ?? habitProvider.getIconForHabit(habit);
                  final isSelected = _selectedHabit == habit;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedHabit = habit;
                      _habitSteps.putIfAbsent(habit, () => 0);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.indigo100 : AppColors.white,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 24, color: AppColors.indigo),
                          const SizedBox(width: AppSizes.space / 2),
                          Text(habit, style: const TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSizes.space),
            if (_selectedHabit != null)
              for (int i = 0; i <= _getCurrentStep(_selectedHabit!) && i < _steps.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _stepDescriptions[_steps[i]]!,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                if (_steps[i] == 'deadline')
                  GestureDetector(
                    onTap: () => _pickDate(_selectedHabit!),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _getController(_selectedHabit!, 'deadline'),
                        decoration: const InputDecoration(
                          labelText: '기한',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(AppSizes.padding),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  )
                else
                  InputTextField(
                    label: _stepLabels[_steps[i]]!,
                    controller: _getController(_selectedHabit!, _steps[i]),
                    fillColor: Colors.white,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty &&
                          i == _getCurrentStep(_selectedHabit!) &&
                          _getCurrentStep(_selectedHabit!) < _steps.length - 1) {
                        _setNextStep(_selectedHabit!);
                      }
                    },
                  ),
              ],
            const SizedBox(height: AppSizes.space),
            if (_selectedHabit != null && _allFieldsCompleted(_selectedHabit!))
              Material(
                color: AppColors.indigo50,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                child: InkWell(
                  onTap: () => _showSummaryDialog(_selectedHabit!),
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
