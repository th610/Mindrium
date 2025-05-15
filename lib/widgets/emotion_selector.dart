import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/utils/emotion_utils.dart';
import 'package:gad_app_team/widgets/emotion_picker_popup.dart';
import 'package:gad_app_team/data/emotion.dart';
import 'package:gad_app_team/widgets/emotion_chip.dart';

enum EmotionSelectorMode { popup, slide }

class EmotionSelector extends StatefulWidget {
  final EmotionSelectorMode mode;
  final List<String> selectedEmotions;
  final Function(List<String>)? onChanged;
  final bool readOnly;

  const EmotionSelector({
    super.key,
    required this.mode,
    required this.selectedEmotions,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<EmotionSelector> createState() => _EmotionSelectorState();
}

class _EmotionSelectorState extends State<EmotionSelector> {
  List<Emotion> _emotions = []; // 전체 감정 목록 (기본 + 커스텀)
  List<Emotion> _customEmotions = []; // 삭제 판단용 커스텀 감정만 분리
  Map<String, Emotion> _emotionMap = {};
  late List<String> selected; // 현재 선택된 감정들

  @override
  void initState() {
    super.initState();
    selected = [...widget.selectedEmotions];
    _loadEmotions();
  }

  Future<void> _loadEmotions() async {
    final list = await loadEmotionList();
    final custom = list
        .where((e) => !predefinedEmotions.any((p) => p.name == e.name)).toList();
    final map = {for (final e in list) e.name: e};

    setState(() {
      _emotions = list;
      _customEmotions = custom;
      _emotionMap = map;
    });
  }

  void _toggleEmotion(String name) {
    _loadEmotions();

    setState(() {
      if (selected.contains(name)) {
        selected.remove(name);
      } else if (selected.length < 3) {
        selected.add(name);
      }
    });
    widget.onChanged?.call(selected);
  }

  Future<void> _handleAddEmotion(String name, String emoji) async {
    final newEmotion = Emotion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
    );

    if (!selected.contains(name)  && !widget.readOnly) {
      await addCustomEmotion(newEmotion); // SharedPreferences 저장
      await _loadEmotions(); // 감정 목록 최신화

      // 이미 선택되어 있지 않고 3개 미만일 때만 자동 선택 및 저장
      if (selected.length < 3) {
        setState(() {
          selected.add(name);
        });
        widget.onChanged?.call(selected);
      }
    }
  }

  Future<void> _handleRemoveEmotion(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("감정을 삭제할까요?"),
        content: Text("‘$name’ 감정을 삭제하면 다시 복원할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await removeCustomEmotion(name); // SharedPreferences에서 삭제
      await _loadEmotions(); // 최신 목록 다시 불러오기

      setState(() {
        selected.remove(name);
        _customEmotions.removeWhere((e) => e.name == name);
      });

      widget.onChanged?.call(selected);
    }
  }

  void _openPopupSelector() async {
    if (widget.readOnly) return;

    final result = await showEmotionDialog(
      context,
      _emotions,
      _handleAddEmotion,
      _handleRemoveEmotion,
      _customEmotions,
      selected,
    );

    if (result != null) {
      await _loadEmotions();  // Shared 최신화
      setState(() => selected = result); // selected는 감정 이름 리스트
      widget.onChanged?.call(selected);  // 외부에 전달
    }
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
      await _handleAddEmotion(result['label']!, result['emoji']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emotions.isEmpty) return const SizedBox.shrink();

    if (widget.mode == EmotionSelectorMode.popup) {
      if (selected.isEmpty) {
        return Center(
          child: InkWell(
            onTap: widget.readOnly ? null : _openPopupSelector,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: AppColors.indigo50,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: AppColors.indigo),
                  SizedBox(width: AppSizes.space),
                  Text(
                    '탭하여 감정 선택하기',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontSize: AppSizes.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Center(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.start,
          children: [
            ...selected.map((name) {
              final emotion = _emotionMap[name] ??
                  Emotion(id: 'past', name: name, emoji: ' ', isSelected: true);
              return EmotionChip(
                emotion: emotion,
                isSelected: true,
                onTap: () => widget.readOnly? null : () {
                  _toggleEmotion(name);
                },
              );
            }),
            if (!widget.readOnly && selected.length < 3)
              EmotionChip(
                emotion: Emotion(id: 'add', name: '추가', emoji: '➕'),
                isSelected: false,
                onTap: _openPopupSelector,
              ),
            if (!widget.readOnly && selected.length >= 3)
              EmotionChip(
                emotion: Emotion(id: 'edit', name: '수정', emoji: '➖'),
                isSelected: false,
                onTap: _openPopupSelector,
              ),
          ],
        )
      );
    }

    // slide 모드
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppSizes.padding),
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              color: AppColors.white,
            ),
            child: PageView.builder(
              itemCount: (_emotions.length / 6).ceil(), // 한 페이지에 n개씩 (Wrap으로 자동 배치)
              controller: PageController(viewportFraction: 0.80),
              itemBuilder: (context, pageIndex) {
                final pageItems = _emotions
                    .skip(pageIndex * 6).take(6)
                    .toList();
                return Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    children: pageItems.map((emotion) {
                      final isSelected = selected.contains(emotion.name);
                      return EmotionChip(
                        emotion: emotion,
                        isSelected: isSelected,
                        onTap: widget.readOnly ? null : () {
                          _toggleEmotion(emotion.name);
                        },
                        onLongPress: widget.readOnly || !_customEmotions.any((e) => e.name == emotion.name)
                           ? null : () => _handleRemoveEmotion(emotion.name),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.space),
          Container(
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: [
                  ...selected.map((name) {
                    final emotion = _emotionMap[name] ??
                        Emotion(id: 'past', name: name, emoji: ' ', isSelected: true);
                    return EmotionChip(
                      emotion: emotion,
                      isSelected: true,
                      onTap: widget.readOnly ? null : () {
                        _toggleEmotion(emotion.name);
                      },
                    );
                  }),
                  if (!widget.readOnly && selected.length < 3)
                    EmotionChip(
                      emotion: Emotion(id: 'add', name: '추가', emoji: '➕'),
                      isSelected: false,
                      onTap: _showAddEmotionDialog,
                    ),
                  if (!widget.readOnly && selected.length >= 3)
                    EmotionChip(
                      emotion: Emotion(id: 'edit', name: '수정', emoji: '➖'),
                      isSelected: false,
                      onTap: _showAddEmotionDialog,
                    ),
                ],
              ),
            )
          ),
        ],
      ),
    );
  }
}



