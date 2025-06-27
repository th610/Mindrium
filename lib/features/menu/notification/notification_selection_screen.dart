import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/map_picker.dart';
import 'package:gad_app_team/data/notification_provider.dart'
    show NotificationProvider, NotificationSetting, NotificationMethod, RepeatOption;

class _SelectionButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class NotificationSelectionScreen extends StatefulWidget {
  final bool fromDirectory;
  
  const NotificationSelectionScreen({
    super.key,
    this.fromDirectory = false, 
  });

  @override
  State<NotificationSelectionScreen> createState() =>
      _NotificationSelectionScreenState();
}

class _NotificationSelectionScreenState
    extends State<NotificationSelectionScreen> {
  NotificationSetting? _draft;
  NotificationMethod? _chosen;

  DateTime _startDate = DateTime.now();
  RepeatOption _repeatOption = RepeatOption.none;
  final Set<int> _selectedWeekdays = {};
  late bool _fromDirectory;

  @override
  void initState() {
    super.initState();
    _draft = null;
    _chosen = null;
    _fromDirectory = widget.fromDirectory;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is bool && args == true) {
      _fromDirectory = true;
    }
  }

  Future<void> _showTimeSheet() async {
    TimeOfDay pickedTime = const TimeOfDay(hour: 9, minute: 0);
    // Reset per invocation
    _startDate = DateTime.now();
    _repeatOption = RepeatOption.none;
    _selectedWeekdays.clear();

    final setting = await showModalBottomSheet<NotificationSetting>(
      context: context,
      backgroundColor: AppColors.grey100,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        TimeOfDay pickedTimeLocal = pickedTime;
        return StatefulBuilder(
          builder: (ctx2, setLocal) => Container(
            height: MediaQuery.of(ctx).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Time picker
                      SizedBox(
                        height: 240,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: false,
                          initialDateTime: DateTime(0, 0, 0, pickedTimeLocal.hour, pickedTimeLocal.minute),
                          onDateTimeChanged: (dt) => pickedTimeLocal = TimeOfDay.fromDateTime(dt),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('시작 날짜'),
                              trailing: Text(
                                DateFormat.yMd().format(_startDate),
                                style: TextStyle(fontSize: 16),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setLocal(() => _startDate = date);
                                }
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Divider(height: 1),
                            ),
                            ListTile(
                              title: const Text('반복'),
                              trailing: Text(_repeatOption == RepeatOption.none
                                  ? '안 함'
                                  : _repeatOption == RepeatOption.daily
                                      ? '매일'
                                      : '매주',
                                style: TextStyle(fontSize: 16),
                              ),
                              onTap: () async {
                                final option = await showDialog<RepeatOption>(
                                  context: ctx,
                                  builder: (ctx2) => SimpleDialog(
                                    title: const Text('반복 설정'),
                                    children: [
                                      SimpleDialogOption(
                                        onPressed: () => Navigator.pop(ctx2, RepeatOption.none),
                                        child: const Text('안 함'),
                                      ),
                                      SimpleDialogOption(
                                        onPressed: () => Navigator.pop(ctx2, RepeatOption.daily),
                                        child: const Text('매일'),
                                      ),
                                      SimpleDialogOption(
                                        onPressed: () => Navigator.pop(ctx2, RepeatOption.weekly),
                                        child: const Text('매주'),
                                      ),
                                    ],
                                  ),
                                );
                                if (option != null) {
                                  setLocal(() => _repeatOption = option);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_repeatOption == RepeatOption.weekly) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(7, (i) {
                                final label = ['일','월','화','수','목','금','토'][i];
                                final day = i + 1;
                                final selected = _selectedWeekdays.contains(day);
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(2,0,2,0),
                                  child: FilterChip(
                                    showCheckmark: false,
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.indigo,
                                    label: Text(
                                      label,
                                      style: TextStyle(color: selected ? Colors.white : Colors.black),
                                    ),
                                    selected: selected,
                                    onSelected: (_) => setLocal(() {
                                      if (selected) {
                                        _selectedWeekdays.remove(day);
                                      } else {
                                        _selectedWeekdays.add(day);
                                      }
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: NavigationButtons(
                  leftLabel: '닫기',
                  rightLabel: '완료',
                  onBack: () => Navigator.pop(ctx),
                  onNext: () {
                    Navigator.pop(ctx, NotificationSetting(
                      method: NotificationMethod.time,
                      time: pickedTimeLocal,
                      startDate: _startDate,
                      repeatOption: _repeatOption,
                      weekdays: _selectedWeekdays.toList(),
                    ));
                  },
                ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (setting != null && mounted) {
      setState(() {
        _draft = setting;
        _chosen = setting.method;
      });
    }
  }

  Future<void> _showLocationSheet() async {
    // 기존 _draft 의 좌표를 initial 으로 넘겨줄 수도 있습니다.
    LatLng? initialLatLng;
    if (_draft?.latitude != null && _draft?.longitude != null) {
      initialLatLng = LatLng(_draft!.latitude!, _draft!.longitude!);
    }

    // MapPicker 자체에서 Navigator.pop(NotificationSetting) 호출
    final setting = await showModalBottomSheet<NotificationSetting>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height,
        child: MapPicker(initial: initialLatLng),
      ),
    );

    if (setting != null && mounted) {
      setState(() {
        _draft = setting;
        _chosen = setting.method;
      });
    }
  }
  
  Future<void> _showManualSheet() async {
    setState(() {
      _draft = NotificationSetting(method: NotificationMethod.manual);
      _chosen = NotificationMethod.manual;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(NotificationMethod m, String label, VoidCallback tap) =>
        _SelectionButton(
          text: label,
          selected: _chosen == m,
          onTap: () {
            setState(() => _chosen = m);
            tap();
          },
        );

    String previewText() {
      if (_draft == null) return '아직 선택된 알림이 없습니다.';
      switch (_draft!.method) {
        case NotificationMethod.time:
          final t = _draft!.time!;
          final buffer = StringBuffer();
          buffer.writeln('선택: ${t.format(context)}');
          if (_draft!.startDate != null) {
            buffer.writeln('시작: ${DateFormat.yMd().format(_draft!.startDate!)}');
          }
          if (_draft!.repeatOption != RepeatOption.none) {
            if (_draft!.repeatOption == RepeatOption.daily) {
              buffer.write('반복: 매일');
            } else {
              final days = _draft!.weekdays
                  .map((d) => ['월','화','수','목','금','토','일'][d - 1])
                  .join(',');
              buffer.write('반복: 매주 ($days)');
            }
          }
          return buffer.toString().trim();
        case NotificationMethod.location:
          final loc = _draft!.location ?? '';
          final desc = _draft!.description;
          final label = (desc != null && desc.isNotEmpty)
              ? '$desc ($loc) '
              : loc;
          return '선택: $label';
        case NotificationMethod.manual:
          return '선택: 수동 알림';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(
        title: '알림 방식 선택', 
        showHome: false,
        confirmOnBack: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 100,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '원하는 알림 방식을 선택해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              btn(NotificationMethod.time, '시간', _showTimeSheet),
              const SizedBox(height: 16),
              btn(NotificationMethod.location, '위치', _showLocationSheet),
              const SizedBox(height: 16),
              btn(NotificationMethod.manual, '수동', _showManualSheet),
              const SizedBox(height: 24),
              Text(
                previewText(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Spacer(),
              PrimaryActionButton(
                text: '저장하기',
                onPressed: _draft != null
                    ? () async {
                        // 1) async 작업 전에 NavigatorState 인스턴스 가져오기
                        final navigator = Navigator.of(context);

                        // 2) 네트워크/스케줄링 작업
                        final provider = NotificationProvider();
                        if (_draft!.id != null) {
                          await provider.updateAndSchedule(_draft!);
                        } else {
                          await provider.createAndSchedule(_draft!);
                        }

                        // 3) 작업이 끝난 후, State가 여전히 mounted 상태인지 검사
                        if (!mounted) return;

                        // 4) 미리 가져둔 navigator 인스턴스로 pop 호출
                        if (_fromDirectory) {
                          navigator.pop();
                        } else {
                          navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}