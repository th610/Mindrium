import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/abc_provider.dart';
import '../../common/constants.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/navigation_button.dart';
import 'smart_input_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AbcInputScreen extends StatefulWidget {
  const AbcInputScreen({super.key});

  @override
  State<AbcInputScreen> createState() => _AbcInputScreenState();
}

class _AbcInputScreenState extends State<AbcInputScreen> {
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();
  int _currentStep = 0;

  final List<String> _bodySymptoms = [
    '가슴이 답답함',
    '머리가 아픔',
    '소화가 안됨',
    '손에 땀이 참',
    '심장이 쿵쾅거림',
    '얼굴이 붉어짐',
    '잠이 오지 않음',
    '호흡이 가빠짐',
  ];
  final List<String> _selectedSymptoms = [];
  final TextEditingController _customSymptomController =
      TextEditingController();

  // Emotion and behavior lists for C-step
  final List<String> _emotions = ['불안함', '초조함'];
  final List<String> _selectedEmotions = [];
  final TextEditingController _customEmotionController =
      TextEditingController();

  // Sub-categories under 행동
  final List<String> _avoidActions = ['할 일을 미룸'];
  final List<String> _selectedAvoidActions = [];
  final TextEditingController _customAvoidController = TextEditingController();

  final List<String> _prepareActions = ['밤늦게까지 준비를 함'];
  final List<String> _selectedPrepareActions = [];
  final TextEditingController _customPrepareController =
      TextEditingController();

  final List<String> _checkActions = ['계속 확인함'];
  final List<String> _selectedCheckActions = [];
  final TextEditingController _customCheckController = TextEditingController();

  // A and B step keyword lists (with one default chip)
  final List<String> _aKeywords = ['발표'];
  final List<String> _bKeywords = ['실수할까 봐 걱정됨'];
  // Track selected keywords for A and B
  final List<String> _selectedAKeywords = [];
  final List<String> _selectedBKeywords = [];
  // Controllers for custom keyword dialogs
  final TextEditingController _customAKeywordController =
      TextEditingController();
  final TextEditingController _customBKeywordController =
      TextEditingController();

