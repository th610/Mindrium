import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:gad_app_team/widgets/map_picker.dart';

import 'package:intl/intl.dart';
import 'package:gad_app_team/data/notification_provider.dart'
    show NotificationProvider, NotificationSetting, NotificationMethod, RepeatOption;
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

/// Firestore 문서를 화면용 모델로 매핑
class NotificationItem {
  final String id;
  final NotificationMethod type;
  final TimeOfDay? time;
  final String detail;
  final bool isActive;
  final String? description;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final RepeatOption repeatOption;
  final List<int> weekdays;

  NotificationItem({
    required this.id,
    required this.type,
    this.time,
    required this.detail,
    this.isActive = true,
    this.description,
    this.latitude,
    this.longitude,
    this.startDate,
    this.repeatOption = RepeatOption.none,
    this.weekdays = const [],
  });

  factory NotificationItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final methodStr = data['method'] as String? ?? 'manual';
    final method = NotificationMethod.values.firstWhere(
      (e) => e.name == methodStr,
      orElse: () => NotificationMethod.manual,
    );
    final active = !(data['disabled'] as bool? ?? false);

    // time parsing
    TimeOfDay? tod;
    if (method == NotificationMethod.time && data['time'] != null) {
      final parts = (data['time'] as String).split(':');
      tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    String detail;
    switch (method) {
      case NotificationMethod.time:
        detail = data['time'] ?? '-';
        break;
      case NotificationMethod.location:
        detail = data['location'] ?? '-';
        break;
      case NotificationMethod.manual:
        detail = '수동';
        break;
    }

    DateTime? sd = (data['startDate'] as Timestamp?)?.toDate();
    RepeatOption ro = RepeatOption.values.firstWhere(
      (e) => e.name == (data['repeatOption'] as String? ?? 'none'),
      orElse: () => RepeatOption.none,
    );
    List<int> wd = List<int>.from(data['weekdays'] as List? ?? []);

    return NotificationItem(
      id: doc.id,
      type: method,
      time: tod,
      detail: detail,
      isActive: active,
      description: data['description'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      startDate: sd,
      repeatOption: ro,
      weekdays: wd,
    );
  }
}

/// 알림 목록 조회 및 편집 화면
class NotificationDirectoryScreen extends StatefulWidget {
  const NotificationDirectoryScreen({super.key});

  @override
  State<NotificationDirectoryScreen> createState() => _NotificationDirectoryScreenState();
}

class _NotificationDirectoryScreenState extends State<NotificationDirectoryScreen> {
  bool _isEditMode = false;
  String? _editingItemId;

  String _label(NotificationMethod m) {
    switch (m) {
      case NotificationMethod.time:
        return '시간';
      case NotificationMethod.location:
        return '위치';
      case NotificationMethod.manual:
        return '수동';
    }
  }

