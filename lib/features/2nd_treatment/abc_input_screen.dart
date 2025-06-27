import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/navigation_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'abc_guide_screen.dart';
import 'abc_real_start_screen.dart';

class GridItem {
  final IconData icon;
  final String label;
  final bool isAdd;
  const GridItem({required this.icon, required this.label, this.isAdd = false});
}

class AbcInputScreen extends StatefulWidget {
  final bool isExampleMode;
  final Map<String, String>? exampleData;
  final bool showGuide;

  const AbcInputScreen({
    super.key,
    this.isExampleMode = false,
    this.exampleData,
    this.showGuide = true,
  });

  @override
  State<AbcInputScreen> createState() => _AbcInputScreenState();
}

class _AbcInputScreenState extends State<AbcInputScreen> {
  int _currentStep = 0;
  // Sub-step for C-step questions
  int _currentCSubStep = 0;

  // 현재 세션에서 추가된 칩들을 추적하는 Set들
  final Set<String> _currentSessionAChips = {};
  final Set<String> _currentSessionBChips = {};
  final Set<String> _currentSessionCPhysicalChips = {};
  final Set<String> _currentSessionCEmotionChips = {};
  final Set<String> _currentSessionCBehaviorChips = {};

  final TextEditingController _customSymptomController =
      TextEditingController();

  // Emotion and behavior lists for C-step
  final TextEditingController _customEmotionController =
      TextEditingController();

  // Controllers for custom keyword dialogs
  final TextEditingController _customAKeywordController =
      TextEditingController();
  final TextEditingController _customBKeywordController =
      TextEditingController();

  // 1. 신체증상 전용 칩
  final List<GridItem> _physicalChips = [
    GridItem(icon: Icons.bed, label: '불면'),
    GridItem(icon: Icons.favorite, label: '두근거림'),
    GridItem(icon: Icons.sick, label: '메스꺼움'),
    GridItem(icon: Icons.spa, label: '식은땀'),
    GridItem(icon: Icons.waves, label: '호흡곤란'),
    GridItem(icon: Icons.healing, label: '근육긴장'),
    GridItem(icon: Icons.thermostat, label: '열감'),
    GridItem(icon: Icons.bug_report, label: '두통'),
    GridItem(icon: Icons.sports_handball, label: '손떨림'),
    GridItem(icon: Icons.add, label: '추가', isAdd: true),
  ];
  final Set<int> _selectedPhysical = {};

  // 2. 감정 전용 칩
  final List<GridItem> _emotionChips = [
    GridItem(icon: Icons.sentiment_very_dissatisfied, label: '불안'),
    GridItem(icon: Icons.flash_on, label: '분노'),
    GridItem(icon: Icons.sentiment_dissatisfied, label: '슬픔'),
    GridItem(icon: Icons.visibility_off, label: '두려움'),
    GridItem(icon: Icons.sentiment_neutral, label: '당황스러움'),
    GridItem(icon: Icons.person_off, label: '외로움'),
    GridItem(icon: Icons.thumb_down, label: '실망'),
    GridItem(icon: Icons.emoji_people, label: '수치심'),
    GridItem(icon: Icons.sentiment_dissatisfied, label: '걱정됨'),
    GridItem(icon: Icons.add, label: '추가', isAdd: true),
  ];
  // Emotion labels for filtering C-2 chips in feedback
  final Set<int> _selectedEmotion = {};

  // 3. 행동 전용 칩
  late List<GridItem> _behaviorChips;
  final Set<int> _selectedBehavior = {};
  final TextEditingController _addCGridController = TextEditingController();

  // 1. 칩 데이터 및 선택 상태 추가
  final List<GridItem> _aGridChips = [
    GridItem(icon: Icons.work, label: '회의'),
    GridItem(icon: Icons.school, label: '수업'),
    GridItem(icon: Icons.people, label: '모임'),
    // ... (상황에 맞는 칩 추가)
    GridItem(icon: Icons.add, label: '추가', isAdd: true),
  ];
  final Set<int> _selectedAGrid = {};

  final List<GridItem> _bGridChips = [
    GridItem(icon: Icons.psychology, label: '실수할까 걱정'),
    GridItem(icon: Icons.warning, label: '비난받을까 두려움'),
    // ... (생각에 맞는 칩 추가)
    GridItem(icon: Icons.add, label: '추가', isAdd: true),
  ];
  final Set<int> _selectedBGrid = {};

  late bool _showGuide;
  // 튜토리얼 단계 상태 (0: 칩 안내, 1: 상황 입력 안내, 2: 상황 입력 후 다음 안내, 3: 생각 입력 안내, 4: 생각 입력 후 다음 안내, 5: 결과 입력 안내, 6: 결과 입력 후 다음 안내)
  int _tutorialStep = 0;
  String? _tutorialError;

