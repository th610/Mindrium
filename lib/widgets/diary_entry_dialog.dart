import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/diary_entry_model.dart';
import 'package:gad_app_team/data/emotion.dart';
import 'package:gad_app_team/utils/emotion_utils.dart';

// 일기 타일에서 보기 버튼을 누르면 일기의 내용이 팝업 창으로 뜸
class DiaryEntryDialog extends StatelessWidget {
  final DiaryEntryModel entry;

  const DiaryEntryDialog({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.padding),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${int.tryParse(entry.id).toString()}일차 걱정 일기',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.fontSize)),
            const SizedBox(height: AppSizes.space),

            // 감정 칩
            FutureBuilder<List<Emotion>>(
              future: mapNamesToEmotions(entry.emotion),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {return CircularProgressIndicator();}
                final emotions = snapshot.data!;
                return Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: emotions.map((e) {
                    return Container(
                      padding: const EdgeInsets.all(AppSizes.padding),
                      decoration: BoxDecoration(
                        color: AppColors.indigo100,
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

            // 읽기 모드 TextField
            Container(
              constraints: isKeyboardOpen ? BoxConstraints(maxHeight: 80) :
                  BoxConstraints(minHeight: 100, maxHeight: 300),
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                color: AppColors.white,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                thickness: 6,
                child: TextField(
                  controller: TextEditingController(text: entry.note),
                  readOnly: true,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(AppSizes.padding),
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.space),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
