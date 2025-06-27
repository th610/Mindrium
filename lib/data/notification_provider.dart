import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:geofence_service/geofence_service.dart' as gf;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/app.dart';

/// ───────────────────────── MODELS ─────────────────────────
enum NotificationMethod { time, location, manual }
enum RepeatOption { none, daily, weekly }

class NotificationSetting {
  final NotificationMethod method;
  final DateTime? startDate;       
  final RepeatOption repeatOption; 
  final List<int> weekdays; 
  final TimeOfDay? time;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? id;
  final DateTime savedAt;
  final String? cause;

  NotificationSetting({
    required this.method,
    this.cause,
    this.time,
    this.startDate,
    this.repeatOption = RepeatOption.none,
    this.weekdays = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.description,
    this.id,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool includeSavedAt = true}) {
    final map = <String, dynamic>{'method': method.name};
    if (includeSavedAt) {
      map['savedAt'] = Timestamp.fromDate(savedAt);
    }
    if (method == NotificationMethod.time && time != null) {
      map['time'] =
          '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
      if (startDate != null) {
        map['startDate'] = Timestamp.fromDate(startDate!);
      }
      map['repeatOption'] = repeatOption.name;
      if (repeatOption == RepeatOption.weekly && weekdays.isNotEmpty) {
        map['weekdays'] = weekdays;
      }
    } else if (method == NotificationMethod.location &&
        latitude != null &&
        longitude != null) {
      map
        ..['latitude'] = latitude
        ..['longitude'] = longitude
        ..['location'] = location;
      if (description != null) map['description'] = description;
    }
    return map;
  }

  factory NotificationSetting.fromJson(Map<String, dynamic> json,
      {String? id}) {
    final method =
        NotificationMethod.values.firstWhere((e) => e.name == json['method']);
    TimeOfDay? tod;
    DateTime? sd;
    RepeatOption ro = RepeatOption.none;
    List<int> wd = [];
    if (method == NotificationMethod.time && json['time'] != null) {
      final p = (json['time'] as String).split(':');
      tod = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    if (method == NotificationMethod.time) {
      if (json['startDate'] != null) {
        sd = (json['startDate'] as Timestamp).toDate();
      }
      if (json['repeatOption'] != null) {
        ro = RepeatOption.values.firstWhere((e) => e.name == json['repeatOption']);
      }
      if (ro == RepeatOption.weekly && json['weekdays'] is List) {
        wd = List<int>.from(json['weekdays']);
      }
    }
    return NotificationSetting(
      method: method,
      time: tod,
      startDate: sd,
      repeatOption: ro,
      weekdays: wd,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      location: json['location'] as String?,
      description: json['description'] as String?,
      id: id,
      savedAt: (json['savedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// ───────────────────────── PROVIDER ─────────────────────────
class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _inst = NotificationProvider._internal();
  factory NotificationProvider() => _inst;
  NotificationProvider._internal() {
    _ready = _init();
  }

  late final Future<void> _ready;
  NotificationSetting? _current;
  NotificationSetting? get current => _current;

  final _fln = FlutterLocalNotificationsPlugin();
  final _geofence = gf.GeofenceService.instance.setup(
    interval: 60000,
    accuracy: 100,
    loiteringDelayMs: 10000,
  );

  /* ─────────── 초기화 ─────────── */
  Future<void> _init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    await _fln.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final route = resp.payload;
        if (route?.startsWith('/') == true) {
          navigatorKey.currentState?.pushNamed(route!);
        }
      },
    );

    await Geolocator.requestPermission();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notification_settings')
          .orderBy('savedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        _current = NotificationSetting.fromJson(doc.data(), id: doc.id);
        await _applySetting(_current!);
      }
    }
    notifyListeners();
  }

  /* ─────────── 권한 헬퍼 ─────────── */
  Future<bool> _ensure(Permission p) async =>
      (await p.status).isGranted || (await p.request()).isGranted;

  /* ─────────── 새 알림 생성 ─────────── */
  Future<void> createAndSchedule(NotificationSetting setting) async {
    await _ready;
    if (!await _ensure(Permission.notification)) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notification_settings')
        .add(setting.toJson());

    _current = setting.copyWith(id: ref.id);
    await _reSchedule(setting);
    notifyListeners();
  }
// ───────────────────────── 기존 알림 업데이트 + 재스케줄 ─────────────────────────
  Future<void> updateAndSchedule(NotificationSetting setting) async {
    await _ready;                               // 초기화 보장

    // 1) 문서 ID가 없으면 새로 추가
    if (setting.id == null) {
      await createAndSchedule(setting);
      return;
    }

    // 2) Firestore 문서 갱신
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notification_settings')
        .doc(setting.id)
        .update(setting.toJson(includeSavedAt: false));   // savedAt 유지

    // 3) 로컬 상태 갱신 + 스케줄 다시 등록
    _current = setting;
    await _reSchedule(setting);
    notifyListeners();
  }
  /* ─────────── 기존 알림 갱신(시간·설명 등) ─────────── */
  /// ★ 시간만 수정
  Future<void> updateTimeOfDay(String docId, TimeOfDay t) async {
    await _ready;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notification_settings')
        .doc(docId)
        .update({'time': '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'});

    _current = _current?.copyWith(time: t);
    await _reSchedule(_current!);
    notifyListeners();
  }

  /// ★ 장소 알림 설명만 수정
  Future<void> updateLocationDescription(String docId, String desc) async {
    await _ready;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notification_settings')
        .doc(docId)
        .update({'description': desc});

    _current = _current?.copyWith(description: desc);
    // 스케줄 변경 없음
    notifyListeners();
  }

  /* ─────────── 수동 트리거 ─────────── */
  Future<void> triggerManual() => _showNow(
        title: '지금 기록해 보세요!',
        body: '버튼을 눌러 감정·행동을 남겨 보세요.',
      );

  /* ─────────── 스케줄 적용/갱신 ─────────── */
  Future<void> _reSchedule(NotificationSetting s) async {
    await _cancelAll();
    await _applySetting(s);
  }

  Future<void> _applySetting(NotificationSetting s) async {
    switch (s.method) {
      case NotificationMethod.time:
        if (s.time != null) await _scheduleDaily(s.time!);
        break;
      case NotificationMethod.location:
        if (s.latitude != null && s.longitude != null) {
          await _startGeofenceLatLng(
              address: s.description ?? s.location ?? '',
              lat: s.latitude!,
              lng: s.longitude!);
        } else if (s.location != null) {
          await _startGeofenceFromAddress(s.location!);
        }
        break;
      case NotificationMethod.manual:
        break;
    }
  }

  /* ─────────── 시간 알림 스케줄 ─────────── */
  Future<void> _scheduleDaily(TimeOfDay tod) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, tod.hour, tod.minute);
    if (first.isBefore(now)) first = first.add(const Duration(days: 1));