  // 사용자 정의 칩 저장 함수
  Future<void> _saveCustomChip(String type, String label) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('custom_abc_chips')
          .add({
            'type': type, // 'A', 'B', 'C-physical', 'C-emotion', 'C-behavior'
            'label': label,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('칩 저장 실패: $e');
    }
  }

  // 사용자 정의 칩 불러오기 함수
  Future<void> _loadCustomChips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('custom_abc_chips')
              .orderBy('createdAt')
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'];
        final label = data['label'];

        setState(() {
          switch (type) {
            case 'A':
              if (!_aGridChips.any((chip) => chip.label == label)) {
                _aGridChips.insert(
                  _aGridChips.length - 1,
                  GridItem(icon: Icons.circle, label: label),
                );
              }
              break;
            case 'B':
              if (!_bGridChips.any((chip) => chip.label == label)) {
                _bGridChips.insert(
                  _bGridChips.length - 1,
                  GridItem(icon: Icons.circle, label: label),
                );
              }
              break;
            case 'C-physical':
              if (!_physicalChips.any((chip) => chip.label == label)) {
                _physicalChips.insert(
                  _physicalChips.length - 1,
                  GridItem(icon: Icons.circle, label: label),
                );
              }
              break;
            case 'C-emotion':
              if (!_emotionChips.any((chip) => chip.label == label)) {
                _emotionChips.insert(
                  _emotionChips.length - 1,
                  GridItem(icon: Icons.circle, label: label),
                );
              }
              break;
            case 'C-behavior':
              if (!_behaviorChips.any((chip) => chip.label == label)) {
                _behaviorChips.insert(
                  _behaviorChips.length - 1,
                  GridItem(icon: Icons.circle, label: label),
                );
              }
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('칩 불러오기 실패: $e');
    }
  }

  // 현재 세션에서 추가된 칩인지 확인하는 함수
  bool _isCurrentSessionChip(String type, String label) {
    switch (type) {
      case 'A':
        return _currentSessionAChips.contains(label);
      case 'B':
        return _currentSessionBChips.contains(label);
      case 'C-physical':
        return _currentSessionCPhysicalChips.contains(label);
      case 'C-emotion':
        return _currentSessionCEmotionChips.contains(label);
      case 'C-behavior':
        return _currentSessionCBehaviorChips.contains(label);
      default:
        return false;
    }
  }

  // 현재 세션에서 추가된 칩을 추적하는 함수
  void _addToCurrentSession(String type, String label) {
    switch (type) {
      case 'A':
        _currentSessionAChips.add(label);
        break;
      case 'B':
        _currentSessionBChips.add(label);
        break;
      case 'C-physical':
        _currentSessionCPhysicalChips.add(label);
        break;
      case 'C-emotion':
        _currentSessionCEmotionChips.add(label);
        break;
      case 'C-behavior':
        _currentSessionCBehaviorChips.add(label);
        break;
    }
  }

  // 현재 세션에서 추가된 칩을 제거하는 함수
  void _removeFromCurrentSession(String type, String label) {
    switch (type) {
      case 'A':
        _currentSessionAChips.remove(label);
        break;
      case 'B':
        _currentSessionBChips.remove(label);
        break;
      case 'C-physical':
        _currentSessionCPhysicalChips.remove(label);
        break;
      case 'C-emotion':
        _currentSessionCEmotionChips.remove(label);
        break;
      case 'C-behavior':
        _currentSessionCBehaviorChips.remove(label);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _showGuide = widget.showGuide;

    // 기본 칩 세팅
    _behaviorChips = [
      GridItem(icon: Icons.event_busy, label: '결석'),
      GridItem(icon: Icons.event_note, label: '약속 안 잡기'),
      GridItem(icon: Icons.phone_disabled, label: '전화 안 받기'),
      GridItem(icon: Icons.mark_email_unread, label: '문자 안 읽기'),
      GridItem(icon: Icons.event_seat, label: '뒷자리나 구석에 앉기'),
      GridItem(icon: Icons.question_mark, label: '질문 피하기'),
      GridItem(icon: Icons.phone_android, label: '휴대폰 만지기'),
      GridItem(icon: Icons.visibility_off, label: '시선 피하기'),
      GridItem(icon: Icons.bed, label: '잠 자기'),
      GridItem(icon: Icons.sports_esports, label: '게임'),
      // 튜토리얼 칩 추가
      if (widget.isExampleMode)
        GridItem(icon: Icons.circle, label: '자전거를 타지 않았어요'),
      GridItem(icon: Icons.add, label: '추가', isAdd: true),
    ];

    // 사용자 정의 칩 불러오기
    if (!widget.isExampleMode) {
      _loadCustomChips();
    }

    if (widget.isExampleMode) {
      // 튜토리얼 모드일 때 '자전거를 타려고 함' 칩을 미리 추가
      if (!_aGridChips.any((chip) => chip.label == '자전거를 타려고 함')) {
        _aGridChips.insert(
          _aGridChips.length - 1,
          GridItem(icon: Icons.circle, label: '자전거를 타려고 함'),
        );
      }
      // 튜토리얼 모드일 때 '넘어질까봐 두려움' 칩을 미리 추가
      if (!_bGridChips.any((chip) => chip.label == '넘어질까봐 두려움')) {
        _bGridChips.insert(
          _bGridChips.length - 1,
          GridItem(icon: Icons.circle, label: '넘어질까봐 두려움'),
        );
      }
      // 튜토리얼 모드일 때 '자전거를 타지 않았어요' 칩을 미리 추가
      if (!_behaviorChips.any((chip) => chip.label == '자전거를 타지 않았어요')) {
        _behaviorChips.insert(
          _behaviorChips.length - 1,
          GridItem(icon: Icons.circle, label: '자전거를 타지 않았어요'),
        );
      }
      _tutorialStep = 0;
      _tutorialError = null;
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        if (_currentStep == 2) _currentCSubStep = 0;
        // 튜토리얼 단계 전환
        if (widget.isExampleMode) {
          if (_tutorialStep == 1) {
            _tutorialStep = 2; // 선택 후 다음 안내
          } else if (_tutorialStep == 2) {
            _tutorialStep = 3; // 상황→생각 안내
          } else if (_tutorialStep == 4) {
            _tutorialStep = 5; // 생각→결과 안내
          }
          // B단계로 넘어오면 튜토리얼 메시지가 바로 보이도록
          if (_currentStep == 1) {
            _tutorialStep = 3;
          }
        }
      });
    } else {
      if (_currentCSubStep < 2) {
        setState(() {
          _currentCSubStep++;
          // 튜토리얼 단계 전환
          if (widget.isExampleMode && _tutorialStep == 6) {
            _tutorialStep = 7; // 결과 입력 후 완료 안내(필요시)
          }
        });
      } else {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AbcVisualizationScreen(
                  selectedPhysicalChips:
                      _selectedPhysical
                          .map((i) => _physicalChips[i].label)
                          .toList(),
                  selectedEmotionChips:
                      _selectedEmotion
                          .map((i) => _emotionChips[i].label)
                          .toList(),
                  selectedBehaviorChips:
                      _selectedBehavior
                          .map((i) => _behaviorChips[i].label)
                          .toList(),
                  activatingEventChips:
                      _selectedAGrid.map((i) => _aGridChips[i]).toList(),
                  beliefChips:
                      _selectedBGrid.map((i) => _bGridChips[i]).toList(),
                  resultChips: [
                    ..._selectedPhysical.map((i) => _physicalChips[i]),
                    ..._selectedEmotion.map((i) => _emotionChips[i]),
                    ..._selectedBehavior.map((i) => _behaviorChips[i]),
                  ],
                  feedbackEmotionChips:
                      _selectedEmotion.map((i) => _emotionChips[i]).toList(),
                  isExampleMode: widget.isExampleMode,
                ),
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _currentCSubStep = 0;
      });
    }
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
                  const Text(
                    '어떤 신체 증상이 나타났나요?',
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
                        hintText: '신체 증상 입력',
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
                        // 중복 체크
                        if (_isDuplicateChip('C-physical', value)) {
                          _showDuplicateAlert(context);
                          return;
                        }
                        setState(() {
                          _physicalChips.insert(
                            _physicalChips.length - 1,
                            GridItem(icon: Icons.circle, label: value),
                          );
                          // 현재 세션에 추가된 칩으로 추적
                          _addToCurrentSession('C-physical', value);
                        });
                        _customSymptomController.clear();
                        Navigator.pop(context);
                      }
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
                    '불안감을 느꼈을 때 어떤 상황이었나요?',
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
                        hintText: '예: 자전거를 타려고 함',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_tutorialError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _tutorialError!,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customAKeywordController.text.trim();
                      if (widget.isExampleMode && _tutorialStep == 1) {
                        if (val == '자전거를 타려고 함') {
                          setState(() {
                            _aGridChips.insert(
                              _aGridChips.length - 1,
                              GridItem(icon: Icons.circle, label: val),
                            );
                            _tutorialStep = 2;
                            _tutorialError = null;
                          });
                          _customAKeywordController.clear();
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _tutorialError = '예시와 똑같이 입력해보세요!';
                          });
                        }
                        return;
                      }
                      if (val.isNotEmpty) {
                        // 중복 체크
                        if (_isDuplicateChip('A', val)) {
                          _showDuplicateAlert(context);
                          return;
                        }
                        setState(() {
                          _aGridChips.insert(
                            _aGridChips.length - 1,
                            GridItem(icon: Icons.circle, label: val),
                          );
                          // 현재 세션에 추가된 칩으로 추적
                          _addToCurrentSession('A', val);
                        });
                        _customAKeywordController.clear();
                        Navigator.pop(context);
                      }
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
                    '그 상황에서 어떤 생각이 들었나요?',
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
                        hintText: '예: 넘어질까봐 두려움',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_tutorialError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _tutorialError!,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _customBKeywordController.text.trim();
                      if (widget.isExampleMode && _tutorialStep == 3) {
                        if (val == '넘어질까봐 두려움') {
                          setState(() {
                            _bGridChips.insert(
                              _bGridChips.length - 1,
                              GridItem(icon: Icons.circle, label: val),
                            );
                            _tutorialStep = 4;
                            _tutorialError = null;
                          });
                          _customBKeywordController.clear();
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _tutorialError = '예시와 똑같이 입력해보세요!';
                          });
                        }
                        return;
                      }
                      if (val.isNotEmpty) {
                        // 중복 체크
                        if (_isDuplicateChip('B', val)) {
                          _showDuplicateAlert(context);
                          return;
                        }
                        setState(() {
                          _bGridChips.insert(
                            _bGridChips.length - 1,
                            GridItem(icon: Icons.circle, label: val),
                          );
                          // 현재 세션에 추가된 칩으로 추적
                          _addToCurrentSession('B', val);
                        });
                        _customBKeywordController.clear();
                        Navigator.pop(context);
                      }
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
                    '어떤 감정이 들었나요?',
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
                        hintText: '감정 입력',
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
                        // 중복 체크
                        if (_isDuplicateChip('C-emotion', val)) {
                          _showDuplicateAlert(context);
                          return;
                        }
                        setState(() {
                          _emotionChips.insert(
                            _emotionChips.length - 1,
                            GridItem(icon: Icons.circle, label: val),
                          );
                          // 현재 세션에 추가된 칩으로 추적
                          _addToCurrentSession('C-emotion', val);
                        });
                        _customEmotionController.clear();
                        Navigator.pop(context);
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isExampleMode ? '예시 연습하기' : '2주차 - ABC 모델',
      ),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(1.2)),
        child: SafeArea(
          child: _showGuide ? const AbcGuideScreen() : _buildMainContent(),
        ),
      ),
      // floatingActionButton removed as requested
      bottomNavigationBar:
          _showGuide
              ? null
              : Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: NavigationButtons(
                  leftLabel: '이전',
                  rightLabel:
                      _currentStep < 2
                          ? '다음'
                          : (_currentCSubStep < 2 ? '다음' : '확인'),
                  onBack: () {
                    if (_currentStep == 0) {
                      Navigator.pop(context);
                    } else if (_currentStep == 2 && _currentCSubStep > 0) {
                      setState(() => _currentCSubStep--);
                    } else {
                      _previousStep();
                    }
                  },
                  onNext: () async {
                    if (_currentStep < 2) {
                      _nextStep();
                    } else {
                      if (_currentCSubStep < 2) {
                        setState(() => _currentCSubStep++);
                      } else {
                        if (widget.isExampleMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AbcRealStartScreen(),
                            ),
                          );
                        } else {
                          if (!widget.isExampleMode) {
                            await _saveSelectedChipsToFirestore();
                          }
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AbcVisualizationScreen(
                                    selectedPhysicalChips:
                                        _selectedPhysical
                                            .map((i) => _physicalChips[i].label)
                                            .toList(),
                                    selectedEmotionChips:
                                        _selectedEmotion
                                            .map((i) => _emotionChips[i].label)
                                            .toList(),
                                    selectedBehaviorChips:
                                        _selectedBehavior
                                            .map((i) => _behaviorChips[i].label)
                                            .toList(),
                                    activatingEventChips:
                                        _selectedAGrid
                                            .map((i) => _aGridChips[i])
                                            .toList(),
                                    beliefChips:
                                        _selectedBGrid
                                            .map((i) => _bGridChips[i])
                                            .toList(),
                                    resultChips: [
                                      ..._selectedPhysical.map(
                                        (i) => _physicalChips[i],
                                      ),
                                      ..._selectedEmotion.map(
                                        (i) => _emotionChips[i],
                                      ),
                                      ..._selectedBehavior.map(
                                        (i) => _behaviorChips[i],
                                      ),
                                    ],
                                    feedbackEmotionChips:
                                        _selectedEmotion
                                            .map((i) => _emotionChips[i])
                                            .toList(),
                                    isExampleMode: widget.isExampleMode,
                                  ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. A-B-C 인디케이터 (가로선 포함)
          _buildAbcStepIndicator(),
          const SizedBox(height: 24),
          // 3. 단계별 질문/입력 UI
          _buildStepContent(),
        ],
      ),
    );
  }

  // 인디케이터(가로선 포함)
  Widget _buildAbcStepIndicator() {
    List<String> labels = ['A', 'B', 'C'];
    List<String> titles = ['상황', '생각', '결과'];
    List<String> descriptions = [
      '반응을 유발하는 사건이나 상황',
      '사건에 대한 해석이나 생각',
      '결과로 나타나는 감정이나 행동',
    ];
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: const Color.fromARGB(255, 242, 243, 254),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (i) {
            if (i % 2 == 1) {
              // Horizontal line between steps - always active color
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(height: 2, color: AppColors.indigo),
                ),
              );
            } else {
              int idx = i ~/ 2;
              final isActive = _currentStep == idx;
              return Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      width: isActive ? 64 : 48,
                      height: isActive ? 64 : 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isActive ? AppColors.indigo : Colors.grey.shade300,
                        boxShadow:
                            isActive
                                ? [
                                  BoxShadow(
                                    color: AppColors.indigo.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                                : [],
                      ),
                      child: Center(
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: isActive ? 22 : 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titles[idx],
                      style: TextStyle(
                        color: isActive ? AppColors.indigo : Colors.grey[600],
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descriptions[idx],
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  // 단계별 질문/입력 UI
  Widget _buildStepContent() {
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

  // 튜토리얼 안내 인라인 메시지 위젯
  Widget _buildTutorialInlineMessage() {
    String text = '';
    switch (_tutorialStep) {
      case 0:
        text = "위에 '자전거를 타려고 함' 칩을 눌러 선택해보세요!";
        break;
      case 1:
        text = "선택한 뒤 아래의 '다음' 버튼을 눌러주세요!";
        break;
      case 2:
        text = "입력한 내용을 선택하고\n'다음' 버튼을 눌러주세요!";
        break;
      case 3:
        text = "위에 '넘어질까봐 두려움' 칩을 눌러 선택해보세요!";
        break;
      case 4:
        text = "선택한 뒤 아래의 '다음' 버튼을 눌러주세요!";
        break;
      case 5:
        text = "위에 '자전거를 타지 않았어요' 칩을 눌러 선택해보세요!";
        break;
      case 6:
        text = "선택한 뒤 '확인' 버튼을 눌러주세요!";
        break;
      default:
        return SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStepA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '불안감을 느꼈을 때 어떤 상황이었나요?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_aGridChips.length, (i) {
            if (i == _aGridChips.length - 1) {
              // Add chip
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.indigo,
                    ),
                    label: const Text(
                      '추가',
                      style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
                    ),
                    backgroundColor: AppColors.indigo50,
                    side: BorderSide(color: AppColors.indigo, width: 1.2),
                    onPressed: widget.isExampleMode ? null : _addAKeyword,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                ],
              );
            } else {
              final item = _aGridChips[i];
              final isSelected = _selectedAGrid.contains(i);
              final isCurrentSessionChip = _isCurrentSessionChip(
                'A',
                item.label,
              );
              return FilterChip(
                avatar: Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                ),
                label: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                    fontSize: 13.5,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    isSelected
                        ? _selectedAGrid.remove(i)
                        : _selectedAGrid.add(i);
                    // 튜토리얼 모드에서 '자전거를 타려고 함' 칩을 선택하면 튜토리얼 단계 진행
                    if (widget.isExampleMode && item.label == '자전거를 타려고 함') {
                      _tutorialStep = 1;
                    }
                  });
                },
                showCheckmark: false,
                selectedColor: AppColors.indigo50,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                  width: 1.2,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                onDeleted:
                    isCurrentSessionChip
                        ? () => _deleteCustomChip('A', item.label, i)
                        : null,
                deleteIcon:
                    isCurrentSessionChip
                        ? const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.redAccent,
                        )
                        : null,
              );
            }
          }),
        ),
        // 아래에 여백 추가
        if (widget.isExampleMode && (_tutorialStep >= 0 && _tutorialStep <= 1))
          SizedBox(height: 120), // 원하는 만큼 조절
        if (widget.isExampleMode && (_tutorialStep >= 0 && _tutorialStep <= 1))
          _buildTutorialInlineMessage(),
      ],
    );
  }

  Widget _buildStepB() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '그 상황에서 어떤 생각이 들었나요?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_bGridChips.length, (i) {
            if (i == _bGridChips.length - 1) {
              return ActionChip(
                avatar: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.indigo,
                ),
                label: const Text(
                  '추가',
                  style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
                ),
                backgroundColor: AppColors.indigo50,
                side: BorderSide(color: AppColors.indigo, width: 1.2),
                onPressed: widget.isExampleMode ? null : _addBKeyword,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              );
            } else {
              final item = _bGridChips[i];
              final isSelected = _selectedBGrid.contains(i);
              final isCurrentSessionChip = _isCurrentSessionChip(
                'B',
                item.label,
              );
              return FilterChip(
                avatar: Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                ),
                label: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                    fontSize: 13.5,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    isSelected
                        ? _selectedBGrid.remove(i)
                        : _selectedBGrid.add(i);
                    if (widget.isExampleMode && item.label == '넘어질까봐 두려움') {
                      _tutorialStep = 4;
                    }
                  });
                },
                showCheckmark: false,
                selectedColor: AppColors.indigo50,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                  width: 1.2,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                onDeleted:
                    isCurrentSessionChip
                        ? () => _deleteCustomChip('B', item.label, i)
                        : null,
                deleteIcon:
                    isCurrentSessionChip
                        ? const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.redAccent,
                        )
                        : null,
              );
            }
          }),
        ),
        if (widget.isExampleMode && (_tutorialStep >= 3 && _tutorialStep <= 4))
          SizedBox(height: 120),
        if (widget.isExampleMode && (_tutorialStep >= 3 && _tutorialStep <= 4))
          _buildTutorialInlineMessage(),
      ],
    );
  }

  Widget _buildStepC() {
    switch (_currentCSubStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'C-1. 어떤 신체증상이 나타났나요?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (widget.isExampleMode)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: const Text(
                  '현재 C단계는 신체증상, 감정, 행동을 각각 입력하는 단계입니다.\n각 항목을 차례로 진행해 주세요!',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            _buildCPhysicalChips(),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'C-2. 어떤 감정이 들었나요?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildCEmotionChips(),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'C-3. 어떤 행동을 했나요?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildCBehaviorChips(),
            if (widget.isExampleMode &&
                (_tutorialStep >= 5 && _tutorialStep <= 6))
              SizedBox(height: 20),
            if (widget.isExampleMode &&
                (_tutorialStep >= 5 && _tutorialStep <= 6))
              _buildTutorialInlineMessage(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCPhysicalChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_physicalChips.length, (i) {
        if (i == _physicalChips.length - 1) {
          return ActionChip(
            avatar: const Icon(Icons.add, size: 18, color: AppColors.indigo),
            label: const Text(
              '추가',
              style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
            ),
            backgroundColor: AppColors.indigo50,
            side: BorderSide(color: AppColors.indigo, width: 1.2),
            onPressed: _addCustomSymptom,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          );
        } else {
          final item = _physicalChips[i];
          final isSelected = _selectedPhysical.contains(i);
          final isCurrentSessionChip = _isCurrentSessionChip(
            'C-physical',
            item.label,
          );
          return FilterChip(
            avatar: Icon(
              item.icon,
              size: 18,
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
            ),
            label: Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                fontSize: 13.5,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                isSelected
                    ? _selectedPhysical.remove(i)
                    : _selectedPhysical.add(i);
              });
            },
            showCheckmark: false,
            selectedColor: AppColors.indigo50,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
              width: 1.2,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            onDeleted:
                isCurrentSessionChip
                    ? () => _deleteCustomChip('C-physical', item.label, i)
                    : null,
            deleteIcon:
                isCurrentSessionChip
                    ? const Icon(Icons.close, size: 18, color: Colors.redAccent)
                    : null,
          );
        }
      }),
    );
  }

  Widget _buildCEmotionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_emotionChips.length, (i) {
        if (i == _emotionChips.length - 1) {
          return ActionChip(
            avatar: const Icon(Icons.add, size: 18, color: AppColors.indigo),
            label: const Text(
              '추가',
              style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
            ),
            backgroundColor: AppColors.indigo50,
            side: BorderSide(color: AppColors.indigo, width: 1.2),
            onPressed: _addEmotion,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          );
        } else {
          final item = _emotionChips[i];
          final isSelected = _selectedEmotion.contains(i);
          final isCurrentSessionChip = _isCurrentSessionChip(
            'C-emotion',
            item.label,
          );
          return FilterChip(
            avatar: Icon(
              item.icon,
              size: 18,
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
            ),
            label: Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                fontSize: 13.5,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                isSelected
                    ? _selectedEmotion.remove(i)
                    : _selectedEmotion.add(i);
              });
            },
            showCheckmark: false,
            selectedColor: AppColors.indigo50,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
              width: 1.2,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            onDeleted:
                isCurrentSessionChip
                    ? () => _deleteCustomChip('C-emotion', item.label, i)
                    : null,
            deleteIcon:
                isCurrentSessionChip
                    ? const Icon(Icons.close, size: 18, color: Colors.redAccent)
                    : null,
          );
        }
      }),
    );
  }

  Widget _buildCBehaviorChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_behaviorChips.length, (i) {
        if (i == _behaviorChips.length - 1) {
          return ActionChip(
            avatar: const Icon(Icons.add, size: 18, color: AppColors.indigo),
            label: const Text(
              '추가',
              style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
            ),
            backgroundColor: AppColors.indigo50,
            side: BorderSide(color: AppColors.indigo, width: 1.2),
            onPressed: widget.isExampleMode ? null : _showAddCGridDialog,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          );
        } else {
          final item = _behaviorChips[i];
          final isSelected = _selectedBehavior.contains(i);
          final isCurrentSessionChip = _isCurrentSessionChip(
            'C-behavior',
            item.label,
          );
          return FilterChip(
            avatar: Icon(
              item.icon,
              size: 18,
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
            ),
            label: Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                fontSize: 13.5,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                isSelected
                    ? _selectedBehavior.remove(i)
                    : _selectedBehavior.add(i);
                if (widget.isExampleMode && item.label == '자전거를 타지 않았어요') {
                  _tutorialStep = 6;
                }
              });
            },
            showCheckmark: false,
            selectedColor: AppColors.indigo50,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
              width: 1.2,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            onDeleted:
                isCurrentSessionChip
                    ? () => _deleteCustomChip('C-behavior', item.label, i)
                    : null,
            deleteIcon:
                isCurrentSessionChip
                    ? const Icon(Icons.close, size: 18, color: Colors.redAccent)
                    : null,
          );
        }
      }),
    );
  }

  void _showAddCGridDialog() {
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
                  const Text(
                    '어떤 행동을 했나요?',
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
                      controller: _addCGridController,
                      decoration: const InputDecoration(
                        hintText: '행동 입력',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      autofocus: true,
                    ),
                  ),
                  if (_tutorialError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _tutorialError!,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final value = _addCGridController.text.trim();
                      if (widget.isExampleMode && _tutorialStep == 5) {
                        if (value == '자전거를 타지 않았어요') {
                          setState(() {
                            _behaviorChips.insert(
                              _behaviorChips.length - 1,
                              GridItem(icon: Icons.circle, label: value),
                            );
                            _tutorialStep = 6;
                            _tutorialError = null;
                          });
                          _addCGridController.clear();
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _tutorialError = '예시와 똑같이 입력해보세요!';
                          });
                        }
                        return;
                      }
                      if (value.isNotEmpty) {
                        // 중복 체크
                        if (_isDuplicateChip('C-behavior', value)) {
                          _showDuplicateAlert(context);
                          return;
                        }
                        setState(() {
                          _behaviorChips.insert(
                            _behaviorChips.length - 1,
                            GridItem(icon: Icons.circle, label: value),
                          );
                          // 현재 세션에 추가된 칩으로 추적
                          _addToCurrentSession('C-behavior', value);
                        });
                        _addCGridController.clear();
                        Navigator.pop(context);
                      }
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

  // 중복 체크 함수 추가
  bool _isDuplicateChip(String type, String label) {
    switch (type) {
      case 'A':
        return _aGridChips.any((chip) => chip.label == label);
      case 'B':
        return _bGridChips.any((chip) => chip.label == label);
      case 'C-physical':
        return _physicalChips.any((chip) => chip.label == label);
      case 'C-emotion':
        return _emotionChips.any((chip) => chip.label == label);
      case 'C-behavior':
        return _behaviorChips.any((chip) => chip.label == label);
      default:
        return false;
    }
  }

  // 중복 알림 다이얼로그 표시
  void _showDuplicateAlert(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('중복된 항목'),
            content: const Text('이미 동일한 내용이 존재합니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // 3. Firestore에 선택된 칩만 저장 (중복 방지)
  Future<void> _saveSelectedChipsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('custom_abc_chips')
            .get();
    final existing =
        snapshot.docs
            .map((doc) => {'type': doc['type'], 'label': doc['label']})
            .toSet();

    // A칩
    for (final i in _selectedAGrid) {
      final label = _aGridChips[i].label;
      if (!existing.contains({'type': 'A', 'label': label})) {
        await _saveCustomChip('A', label);
      }
    }
    // B칩
    for (final i in _selectedBGrid) {
      final label = _bGridChips[i].label;
      if (!existing.contains({'type': 'B', 'label': label})) {
        await _saveCustomChip('B', label);
      }
    }
    // C-physical
    for (final i in _selectedPhysical) {
      final label = _physicalChips[i].label;
      if (!existing.contains({'type': 'C-physical', 'label': label})) {
        await _saveCustomChip('C-physical', label);
      }
    }
    // C-emotion
    for (final i in _selectedEmotion) {
      final label = _emotionChips[i].label;
      if (!existing.contains({'type': 'C-emotion', 'label': label})) {
        await _saveCustomChip('C-emotion', label);
      }
    }
    // C-behavior
    for (final i in _selectedBehavior) {
      final label = _behaviorChips[i].label;
      if (!existing.contains({'type': 'C-behavior', 'label': label})) {
        await _saveCustomChip('C-behavior', label);
      }
    }
  }

  // Firestore에서 커스텀 칩 삭제 함수
  Future<void> _deleteCustomChip(String type, String label, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 현재 세션에서 추가된 칩인 경우에만 Firestore에서 삭제
    if (_isCurrentSessionChip(type, label)) {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('custom_abc_chips')
              .where('type', isEqualTo: type)
              .where('label', isEqualTo: label)
              .get();
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    }

    setState(() {
      switch (type) {
        case 'A':
          _aGridChips.removeAt(index);
          break;
        case 'B':
          _bGridChips.removeAt(index);
          break;
        case 'C-physical':
          _physicalChips.removeAt(index);
          break;
        case 'C-emotion':
          _emotionChips.removeAt(index);
          break;
        case 'C-behavior':
          _behaviorChips.removeAt(index);
          break;
      }
      // 현재 세션 추적에서도 제거
      _removeFromCurrentSession(type, label);
    });
  }
}

