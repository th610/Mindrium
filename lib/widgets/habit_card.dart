import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/habit_provider.dart';

/// 개별 생활 습관 카드 위젯
class HabitCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const HabitCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final isSelected = provider.isSelected(title);

    final backgroundColor = isSelected ? AppColors.indigo100 : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      child: InkWell(
        onTap: () => provider.addHabitWithIcon(title, icon),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.indigo),
              const SizedBox(width: AppSizes.space / 1.5),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.fontSize,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}