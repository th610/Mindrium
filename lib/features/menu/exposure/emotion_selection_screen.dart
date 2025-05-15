import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/constants.dart';
import '../../../data/emotion.dart';
import '../../../data/anxiety_cause.dart';
import '../../../data/exposure_provider.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/input_text_field.dart';
import '../../../widgets/navigation_button.dart';
import 'anxiety_ocean_screen.dart';

class EmotionSelectionScreen extends StatefulWidget {
  const EmotionSelectionScreen({super.key});

  @override
  State<EmotionSelectionScreen> createState() => _EmotionSelectionScreenState();
}

class _EmotionSelectionScreenState extends State<EmotionSelectionScreen> {
  late List<Emotion> emotions;
  AnxietyCause? _selectedAnxietyCause;
  final Map<String, List<Emotion>> _anxietyCauseEmotions = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExposureProvider>();
    final causes = provider.rawAnxietyCauses;
    emotions = List.from(predefinedEmotions);
    for (var cause in causes) {
      _anxietyCauseEmotions[cause.id] = List.from(predefinedEmotions);
    }
    _selectedAnxietyCause = causes.isNotEmpty ? causes.first : null;
  }

  void _toggleEmotion(int index) {
    setState(() {
      emotions[index] = emotions[index].copyWith(isSelected: !emotions[index].isSelected);
      if (_selectedAnxietyCause != null) {
        _anxietyCauseEmotions[_selectedAnxietyCause!.id] = emotions;
      }
    });
  }

  void _onAnxietyCauseChanged(AnxietyCause? newValue) {
    if (newValue != null && _selectedAnxietyCause != null) {
      setState(() {
        _anxietyCauseEmotions[_selectedAnxietyCause!.id] = emotions;
        _selectedAnxietyCause = newValue;
        emotions = _anxietyCauseEmotions[newValue.id]!;
      });
    }
  }

  void _showAddEmotionDialog() {
    String emoji = '😊';
    final TextEditingController labelController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('나만의 감정 추가하기', style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                label: '감정 이름',
                hintText: '예: 답답해요',
                controller: labelController,
                fillColor: Colors.transparent,
              ),
              const SizedBox(height: AppSizes.space),
              const Text('이모지를 선택하세요'),
              const SizedBox(height: AppSizes.space),
              Wrap(
                spacing: 8,
                children: [
                  '😊','😢','😨','😩','😴','😠','😌','😕','😖','😳','😔','😰','😱','😫','😤','😣','🥺','😵'
                ].map((e) => InkWell(
                  onTap: () => setDialogState(() => emoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    decoration: BoxDecoration(
                      color: emoji == e ? AppColors.indigo100 : null,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: AppSizes.fontSize)),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () async {
                final label = labelController.text.trim();
                if (label.isNotEmpty) {
                  final newEmotion = Emotion(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    emoji: emoji,
                    name: label,
                    isSelected: true,
                  );

                  setState(() {
                    emotions.add(newEmotion);
                    if (_selectedAnxietyCause != null) {
                      _anxietyCauseEmotions[_selectedAnxietyCause!.id] = emotions;
                    }
                  });

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('emotions').add({
                        'id': newEmotion.id,
                        'emoji': newEmotion.emoji,
                        'name': newEmotion.name,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                  } catch (e) {
                    debugPrint('감정 저장 중 오류 발생: $e');
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final provider = context.read<ExposureProvider>();
    final updatedCauses = provider.rawAnxietyCauses.map((cause) {
      final selected = _anxietyCauseEmotions[cause.id]
          ?.where((e) => e.isSelected)
          .map((e) => '${e.emoji} ${e.name}')
          .toList() ?? [];
      return cause.copyWith(selectedEmotions: selected);
    }).toList();

    provider.updateSelectedEmotions(
      updatedCauses.expand((c) => c.selectedEmotions ?? <String>[]).cast<String>().toList(),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var cause in updatedCauses) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('anxiety_causes')
            .doc(cause.id);
        batch.set(docRef, {
          'title': cause.title,
          'selectedEmotions': cause.selectedEmotions,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnxietyOceanScreen(
            anxietyCauses: updatedCauses,
            photoPath: provider.getPhotoForCause(updatedCauses.first.id) ?? '',
            selectedEmotions: provider.selectedEmotions,
            entrySource: 'emotion_selection',
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('데이터 저장 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPreviewImage() {
    final provider = context.read<ExposureProvider>();
    final photoPath = _selectedAnxietyCause != null
        ? provider.getPhotoForCause(_selectedAnxietyCause!.id)
        : null;

    if (photoPath != null && File(photoPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            File(photoPath),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: AppColors.black12),
        ),
        child: const Text(
          '촬영된 사진이 없습니다.',
          style: TextStyle(color: AppColors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(
        title: '감정 선택하기',
        confirmOnBack: true,
        confirmOnHome: true,
        onBack: () => Navigator.of(context).popUntil((r) => r.settings.name == '/exposure'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: NavigationButtons(
          onBack: () => Navigator.pop(context),
          onNext: _handleNext,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            _buildPreviewImage(),
            const SizedBox(height: AppSizes.space),
            _buildDropdownSection(),
            const SizedBox(height: AppSizes.space),
            _buildAddEmotionButton(),
            const SizedBox(height: AppSizes.space),
            _buildEmotionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSection() {
    final provider = context.read<ExposureProvider>();
    return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            if (provider.rawAnxietyCauses.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  color: AppColors.white,
                  border: Border.all(color: AppColors.black12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnxietyCause>(
                    value: _selectedAnxietyCause,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                    items: provider.rawAnxietyCauses.map((cause) => DropdownMenuItem(
                      value: cause,
                      child: Text(cause.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )).toList(),
                    onChanged: _onAnxietyCauseChanged,
                  ),
                ),
              ),
            const Text(' 을(를) 바라보면 어떤 생각이 드나요?', style: TextStyle(fontSize: AppSizes.fontSize, fontWeight: FontWeight.bold)),
          ],
    );
  }

  Widget _buildAddEmotionButton() {
    return Material(
      color: AppColors.indigo50,
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      child: InkWell(
        onTap: _showAddEmotionDialog,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, color: AppColors.indigo),
              SizedBox(width: AppSizes.space),
              Text(
                '나만의 감정 추가하기',
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

  Widget _buildEmotionChips() {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: emotions.asMap().entries.map((entry) {
        final index = entry.key;
        final emotion = entry.value;
        final isSelected = emotion.isSelected;

        return ChoiceChip(
          label: Text('${emotion.emoji} ${emotion.name}'),
          selected: isSelected,
          onSelected: (_) => _toggleEmotion(index),
          selectedColor: AppColors.indigo100,
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            side: BorderSide(color: isSelected ? AppColors.indigo100 : AppColors.black12),
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.indigo : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