class AbcVisualizationScreen extends StatefulWidget {
  final List<GridItem> activatingEventChips;
  final List<GridItem> beliefChips;
  final List<GridItem> resultChips;
  final List<GridItem> feedbackEmotionChips;
  final bool isExampleMode;
  final List<String> selectedPhysicalChips;
  final List<String> selectedEmotionChips;
  final List<String> selectedBehaviorChips;

  const AbcVisualizationScreen({
    super.key,
    required this.activatingEventChips,
    required this.beliefChips,
    required this.resultChips,
    required this.feedbackEmotionChips,
    required this.isExampleMode,
    required this.selectedPhysicalChips,
    required this.selectedEmotionChips,
    required this.selectedBehaviorChips,
  });

  @override
  AbcVisualizationScreenState createState() => AbcVisualizationScreenState();
}

class AbcVisualizationScreenState extends State<AbcVisualizationScreen> {
  bool _showFeedback = true;

  Widget _buildVerticalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          icon: Icons.event_note,
          title: '상황',
          chips: widget.activatingEventChips,
          backgroundColor: const Color.fromARGB(
            255,
            220,
            231,
            254,
          ), // 상황: 연한 파랑
        ),
        Center(
          child: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.indigo,
            size: 40,
          ),
        ),
        _buildSectionCard(
          icon: Icons.psychology_alt,
          title: '생각',
          chips: widget.beliefChips,
          backgroundColor: const Color(0xFFB1C9EF), // 생각: 중간 파랑
        ),
        Center(
          child: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.indigo,
            size: 40,
          ),
        ),
        _buildSectionCard(
          icon: Icons.emoji_emotions,
          title: '결과',
          chips: widget.resultChips,
          backgroundColor: const Color(0xFF95B1EE), // 결과: 진한 파랑
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<GridItem> chips,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF081F5C).withValues(alpha: 0.22),
            offset: Offset(4, 12), // 우측하단 그림자
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              decoration: BoxDecoration(
                color: AppColors.indigo,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
            // 타이틀 + 칩
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black, // 검정색으로 변경
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        chips.map((item) {
                          return Chip(
                            avatar: Icon(
                              item.icon,
                              size: 15,
                              color: AppColors.indigo,
                            ),
                            label: Text(
                              item.label,
                              style: TextStyle(
                                color: AppColors.indigo,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: const Color(0xFFF6F8FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: const Color(0xFFCED4DA),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    final situation = widget.activatingEventChips
        .map((e) => e.label)
        .join(', ');
    final thought = widget.beliefChips.map((e) => e.label).join(', ');
    // Emotion labels come from feedbackEmotionChips
    final emotionList =
        widget.feedbackEmotionChips.map((e) => e.label).toList();
    // Physical symptoms as before
    final physicalList = widget.selectedPhysicalChips;
    // Behaviors are any labels not in physical or emotion lists
    final behaviorList = widget.selectedBehaviorChips;
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    return Card(
      color: Colors.white, // ← 이 부분 추가
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "$userName님, 말씀해주셔서 감사합니다. 👏\n글로 한번 정리해볼까요?",
                style: const TextStyle(
                  fontSize: 16.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "'$situation' 상황에서\n"
                "'$thought' 생각을 하였습니다.\n\n"
                "'${emotionList.join("', '")}' 감정을 느끼셨습니다.\n\n"
                "그 결과 신체적으로 '${physicalList.join("', '")}' 증상이 나타났고,\n"
                "'${behaviorList.join("', '")}' 행동을 하였습니다.\n",
                style: const TextStyle(
                  fontSize: 16.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "위의 내용을 그림으로 그려볼까요?",
              style: const TextStyle(
                fontSize: 16.5,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "당신을 응원해요!",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Text("❤️", style: TextStyle(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '2주차 - ABC 모델'),
      resizeToAvoidBottomInset: true,
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(1.2)),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showFeedback) _buildFeedbackContent(),
                  if (!_showFeedback) _buildVerticalContent(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          leftLabel: '이전',
          rightLabel: _showFeedback ? '다음' : '완료',
          onBack: () {
            if (!_showFeedback) {
              setState(() => _showFeedback = true);
            } else {
              Navigator.pop(context);
            }
          },
          onNext: () {
            if (_showFeedback) {
              setState(() => _showFeedback = false);
            } else {
              _handleComplete();
            }
          },
        ),
      ),
    );
  }

  void _handleComplete() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없어 저장할 수 없습니다.')));
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
        'activatingEvent': widget.activatingEventChips
            .map((e) => e.label)
            .join(', '),
        'belief': widget.beliefChips.map((e) => e.label).join(', '),
        'consequence': widget.resultChips.map((e) => e.label).join(', '),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(userId)
          .collection('abc_models')
          .add(data);

      debugPrint('ABC 모델 저장 성공 - 사용자 ID: $userId');

      if (!mounted) return;
      // 메인 화면으로 이동
      Navigator.pushNamed(context, '/noti_select');
    } catch (e) {
      debugPrint('ABC 모델 저장 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    }
  }
}
