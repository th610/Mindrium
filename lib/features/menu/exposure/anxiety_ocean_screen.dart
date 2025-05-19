import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/exposure_provider.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/internal_action_button.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import '../../../data/anxiety_cause.dart';
import '../../../widgets/anxiety_fish.dart';
import '../../../widgets/ocean_ui.dart';
import 'anxiety_ranking_screen.dart';

class AnxietyOceanScreen extends StatefulWidget {
  final List<AnxietyCause> anxietyCauses;
  final String photoPath;
  final List<String> selectedEmotions;
  final String entrySource;
  final bool showCompleteButton;
  final bool showAppBar;
  final bool readOnly;

  const AnxietyOceanScreen({
    super.key,
    required this.anxietyCauses,
    required this.selectedEmotions,
    required this.entrySource,
    this.photoPath = '',
    this.showCompleteButton = true,
    this.showAppBar = true,
    this.readOnly = false,
  });

  @override
  State<AnxietyOceanScreen> createState() => _AnxietyOceanScreenState();
}

class _AnxietyOceanScreenState extends State<AnxietyOceanScreen> {
  final random = math.Random();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fishPositionController = StreamController<Offset>.broadcast();
  OverlayEntry? _overlayEntry;
  double _anxietyLevel = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExposureProvider>(context, listen: false);
      provider.initialize(
        widget.anxietyCauses,
        widget.photoPath,
        widget.selectedEmotions,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fishPositionController.close();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '잘하셨어요!!',
                style: TextStyle(
                  fontSize: AppSizes.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: AppSizes.space),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  //TODO:child: Image.asset('assets/image/completion.png',fit: BoxFit.contain,),
                ),
              ),
              const SizedBox(height: AppSizes.space),
              const Text(
                '불안은 누구나\n느낄 수 있는 감정입니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.space),
              InternalActionButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                text: '이제 괜찮아요',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(AnxietyCause cause) {
    if (widget.readOnly) return;
    _titleController.text = cause.title;
    _descriptionController.text = cause.description;
    _anxietyLevel = cause.anxietyLevel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          title: const Text('불안 수정하기'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                InputTextField(controller: _titleController, label: '불안 원인'),
                const SizedBox(height: 12),
                InputTextField(
                  controller: _descriptionController,
                  label: '상세 설명',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('불안 정도: ${_anxietyLevel.toInt()}'),
                    Expanded(
                      child: Slider(
                        value: _anxietyLevel,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _anxietyLevel.toInt().toString(),
                        onChanged: (val) {
                          setState(() => _anxietyLevel = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                final updated = cause.copyWith(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  anxietyLevel: _anxietyLevel,
                );
                Provider.of<ExposureProvider>(context, listen: false)
                    .updateAnxietyCause(updated);
                Navigator.pop(context);
              },
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(AnxietyCause cause) {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('불안 삭제'),
        content: Text('"${cause.title}" 불안을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Provider.of<ExposureProvider>(context, listen: false)
                  .removeAnxietyCause(cause.id);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final provider = Provider.of<ExposureProvider>(context);
    final causes = provider.anxietyCauses;

    return Scaffold(
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: '물고기의 바다',
              confirmOnBack: true,
              confirmOnHome: true,
              onBack: () => Navigator.of(context).popUntil((route) => route.settings.name == '/exposure'),
            )
          : null,
      body: Stack(
        children: [
          const OceanBackground(),
          OceanBubbles(count: 20, screenSize: screenSize),
          CoralReef(screenSize: screenSize),
          ...causes.asMap().entries.map((entry) {
            final index = entry.key;
            final cause = entry.value;
            final initialX = random.nextDouble() * (screenSize.width - 100);
            final initialY = random.nextDouble() * (screenSize.height - 300) + 100;

            return AnxietyFish(
              key: ValueKey('${cause.id}_$index'),
              anxietyCause: cause,
              index: index,
              initialX: initialX,
              initialY: initialY,
              onDoubleTap: widget.readOnly ? null : () => _showEditDialog(cause),
              onLongPress: widget.readOnly ? null : () => _showDeleteConfirmation(cause),
            );
          }),
          if (!widget.readOnly && causes.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnxietyRankingScreen(
                        photoPath: widget.photoPath,
                        selectedEmotions: widget.selectedEmotions,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.indigo.shade50
                  ),
                  child: const Icon(Icons.add, color: AppColors.indigo),
                ),
              ),
            ),
          if (!widget.readOnly && causes.isNotEmpty)
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: NavigationButtons(
                rightLabel: '저장',
                onBack: () => Navigator.pop(context),
                onNext: () async => await provider.saveAnxietyStateToFirestore(context),
              ),
            ),
          if (causes.isEmpty)
            const Center(
              child: Text(
                '수조관이 비어있어요',
                style: TextStyle(
                  fontSize: AppSizes.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                margin: const EdgeInsets.all(AppSizes.padding),
                child: Text(
                  '나의 불안들이 이곳에서 헤엄치고 있어요',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (!widget.readOnly && causes.isEmpty && widget.showCompleteButton)
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: PrimaryActionButton(
                onPressed: () async => await provider.completeSession(context, _showCompletionDialog),
                text: '완료하기',
              ),
            ),
        ],
      ),
    );
  }
}