  // 리플렉션 관련 필드 추가
  bool _showReflection = false;
  int _currentReflectionPage = 0;
  final List<String> _reflectionQuestions = [
    '그 생각이 정말 사실인가요?',
    '다른 설명이 있을 수도 있나요?',
    '모든 증거가 그 생각을 지지하고 있나요?',
    '내가 지나치게 한쪽으로만 보고 있는 것은 아닐까요?',
    '친구에게 이 생각을 전한다면 뭐라고 말할 것 같나요?',
    '스스로에게 따뜻하게 이렇게 말해줄 수 있나요?',
  ];
  late final List<TextEditingController> _reflectionControllers = List.generate(
    _reflectionQuestions.length,
    (_) => TextEditingController(),
  );
  late final PageController _reflectionController = PageController();

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  /// ============ 커스텀 다이얼로그 복구 =============
  void _addCustomSymptom() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '또 다른 증상이 있다면 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customSymptomController,
                      decoration: const InputDecoration(
                        hintText: '증상 입력',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final value = _customSymptomController.text.trim();
                      if (value.isNotEmpty) {
                        setState(() {
                          _bodySymptoms.add(value);
                          _selectedSymptoms.add(value);
                        });
                        _customSymptomController.clear();
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  // ================================================

  void _addAKeyword() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '상황과 관련된 키워드를 각각 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customAKeywordController,
                      decoration: const InputDecoration(
                        hintText: '예: 회의, 발표',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customAKeywordController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() => _aKeywords.add(val));
                        _customAKeywordController.clear();
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _addBKeyword() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '키워드를 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customBKeywordController,
                      decoration: const InputDecoration(
                        hintText: '예: 실수할까봐 걱정됨',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customBKeywordController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() => _bKeywords.add(val));
                        _customBKeywordController.clear();
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _addEmotion() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '감정을 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customEmotionController,
                      decoration: const InputDecoration(
                        hintText: '예: 불안함',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customEmotionController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() {
                          _emotions.add(val);
                        });
                        _customEmotionController.clear();
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _addBehavior() {
    // (No longer used, kept for reference)
  }

  void _addAvoidAction() {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '행동을 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customAvoidController,
                      decoration: const InputDecoration(
                        hintText: '예: 할 일을 미룸',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customAvoidController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() => _avoidActions.add(val));
                        _customAvoidController.clear();
                      }
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _addPrepareAction() {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '행동을 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customPrepareController,
                      decoration: const InputDecoration(
                        hintText: '예: 미리 준비함',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customPrepareController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() => _prepareActions.add(val));
                        _customPrepareController.clear();
                      }
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _addCheckAction() {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '행동을 추가해주세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: TextField(
                      controller: _customCheckController,
                      decoration: const InputDecoration(
                        hintText: '예: 계속 확인함',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customCheckController.text.trim();
                      if (val.isNotEmpty) {
                        setState(() => _checkActions.add(val));
                        _customCheckController.clear();
                      }
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStepCircle('A', 0),
        _buildStepLine(),
        _buildStepCircle('B', 1),
        _buildStepLine(),
        _buildStepCircle('C', 2),
      ],
    );
  }

  Widget _buildStepCircle(String label, int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.indigo : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(width: 50, height: 2, color: Colors.grey[300]);
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepA();
      case 1:
        return _buildStepB();
      case 2:
        return _buildStepC();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상황 (Activating Event)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '예시: "회의에서 발표를 해야 하는 상황"',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _aController,
          maxLines: 1,
          decoration: const InputDecoration(
            hintText: '상황을 자세히 설명해주세요',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCED0D2), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCED0D2), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7B86F4), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '불안감을 느낀 상황 키워드를 각각 추가해주세요.',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._aKeywords.map(
              (kw) => ChoiceChip(
                label: Text(kw),
                selected: _selectedAKeywords.contains(kw),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAKeywords.add(kw);
                    } else {
                      _selectedAKeywords.remove(kw);
                    }
                  });
                },
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addAKeyword),
          ],
        ),
      ],
    );
  }

  Widget _buildStepB() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생각 (Belief)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '예시: "내가 실수하면 어떻게 하지?"',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bController,
          maxLines: 1,
          decoration: const InputDecoration(
            hintText: '생각을 자세히 설명해주세요',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCED0D2), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCED0D2), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7B86F4), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '그 상황에서 어떤 생각이 들었나요?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._bKeywords.map(
              (kw) => ChoiceChip(
                label: Text(kw),
                selected: _selectedBKeywords.contains(kw),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBKeywords.add(kw);
                    } else {
                      _selectedBKeywords.remove(kw);
                    }
                  });
                },
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addBKeyword),
          ],
        ),
      ],
    );
  }

  Widget _buildStepC() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '감정 및 행동 (Consequence)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '그 생각으로 인해 어떤 감정과 행동이 나타났나요?\n'
          '예시: "불안하고 초조해졌다, 회피 행동을 했다"',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        // Consequence input field
        TextField(
          controller: _cController,
          maxLines: 1,
          decoration: const InputDecoration(
            hintText: '감정과 행동을 자세히 설명해주세요',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCED0D2), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCED0D2), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7B86F4), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 신체 증상
        const Text(
          '1. 신체 증상',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._bodySymptoms.map(
              (s) => ChoiceChip(
                label: Text(s),
                selected: _selectedSymptoms.contains(s),
                onSelected: (sel) {
                  setState(() {
                    if (sel)
                      _selectedSymptoms.add(s);
                    else
                      _selectedSymptoms.remove(s);
                  });
                },
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addCustomSymptom),
          ],
        ),
        const SizedBox(height: 16),
        // 감정
        const Text(
          '2. 감정',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._emotions.map(
              (e) => ChoiceChip(
                label: Text(e),
                selected: _selectedEmotions.contains(e),
                onSelected: (sel) {
                  setState(() {
                    if (sel)
                      _selectedEmotions.add(e);
                    else
                      _selectedEmotions.remove(e);
                  });
                },
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addEmotion),
          ],
        ),
        const SizedBox(height: 16),
        // 행동 세부 항목
        const Text(
          '3. 행동',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Sub-question 1
        const Text('상황을 회피하거나 외면했나요?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._avoidActions.map(
              (act) => ChoiceChip(
                label: Text(act),
                selected: _selectedAvoidActions.contains(act),
                onSelected:
                    (sel) => setState(() {
                      if (sel)
                        _selectedAvoidActions.add(act);
                      else
                        _selectedAvoidActions.remove(act);
                    }),
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addAvoidAction),
          ],
        ),
        const SizedBox(height: 16),

        // Sub-question 2
        const Text('걱정하는 일이 생기지 않도록 어떤 노력을 했나요?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._prepareActions.map(
              (act) => ChoiceChip(
                label: Text(act),
                selected: _selectedPrepareActions.contains(act),
                onSelected:
                    (sel) => setState(() {
                      if (sel)
                        _selectedPrepareActions.add(act);
                      else
                        _selectedPrepareActions.remove(act);
                    }),
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addPrepareAction),
          ],
        ),
        const SizedBox(height: 16),

        // Sub-question 3
        const Text('문제가 없는지 계속 확인했나요?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._checkActions.map(
              (act) => ChoiceChip(
                label: Text(act),
                selected: _selectedCheckActions.contains(act),
                onSelected:
                    (sel) => setState(() {
                      if (sel)
                        _selectedCheckActions.add(act);
                      else
                        _selectedCheckActions.remove(act);
                    }),
              ),
            ),
            ActionChip(label: const Text('+'), onPressed: _addCheckAction),
          ],
        ),
      ],
    );
  }

  Future<void> _saveAbcModelToFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없어 저장할 수 없습니다.')));
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. 사용자 문서에 임시 데이터 상태 저장
      await firestore.collection('users').doc(userId).set({
        'has_temporary_data': true,
        'current_screen': 'abc_model',
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. ABC 모델 데이터 저장
      final data = {
        'activatingEvent':         _aController.text,
        'belief':                  _bController.text,
        'consequence':             _cController.text,
        'activatingKeywords':      _selectedAKeywords,
        'beliefKeywords':          _selectedBKeywords,
        'bodySymptoms':            _selectedSymptoms,
        'emotions':                _selectedEmotions,
        'avoidActions':            _selectedAvoidActions,
        'prepareActions':          _selectedPrepareActions,
        'checkActions':            _selectedCheckActions,
        'reflectionAnswers':       _reflectionControllers.map((c) => c.text).toList(),
        'createdAt':               FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(userId)
          .collection('abc_models')
          .add(data);

      print('ABC 모델 저장 성공 - 사용자 ID: $userId');

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text('저장 완료'),
                content: const Text('ABC 모델이 저장되었습니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(
                        context,
                      ).popUntil((route) => route.settings.name == '/exposure');
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('ABC 모델 저장 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(title: '2주차 - ABC 모델'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                //TODO:child: 
                  //Image.asset('assets/image/ABCmodel.png',width: double.infinity,fit: BoxFit.fitWidth,),
              ),
              _buildStepIndicator(),
              const SizedBox(height: 32),
              _buildCurrentStep(),
              const SizedBox(height: 24),
              NavigationButtons(
                onBack: _currentStep > 0 ? _previousStep : null,
                onNext:
                    _currentStep < 2
                        ? _nextStep
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AbcVisualizationScreen(
                                    activatingEvent: _aController.text,
                                    belief: _bController.text,
                                    consequence: _cController.text,
                                    bodySymptoms: _selectedSymptoms,
                                    activatingEventKeywords: _selectedAKeywords,
                                    beliefKeywords: _selectedBKeywords,
                                    emotions: _selectedEmotions,
                                    avoidActions: _selectedAvoidActions,
                                    prepareActions: _selectedPrepareActions,
                                    checkActions: _selectedCheckActions,
                                  ),
                            ),
                          );
                        },
                leftLabel: '이전',
                rightLabel: _currentStep < 2 ? '다음' : '완료',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          _showReflection
              ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: NavigationButtons(
                  leftLabel: '이전',
                  rightLabel:
                      _currentReflectionPage < _reflectionQuestions.length - 1
                          ? '다음'
                          : '완료',
                  onBack: () {
                    if (_currentReflectionPage > 0) {
                      _reflectionController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                      setState(() => _currentReflectionPage--);
                    } else {
                      setState(() => _showReflection = false);
                    }
                  },
                  onNext: () async {
                    if (_currentReflectionPage <
                        _reflectionQuestions.length - 1) {
                      _reflectionController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                      setState(() => _currentReflectionPage++);
                    } else {
                      await _saveAbcModelToFirestore();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SmartInputScreen(),
                        ),
                      );
                    }
                  },
                ),
              )
              : null,
    );
  }
}