    final id = first.millisecondsSinceEpoch % 1000000000;
    final exact = await _ensure(Permission.scheduleExactAlarm);

    try {
      await _fln.zonedSchedule(
        id,
        '오늘의 감정 기록 😊',
        '지금 상태를 작성해 보세요!',
        first,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel',
            'Daily Notification',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/abc',
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _fln.zonedSchedule(
          id,
          '오늘의 감정 기록 😊',
          '지금 상태를 작성해 보세요!',
          first,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_channel',
              'Daily Notification',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: '/abc',
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    }
    return;
  }

  /* ─────────── 지오펜스 ─────────── */
  Future<void> _startGeofenceFromAddress(String addr) async {
    try {
      final key = vworldApiKey;
      final uri = Uri.parse(
        'http://api.vworld.kr/req/address'
        '?service=address&request=getcoord'
        '&address=${Uri.encodeComponent(addr)}'
        '&type=road&inputCoordSystem=WGS84GEO&output=json&key=$key',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return;

      final j = json.decode(res.body) as Map<String, dynamic>;
      final p = j['response']?['result']?['point'] as Map<String, dynamic>?;
      final lat = double.tryParse(p?['y']?.toString() ?? '');
      final lng = double.tryParse(p?['x']?.toString() ?? '');
      if (lat == null || lng == null) return;

      await _startGeofenceLatLng(address: addr, lat: lat, lng: lng);
    } catch (_) {}
    return;
  }

  //위치 도착 알림
  Future<void> _startGeofenceLatLng({
    required String address,
    required double lat,
    required double lng,
  }) async {
    if (!await _ensure(Permission.activityRecognition)) return;
    if (!await _ensure(Permission.locationWhenInUse)) return;

    final region = gf.Geofence(
      id: 'record_region',
      latitude: lat,
      longitude: lng,
      radius: [gf.GeofenceRadius(id: '100m', length: 100)],
    );
    _geofence.addGeofenceStatusChangeListener((g, r, status, loc) async {
      if (status == gf.GeofenceStatus.ENTER ||
          status == gf.GeofenceStatus.DWELL) {
        _showNow(
          title: '도착하셨네요!',
          body: address.isNotEmpty
              ? '“$address”에 도착했습니다. 여기서 기록해 보세요.'
              : '설정한 위치에 도착했습니다. 여기서 기록해 보세요.',
        );
      }
    
    });
    await _geofence.start([region]);
  }

  /* ─────────── 즉시 푸시 ─────────── */
  Future<void> _showNow({required String title, required String body}) async {
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch % 1000000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'Instant Push',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /* ─────────── 취소 ─────────── */
  Future<void> _cancelAll() async {
    await _fln.cancelAll();
    await _geofence.stop();
    _geofence.clearAllListeners();
    _geofence.clearGeofenceList();
  }
}

/* ─────────── 확장 메서드 (copyWith) ─────────── */
extension _NSCopy on NotificationSetting {
  NotificationSetting copyWith({
    NotificationMethod? method,
    TimeOfDay? time,
    DateTime? startDate,
    RepeatOption? repeatOption,
    List<int>? weekdays,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    String? id,
  }) =>
      NotificationSetting(
        method: method ?? this.method,
        time: time ?? this.time,
        startDate: startDate ?? this.startDate,
        repeatOption: repeatOption ?? this.repeatOption,
        weekdays: weekdays ?? this.weekdays,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        description: description ?? this.description,
        id: id ?? this.id,
        savedAt: savedAt,
      );
}