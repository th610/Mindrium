import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/emotion.dart';

enum EmotionChipStyle {
  msLike,     // 명석님 스타일
  choiceLike, // ChoiceChip 스타일
}

class EmotionChip extends StatelessWidget {
  final Emotion emotion;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EmotionChipStyle style;

  const EmotionChip({
    super.key,
    required this.emotion,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.style = EmotionChipStyle.choiceLike,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case EmotionChipStyle.choiceLike:
        return InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          child: ChoiceChip(
            label: Text('${emotion.emoji} ${emotion.name}'),
            selected: isSelected,
            onSelected: (_) => onTap?.call(),
            selectedColor: AppColors.indigo100,
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              side: BorderSide(
                color: isSelected ? AppColors.indigo100 : AppColors.black12,
              ),
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.indigo : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        );

      case EmotionChipStyle.msLike:
        return InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4B5FD6).withAlpha((0.1*255).toInt())
                  : const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: isSelected ? const Color(0xFF4B5FD6) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emotion.emoji, style: const TextStyle(fontSize: AppSizes.fontSize)),
                const SizedBox(width: AppSizes.space),
                Text(emotion.name,
                  style: TextStyle(
                    fontSize: AppSizes.fontSize,
                    color: isSelected ? const Color(0xFF4B5FD6) : const Color(0xFF2D3142),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

