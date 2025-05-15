import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/image_banner.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/habit_card.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/data/habit_provider.dart';

class Habit1Page extends StatefulWidget {
  const Habit1Page({super.key});

  @override
  State<Habit1Page> createState() => _Habit1PageState();
}

class _Habit1PageState extends State<Habit1Page> {
  final List<String> defaultHabits = ['수면', '운동', '식습관', '야외 활동', '디지털 노마드'];
  final TextEditingController _habitController = TextEditingController();

  final Map<String, IconData> defaultHabitIcons = {
    '수면': Icons.nightlight_round,
    '운동': Icons.fitness_center,
    '식습관': Icons.restaurant,
    '야외 활동': Icons.park,
    '디지털 노마드': Icons.laptop_mac,
  };

  final List<IconData> habitIconList = [
    Icons.check_circle_outline,
    Icons.self_improvement,
    Icons.menu_book,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.park,
    Icons.directions_walk,
    Icons.directions_bike,
    Icons.local_drink,
    Icons.wb_sunny,
    Icons.nightlight_round,
    Icons.phonelink_erase,
    Icons.edit_note,
    Icons.palette,
    Icons.cleaning_services,
    Icons.music_note,
    Icons.schedule,
    Icons.favorite_border,
    Icons.accessibility_new,
    Icons.flag,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().clearSelectedHabits();
    });
  }

  void _showAddDialog() {
    int? selectedIconIndex;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 480,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '나만의 습관',
                    style: TextStyle(
                      fontSize: AppSizes.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),

                  InputTextField(
                    controller: _habitController,
                    label: '습관 이름',
                  ),
                  const SizedBox(height: AppSizes.space),

                  const Align(
                    alignment: Alignment.center,
                    child: Text('아이콘을 선택하세요'),
                  ),
                  const SizedBox(height: AppSizes.space / 2),

                  Expanded(
                    child: GridView.builder(
                      itemCount: habitIconList.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final isSelected = selectedIconIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIconIndex = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.indigo100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                habitIconList[index],
                                size: 24,
                                color: isSelected ? AppColors.indigo : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSizes.space / 2),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          final habit = _habitController.text.trim();
                          if (habit.isNotEmpty && selectedIconIndex != null) {
                            final icon = habitIconList[selectedIconIndex!];
                            context.read<HabitProvider>().addHabitWithIcon(habit, icon);
                            _habitController.clear();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    final allHabits = {
      ...defaultHabits,
      ...habitProvider.selectedHabits,
    }.toList()
      ..sort();

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
          onBack: null,
          onNext: habitProvider.selectedHabits.isNotEmpty
              ? () => Navigator.pushNamed(context, '/habit2')
              : null,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            const ImageBanner(imageSource: ''),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.padding),
              child: Text(
                '실천할 생활 습관을 선택해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space),

            Material(
              color: AppColors.indigo50,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              child: InkWell(
                onTap: _showAddDialog,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: AppColors.indigo),
                      SizedBox(width: AppSizes.space),
                      Text(
                        '탭하여 새로운 습관 추가하기',
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
            const SizedBox(height: AppSizes.space),

            Wrap(
              spacing: AppSizes.space,
              runSpacing: AppSizes.space / 2,
              children: allHabits.map((habit) {
                final icon = defaultHabitIcons[habit] ?? habitProvider.getIconForHabit(habit);
                return HabitCard(title: habit, icon: icon);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
