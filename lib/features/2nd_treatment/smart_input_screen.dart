import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:provider/provider.dart';
import '../../models/smart_goal_event.dart';
import '../../providers/smart_goal_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartInputScreen extends StatefulWidget {
  const SmartInputScreen({super.key});

  @override
  State<SmartInputScreen> createState() => _SmartInputScreenState();
}

class _SmartInputScreenState extends State<SmartInputScreen> {
  final _controllers = List.generate(5, (_) => TextEditingController());
  final List<String> _answers = [];
  int _currentStep = 0;

  double _anxietyScore = 5;

  bool _isCompleted = false;

  final List<String> _titles = [
    'S (구체적: Specific)',
    'M (측정 가능: Measurable)',
    'A (달성 가능: Achievable)',
    'R (관련성: Relevant)',
    'T (기한: Time-bound)',
  ];

  final List<String> _descriptions = [
    '정말 달성하고자 하는 목표는 무엇인가요?',
    '하루에 얼마나 오래 하면 좋을까요?',
    '목표를 이룰 수 있는 가능성은 얼마나 될까요?',
    '목표를 통해 이루고 싶은 목적이 있다면 무엇일까요?',
    '언제까지 이루고 싶은 기한이 있나요?',
  ];

  final List<String> _examples = [
    '명상하기',
    '10분씩, 주5회',
    '높은 가능성',
    '불안을 관리한다.',
    '이번 주 안에',
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(() {
        setState(() {}); // rebuild when text changes
      });
    }
  }

  void _nextStep() {
    final text = _controllers[_currentStep].text.trim();
    if (_currentStep == 2) {
      // A단계: 답변과 슬라이더 값을 함께 저장
      if (_answers.length > _currentStep) {
        _answers[_currentStep] = '$text (달성 가능성: ${_anxietyScore.toInt()}/10)';
      } else {
        _answers.add('$text (달성 가능성: ${_anxietyScore.toInt()}/10)');
      }
    } else {
      if (text.isEmpty) return;
      if (_answers.length > _currentStep) {
        _answers[_currentStep] = text;
      } else {
        _answers.add(text);
      }
    }
    if (_currentStep < _titles.length - 1) {
      setState(() => _currentStep++);
    } else {
      // 마지막 단계에서만 _answers 길이 체크 후 완료 처리
      if (_answers.length == 5) {
        setState(() => _isCompleted = true);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        // Move back one step first
        _currentStep--;
        // Restore the answer for the current step
        final answerToRestore = _answers[_currentStep];
        if (_currentStep == 2) {
          // A-step: parse slider + text
          final match = RegExp(
            r'(.*) \(달성 가능성: (\d+)/10\)',
          ).firstMatch(answerToRestore);
          if (match != null) {
            _controllers[_currentStep].text = match.group(1) ?? '';
            _anxietyScore =
                double.tryParse(match.group(2) ?? '') ?? _anxietyScore;
          }
        } else {
          // Other steps
          _controllers[_currentStep].text = answerToRestore;
        }
        // Then remove the now-outdated answer entry
        _answers.removeAt(_currentStep + 1);
      });
    }
  }

  Widget _buildStepA() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _descriptions[_currentStep],
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '예시: ${_examples[_currentStep]}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controllers[_currentStep],
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '여기에 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('달성 가능성', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _anxietyScore,
              min: 1,
              max: 10,
              divisions: 9,
              label: _anxietyScore.toInt().toString(),
              onChanged: (v) => setState(() => _anxietyScore = v),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddToCalendarPressed() async {
    // 1. 날짜 선택
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.indigo,
              onPrimary: Colors.white,
              onSurface: AppColors.indigo,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selectedDate == null) return;

    // 2. 목표 요약 팝업
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('[${_answers[0]}] 계획'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('목표: ${_answers[0]}'),
              Text('지표: ${_answers[1]}'),
              Text('가능성: ${_answers[2]}'),
              Text('목적: ${_answers[3]}'),
              Text('기한: ${_answers[4]}'),
              Text('선택 날짜: ${selectedDate.toString().split(' ')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 정보가 없어 저장할 수 없습니다.')),
                  );
                  return;
                }
                // 3. Provider에 저장
                final event = SmartGoalEvent(
                  title: _answers[0],
                  indicator: _answers[1],
                  possibility: _answers[2],
                  purpose: _answers[3],
                  deadline: _answers[4],
                  eventDate: selectedDate,
                );
                Provider.of<SmartGoalProvider>(
                  context,
                  listen: false,
                ).addEvent(event);

                try {
                  final firestore = FirebaseFirestore.instance;

                  // 1. 사용자 문서에 임시 데이터 상태 저장
                  await firestore.collection('users').doc(userId).set({
                    'has_temporary_data': true,
                    'current_screen': 'smart_goal',
                    'last_updated': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  // 2. smart_goals 컬렉션에 데이터 저장
                  final data = {
                    'title': _answers[0],
                    'indicator': _answers[1],
                    'possibility': _answers[2],
                    'purpose': _answers[3],
                    'deadline': _answers[4],
                    'eventDate': selectedDate.toIso8601String(),
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  await firestore
                      .collection('users')
                      .doc(userId)
                      .collection('smart_goals')
                      .add(data);

                  print('파이어베이스 저장 성공 - 사용자 ID: $userId');
                  Navigator.pop(context); // 팝업 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('캘린더에 목표가 추가되었습니다!')),
                  );
                } catch (e) {
                  print('파이어베이스 저장 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
                  );
                  return;
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(title: '2주차 - SMART 목표 설정'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isCompleted) ...[
                Card(
                  color: AppColors.indigo50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(
                          _answers.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titles[i],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _answers[i],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_currentStep < _titles.length) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            _titles[_currentStep],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_currentStep == 2)
                  _buildStepA()
                else
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _descriptions[_currentStep],
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '예시: ${_examples[_currentStep]}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _controllers[_currentStep],
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: '여기에 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: _currentStep < 4 ? '다음' : '완료',
                  onBack:
                      _currentStep > 0
                          ? _previousStep
                          : () => Navigator.pop(context),
                  onNext:
                      _currentStep == 2
                          ? _nextStep
                          : (_controllers[_currentStep].text.trim().isNotEmpty
                              ? _nextStep
                              : null),
                ),
              ] else if (_answers.length == 5) ...[
                Card(
                  color: AppColors.indigo50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            '항목',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            '내용',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            const DataCell(Text('목표')),
                            DataCell(Text(_answers[0])),
                          ],
                        ),
                        DataRow(
                          cells: [
                            const DataCell(Text('지표')),
                            DataCell(Text(_answers[1])),
                          ],
                        ),
                        DataRow(
                          cells: [
                            const DataCell(Text('가능성')),
                            DataCell(Text(_answers[2])),
                          ],
                        ),
                        DataRow(
                          cells: [
                            const DataCell(Text('목적')),
                            DataCell(Text(_answers[3])),
                          ],
                        ),
                        DataRow(
                          cells: [
                            const DataCell(Text('기한')),
                            DataCell(Text(_answers[4])),
                          ],
                        ),
                      ],
                      dataRowHeight: null,
                      headingRowHeight: null,
                      horizontalMargin: 0,
                      columnSpacing: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '대단해요!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: _answers[0],
                                style: const TextStyle(
                                  color: AppColors.indigo,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(
                                text: '을(를) 목표로 이번 한 주 동안 달성해 볼까요?',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('캘린더에 추가하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.indigo,
                            side: const BorderSide(color: AppColors.indigo),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _onAddToCalendarPressed,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: '완료',
                  onBack: () {
                    setState(() {
                      _isCompleted = false;
                      _currentStep = _titles.length - 1; // go back to T step
                    });
                  },
                  onNext: () {
                    // Navigate to 주차별 치료 화면. Replace routeName with the actual route.
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                ),
              ] else ...[
                // 방어: 데이터가 부족할 때는 안내 메시지
                Center(
                  child: Text(
                    '입력 데이터가 부족합니다. 다시 시도해 주세요.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
