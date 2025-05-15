import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/emotion.dart';
import 'package:gad_app_team/widgets/emotion_chip.dart';

Future<List<String>?> showEmotionDialog(
    BuildContext context,
    List<Emotion> emotions,
    Future<void> Function(String name, String emoji)? onAddEmotion,
    Future<void> Function(String name)? onRemoveEmotion,
    List<Emotion>? customEmotions,
    List<String>? selectedNames,
    ) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => EmotionPickerPopup(
      emotions: emotions,
      customEmotions: customEmotions ?? [],
      onAddEmotion: onAddEmotion,
      onRemoveEmotion: onRemoveEmotion,
      initialSelected: selectedNames ?? [],
    ),
  );
}

class EmotionPickerPopup extends StatefulWidget {
  final List<Emotion> emotions;
  final List<Emotion> customEmotions;
  final Future<void> Function(String name, String emoji)? onAddEmotion;
  final Future<void> Function(String name)? onRemoveEmotion;
  final List<String>? initialSelected;

  const EmotionPickerPopup({
    super.key,
    required this.emotions,
    required this.customEmotions,
    this.onAddEmotion,
    this.onRemoveEmotion,
    this.initialSelected = const [],
  });

  @override
  State<EmotionPickerPopup> createState() => _EmotionPickerPopupState();
}

class _EmotionPickerPopupState extends State<EmotionPickerPopup> {
  late List<String> selected;

  // 팝업 내부 상태에 감정 목록 따로 유지
  late List<Emotion> emotions;
  late List<Emotion> customEmotions;

  @override
  void initState() {
    super.initState();
    selected = [...widget.initialSelected!];
    emotions = [...widget.emotions]; // 동기화
    customEmotions = [...widget.customEmotions]; // 동기화
  }

  void toggleEmotion(String name) {
    setState(() {
      if (selected.contains(name)) {
        selected.remove(name);
      } else if (selected.length < 3) {
        selected.add(name);
      }
    });
  }

  Future<void> _showAddEmotionDialog() async {
    String emoji = '😊';
    String label = '';
    bool isValid = false;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('나만의 감정 추가하기'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: const InputDecoration(
                      labelText: '감정 이름',
                      hintText: '예: 답답해요',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setStateDialog(() {
                        label = v;
                        isValid = v.trim().length <= 6;
                      });
                    }
                ),
                const SizedBox(height: AppSizes.space),
                if (!isValid && label.isNotEmpty)
                  const Text(
                    '6글자 이내로 입력해주세요',
                    style: TextStyle(color: Colors.red, fontSize: AppSizes.fontSize),
                  ),
                const SizedBox(height: AppSizes.space),
                const Text('이모지를 선택하세요'),
                const SizedBox(height: AppSizes.space),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 5,
                        children: [
                          '😊', '😢', '😨', '😩', '😴', '😠', '😌', '😕', '😖',
                          '😳', '😔', '😰', '😱', '😫', '😤', '😣', '🥺', '😵'
                        ].map((e) => InkWell(
                          onTap: () => setStateDialog(() => emoji = e),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: 150),
                            padding: const EdgeInsets.all(AppSizes.padding),
                            decoration: BoxDecoration(
                              color: emoji == e ? AppColors.indigo100 : null,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: AppSizes.fontSize)),
                          ),
                        )).toList(),
                      )
                  ),
                ),
              ]
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            FilledButton(
              onPressed: isValid
                  ? () {
                if (label.isNotEmpty) {
                  Navigator.pop(context, {'label': label, 'emoji': emoji});
                }
              } : null,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4B5FD6)),
              child: const Text('추가'),
            )
          ],
        ),
      ),
    );

    if (result != null) {
      final newEmotion = Emotion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['label']!,
        emoji: result['emoji']!,
      );

      await widget.onAddEmotion!(newEmotion.name, newEmotion.emoji);
      setState(() {
        emotions.add(newEmotion);
        customEmotions.add(newEmotion);
        if (!selected.contains(newEmotion.name) && selected.length < 3) {
          selected.add(newEmotion.name);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("감정을 선택하세요 (~3개)"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...emotions.map((emotion) {
                    final isSelected = selected.contains(emotion.name);
                    final isCustom = customEmotions.any((e) => e.name == emotion.name);
                    return EmotionChip(
                      emotion: emotion,
                      isSelected: isSelected,
                      onTap: (selected.length < 3 || isSelected)
                          ? () => toggleEmotion(emotion.name)
                          : null,
                      onLongPress: isCustom && widget.onRemoveEmotion != null
                          ? () async {
                        await widget.onRemoveEmotion!(emotion.name);
                        setState(() {
                          emotions.removeWhere((e) => e.name == emotion.name);
                          customEmotions.removeWhere((e) => e.name == emotion.name);
                          selected.remove(emotion.name);
                        });
                      } : null,
                    );
                  }),
                  // +추가 버튼을 EmotionChip처럼
                  EmotionChip(
                    emotion: Emotion(id: 'add', name: '추가', emoji: '➕'),
                    isSelected: false,
                    onTap: _showAddEmotionDialog,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selected),
          child: const Text("확인"),
        ),
      ],
    );
  }
}