class AbcVisualizationScreen extends StatefulWidget {
  final String activatingEvent;
  final String belief;
  final String consequence;
  final List<String> bodySymptoms;
  final List<String>? activatingEventKeywords;
  final List<String>? beliefKeywords;
  final List<String>? emotions;
  final List<String>? avoidActions;
  final List<String>? prepareActions;
  final List<String>? checkActions;

  const AbcVisualizationScreen({
    Key? key,
    required this.activatingEvent,
    required this.belief,
    required this.consequence,
    required this.bodySymptoms,
    this.activatingEventKeywords,
    this.beliefKeywords,
    this.emotions,
    this.avoidActions,
    this.prepareActions,
    this.checkActions,
  }) : super(key: key);

  @override
  _AbcVisualizationScreenState createState() => _AbcVisualizationScreenState();
}

class _AbcVisualizationScreenState extends State<AbcVisualizationScreen> {
  late final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showReflection = false;
  // Reflection PageView controller and index
  late final PageController _reflectionController = PageController();
  int _currentReflectionPage = 0;

  // Reflection questions
  final List<String> _reflectionQuestions = [
    '그 생각이 정말 사실인가요?',
    '다른 설명이 있을 수도 있나요?',
    '모든 증거가 그 생각을 지지하고 있나요?',
    '내가 지나치게 한쪽으로만 보고 있는 것은 아닐까요?',
    '친구에게 이 생각을 전한다면 뭐라고 말할 것 같나요?',
    '스스로에게 따뜻하게 이렇게 말해줄 수 있나요?',
  ];
  late final List<TextEditingController> _reflectionControllers = List.generate(
    _reflectionQuestions.length,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final c in _reflectionControllers) {
      c.dispose();
    }
    _pageController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  void _showAllDialog() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildVerticalContent()],
              ),
            ),
          ),
    );
  }

  Widget _buildVerticalContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageContent(
          icon: Icons.event_note,
          title: 'Activating Event',
          value: widget.activatingEvent,
        ),
        const SizedBox(height: 16),
        Icon(Icons.arrow_downward, size: 32, color: AppColors.indigo),
        const SizedBox(height: 16),
        _buildPageContent(
          icon: Icons.psychology_alt,
          title: 'Belief',
          value: widget.belief,
        ),
        const SizedBox(height: 16),
        Icon(Icons.arrow_downward, size: 32, color: AppColors.indigo),
        const SizedBox(height: 16),
        _buildPageContent(
          icon: Icons.emoji_emotions,
          title: 'Consequence',
          value: widget.consequence,
        ),
      ],
    );
  }

  Widget _buildPageContent({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.indigo,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _AbcValueBox(value: value),
      ],
    );
  }

  Widget _buildStepCircle(String label, int step) {
    final isActive = _currentPage == step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.indigo : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() =>
      Container(width: 24, height: 2, color: Colors.grey.shade300);

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle('A', 0),
        _buildStepLine(),
        _buildStepCircle('B', 1),
        _buildStepLine(),
        _buildStepCircle('C', 2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: CustomAppBar(title: '2주차 - ABC 모델'),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Fixed card
              SizedBox(
                height: 420,
                child: Card(
                  color: AppColors.indigo50,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container()),
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 24,
                              ),
                              onPressed: _showAllDialog,
                            ),
                          ],
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged:
                                (i) => setState(() => _currentPage = i),
                            children: [
                              // A
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPageContent(
                                    icon: Icons.event_note,
                                    title: 'Activating Event',
                                    value: widget.activatingEvent,
                                  ),
                                  const SizedBox(height: 45),
                                  Center(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: _buildSlidingChips(
                                        '상황 키워드',
                                        widget.activatingEventKeywords,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // B
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPageContent(
                                    icon: Icons.psychology_alt,
                                    title: 'Belief',
                                    value: widget.belief,
                                  ),
                                  const SizedBox(height: 45),
                                  Center(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: _buildSlidingChips(
                                        '생각 키워드',
                                        widget.beliefKeywords,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // C
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPageContent(
                                      icon: Icons.emoji_emotions,
                                      title: 'Consequence',
                                      value: widget.consequence,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSlidingChips(
                                      '신체 증상',
                                      widget.bodySymptoms,
                                    ),
                                    _buildSlidingChips('감정', widget.emotions),
                                    _buildSlidingChips(
                                      '행동 - 상황을 피하거나 외면했나요?',
                                      widget.avoidActions,
                                    ),
                                    _buildSlidingChips(
                                      '행동 - 걱정하는 일이 생기지 않도록 어떤 노력을 했나요?',
                                      widget.prepareActions,
                                    ),
                                    _buildSlidingChips(
                                      '행동 - 문제가 없는지 계속 확인했나요?',
                                      widget.checkActions,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(child: _buildStepIndicator()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 카드 아래에 중앙 정렬 문구 추가
              if (!_showReflection) ...[
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    '<Belief>에 집중해서 답해볼까요?\n이러한 생각이 사실일까요?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Reflection slider
              if (_showReflection)
                SizedBox(
                  height: 200,
                  child: PageView(
                    controller: _reflectionController,
                    onPageChanged:
                        (idx) => setState(() => _currentReflectionPage = idx),
                    children: List.generate(_reflectionQuestions.length, (i) {
                      return Stack(
                        children: [
                          // Use controller to preserve text
                          Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _reflectionQuestions[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _reflectionControllers[i],
                                    decoration: const InputDecoration(
                                      hintText: '답변을 입력해주세요',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _reflectionQuestions.length,
                                (dotIdx) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width:
                                      _currentReflectionPage == dotIdx ? 12 : 8,
                                  height:
                                      _currentReflectionPage == dotIdx ? 12 : 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _currentReflectionPage == dotIdx
                                            ? AppColors.indigo
                                            : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          leftLabel: !_showReflection ? '아니오' : '이전',
          rightLabel:
              !_showReflection
                  ? '예'
                  : (_currentReflectionPage < _reflectionQuestions.length - 1
                      ? '다음'
                      : '완료'),
          onBack: () {
            if (!_showReflection) {
              Navigator.pop(context);
            } else if (_currentReflectionPage > 0) {
              _reflectionController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
              setState(() => _currentReflectionPage--);
            } else {
              // First reflection page: exit reflection mode
              setState(() => _showReflection = false);
            }
          },
          onNext: _handleNext,
        ),
      ),
    );
  }

  void _handleNext() async {
    if (!_showReflection) {
      // Enter reflection
      setState(() => _showReflection = true);
    } else if (_currentReflectionPage < _reflectionQuestions.length - 1) {
      // Next reflection question
      _reflectionController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() => _currentReflectionPage++);
    } else {
      // Last reflection: save data and navigate to SMART
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 정보가 없어 저장할 수 없습니다.')),
          );
          return;
        }

        final firestore = FirebaseFirestore.instance;

        // 1. 사용자 문서에 임시 데이터 상태 저장
        await firestore.collection('users').doc(userId).set({
          'has_temporary_data': true,
          'current_screen': 'abc_model',
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 2. ABC 모델 데이터 저장
        final data = {
          'activatingEvent': widget.activatingEvent,
          'belief': widget.belief,
          'consequence': widget.consequence,
          'bodySymptoms': widget.bodySymptoms,
          'activatingKeywords': widget.activatingEventKeywords ?? [],
          'beliefKeywords': widget.beliefKeywords ?? [],
          'emotions': widget.emotions ?? [],
          'avoidActions': widget.avoidActions ?? [],
          'prepareActions': widget.prepareActions ?? [],
          'checkActions': widget.checkActions ?? [],
          'reflectionAnswers':
              _reflectionControllers.map((c) => c.text).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await firestore
            .collection('users')
            .doc(userId)
            .collection('abc_models')
            .add(data);

        print('ABC 모델 저장 성공 - 사용자 ID: $userId');

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SmartInputScreen()),
        );
      } catch (e) {
        print('ABC 모델 저장 실패: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    }
  }

  Widget _buildSlidingChips(String title, List<String>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder:
                (_, idx) => Chip(
                  label: Text(items[idx]),
                  backgroundColor: AppColors.indigo,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AbcCircle extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;

  const _AbcCircle({
    required this.label,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.indigo,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AbcValueBox extends StatelessWidget {
  final String value;
  const _AbcValueBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.indigo100),
      ),
      child: Text(
        value.isEmpty ? '-' : value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