  Future<void> _openDetailSheet(BuildContext ctx, String uid, NotificationItem item) async {
    setState(() => _editingItemId = item.id);

    if (item.type == NotificationMethod.location) {
      final initial = (item.latitude != null && item.longitude != null)
          ? LatLng(item.latitude!, item.longitude!)
          : null;
      final setting = await showModalBottomSheet<NotificationSetting>(
        context: ctx,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SizedBox(
          height: MediaQuery.of(ctx).size.height,
          child: MapPicker(initial: initial),
        ),
      );
      if (!mounted) return;
      if (setting != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notification_settings')
            .doc(item.id)
            .update({
          'latitude': setting.latitude,
          'longitude': setting.longitude,
          'location': setting.location ?? item.detail,
          'description': setting.description ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        final provider = Provider.of<NotificationProvider>(context, listen: false);
        await provider.updateAndSchedule(
          NotificationSetting(
            id: item.id,
            method: NotificationMethod.location,
            latitude: setting.latitude,
            longitude: setting.longitude,
            location: setting.location,
            description: setting.description,
          ),
        );
        if (!mounted) return;
        setState(() {
          _isEditMode = false;
          _editingItemId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 알림이 수정되었습니다.')),
        );
      }
    } else {
      await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: AppColors.grey100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _DetailSheet(uid: uid, item: item),
      );
      if (!mounted) return;
      setState(() {
        _isEditMode = false;
        _editingItemId = null;
      });
    }
  }

  Future<void> _deleteItem(String uid, NotificationItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('정말 삭제하시겠습니까?'),
        content: const Text('이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('notification_settings')
          .doc(item.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(title: '알림', showHome: true),
      body: uid == null
          ? const Center(child: Text('로그인이 필요합니다'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Tooltip(
                        message: _isEditMode ? '편집 모드 종료' : '편집 모드 진입',
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: _isEditMode ? Colors.deepOrange : Colors.indigo,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => setState(() => _isEditMode = !_isEditMode),
                          child: Text(_isEditMode ? '완료' : '편집', style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 28, color: Colors.indigo),
                        tooltip: '새 알림 추가',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/noti_select',
                          arguments: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('notification_settings')
                        .orderBy('savedAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('저장된 알림이 없습니다'));
                      }
                      // 타입별 분류
                      final allItems = docs.map(NotificationItem.fromDoc).toList();
                      final timeItems = allItems.where((e) => e.type == NotificationMethod.time).toList();
                      final locItems = allItems.where((e) => e.type == NotificationMethod.location).toList();
                      final manItems = allItems.where((e) => e.type == NotificationMethod.manual).toList();

                      List<Widget> buildSections() {
                        final sections = <Widget>[];
                        void addSection(String title, IconData icon, List<NotificationItem> items) {
                          if (items.isEmpty) return;
                          sections.add(
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              child: Row(
                                children: [
                                  Icon(icon, color: Colors.indigo),
                                  const SizedBox(width: 8),
                                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                          sections.addAll(items.map((item) => _buildItemCard(uid, item)));
                        }
                        addSection('시간 알림', Icons.access_time, timeItems);
                        addSection('위치 알림', Icons.place, locItems);
                        addSection('수동 알림', Icons.touch_app, manItems);
                        return sections;
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                        children: buildSections(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildItemCard(String uid, NotificationItem item) {
    final isSelected = _isEditMode && item.id == _editingItemId;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: isSelected ? const Icon(Icons.location_on, color: Colors.indigo) : null,
        title: Text(_label(item.type), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: item.type == NotificationMethod.time
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.time != null ? item.time!.format(context) : item.detail,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (item.startDate != null)
                    Text(
                      '시작: ${DateFormat.yMd().format(item.startDate!)}',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  if (item.repeatOption != RepeatOption.none)
                    Text(
                      item.repeatOption == RepeatOption.daily
                          ? '반복: 매일'
                          : '반복: 매주 (${item.weekdays.map((d) => ['월','화','수','목','금','토','일'][d-1]).join(',')})',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                ],
              )
            : item.type == NotificationMethod.location
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description != null && item.description!.isNotEmpty ? item.description! : '-',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        item.detail,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  )
                : Text(
                    item.detail,
                    style: const TextStyle(fontSize: 20, color: Colors.black54),
                  ),
        trailing: _isEditMode
            ? Wrap(
                children: [
                  if (item.type != NotificationMethod.manual)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.indigo),
                      tooltip: '수정',
                      onPressed: () => _openDetailSheet(context, uid, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.deepOrange),
                      tooltip: '삭제',
                      onPressed: () => _deleteItem(uid, item),
                    ),
                ]
              )
            : null,
        onTap: !_isEditMode && item.type != NotificationMethod.manual
            ? () => _openDetailSheet(context, uid, item)
            : null,
      ),
    );
  }
}

/// 시간/수동 알림 편집 상세 시트
class _DetailSheet extends StatefulWidget {
  final String uid;
  final NotificationItem item;
  const _DetailSheet({required this.uid, required this.item});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late TimeOfDay _time;
  bool _saving = false;
  late DateTime _startDate;
  late RepeatOption _repeatOption;
  final Set<int> _selectedWeekdays = {};

  @override
  void initState() {
    super.initState();
    _time = widget.item.time ?? const TimeOfDay(hour: 9, minute: 0);
    _startDate = widget.item.startDate ?? DateTime.now();
    _repeatOption = widget.item.repeatOption;
    _selectedWeekdays.addAll(widget.item.weekdays);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final newSetting = NotificationSetting(
      id: widget.item.id,
      method: NotificationMethod.time,
      time: _time,
      startDate: _startDate,
      repeatOption: _repeatOption,
      weekdays: _selectedWeekdays.toList(),
    );
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.updateAndSchedule(newSetting);
    if (!mounted) return;
    Navigator.pop(context);
    final parent = context.findAncestorStateOfType<_NotificationDirectoryScreenState>();
    if (!mounted) return;
    parent?.setState(() => parent._isEditMode = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('시간 알림이 수정되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 240,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: false,
              initialDateTime: DateTime(2020, 1, 1, _time.hour, _time.minute),
              onDateTimeChanged: (dt) => setState(() => _time = TimeOfDay.fromDateTime(dt)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('시작 날짜'),
                  trailing: Text(DateFormat.yMd().format(_startDate), style: const TextStyle(fontSize: 16)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now().subtract(const Duration(days:365)),
                      lastDate: DateTime.now().add(const Duration(days:365)),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Divider(height: 1),
                ),
                ListTile(
                  title: const Text('반복'),
                  trailing: Text(
                    _repeatOption == RepeatOption.none ? '안 함'
                      : _repeatOption == RepeatOption.daily ? '매일'
                      : '매주',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () async {
                    final opt = await showDialog<RepeatOption>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('반복 설정'),
                        children: [
                          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, RepeatOption.none), child: const Text('안 함')),
                          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, RepeatOption.daily), child: const Text('매일')),
                          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, RepeatOption.weekly), child: const Text('매주')),
                        ],
                      ),
                    );
                    if (opt != null) {
                      setState(() {
                        _repeatOption = opt;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          if (_repeatOption == RepeatOption.weekly) ...[
            const SizedBox(height: 8),
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
                        onSelected: (_) {
                          setState(() {
                            if (selected) { _selectedWeekdays.remove(day); }
                            else { _selectedWeekdays.add(day); }
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          NavigationButtons(
            leftLabel: '닫기',
            rightLabel: '완료',
            onBack: _saving ? null : () => Navigator.pop(context),
            onNext: _saving ? null : _save,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}