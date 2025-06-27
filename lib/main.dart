import 'app.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Firebase 설정 및 사용자 프로바이더
import 'package:gad_app_team/firebase_options.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/daycounter.dart';

// 일기 providers
import 'package:gad_app_team/data/diary_entry_repository.dart';
import 'package:gad_app_team/data/diary_entry_provider.dart';
import 'package:gad_app_team/data/weekly_entry_repository.dart';
import 'package:gad_app_team/data/weekly_entry_provider.dart';

// 불안 노출치료
import 'package:gad_app_team/data/exposure_provider.dart';

// 건강한 습관
import 'package:gad_app_team/data/habit_provider.dart';
import 'package:gad_app_team/data/calendar_manager.dart';

// 알림
import 'package:gad_app_team/data/notification_provider.dart';

/// 앱 시작점 (entry point)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase 초기화 (환경별 설정 적용)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) 전역 상태 관리를 위한 MultiProvider 설정 및 앱 실행
  runApp(
    MultiProvider(
      providers: [
        // 기본 Provider
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserDayCounter()),

        // Repository Provider
        Provider<DiaryEntryRepository>(
          create: (_) => FirestoreDiaryEntryRepository(),
        ),
        Provider<WeeklyEntryRepository>(
          create: (_) => FirestoreWeeklyEntryRepository(),
        ),

        // DiaryEntryNotifier (일별 일기용)
        ChangeNotifierProxyProvider3<
          DiaryEntryRepository,
          UserProvider,
          UserDayCounter,
          DiaryEntryNotifier
        >(
          create:
              (_) => DiaryEntryNotifier(
                repository: DummyDiaryEntryRepository(),
                userId: '',
                daysSinceJoin: 0,
              ),
          update:
              (_, repo, user, counter, __) => DiaryEntryNotifier(
                repository: repo,
                userId: user.userId,
                daysSinceJoin: counter.daysSinceJoin,
              ),
        ),

        // WeeklyEntryNotifier (주간 일기용)
        ChangeNotifierProxyProvider3<
          WeeklyEntryRepository,
          UserProvider,
          UserDayCounter,
          WeeklyEntryNotifier
        >(
          create:
              (_) => WeeklyEntryNotifier(
                repository: DummyWeeklyEntryRepository(),
                userId: '',
                weekId: '000',
              ),
          update:
              (_, repo, user, counter, __) => WeeklyEntryNotifier(
                repository: repo,
                userId: user.userId,
                weekId: counter
                    .getWeekNumberFromJoin(DateTime.now())
                    .toString()
                    .padLeft(3, '0'),
              ),
        ),

        // DiaryEntriesForCurrentWeekProvider
        ChangeNotifierProxyProvider2<
          DiaryEntryRepository,
          UserProvider,
          DiaryEntriesForCurrentWeekProvider
        >(
          create:
              (_) => DiaryEntriesForCurrentWeekProvider(
                repository: DummyDiaryEntryRepository(),
                userId: '',
              ),
          update:
              (_, repo, user, __) => DiaryEntriesForCurrentWeekProvider(
                repository: repo,
                userId: user.userId,
              ),
        ),

        // DiaryEntryTodayProvider (오늘 일기)
        ChangeNotifierProxyProvider2<
          DiaryEntryRepository,
          UserProvider,
          DiaryEntryTodayProvider
        >(
          create:
              (_) => DiaryEntryTodayProvider(
                repository: DummyDiaryEntryRepository(),
                userId: '',
              ),
          update:
              (_, repo, user, __) => DiaryEntryTodayProvider(
                repository: repo,
                userId: user.userId,
              ),
        ),

        // WeeklyEntryByCurrentWeekProvider (이번 주 주간일기)
        ChangeNotifierProxyProvider3<
          WeeklyEntryRepository,
          UserProvider,
          UserDayCounter,
          WeeklyEntryByCurrentWeekProvider
        >(
          create:
              (_) => WeeklyEntryByCurrentWeekProvider(
                repository: DummyWeeklyEntryRepository(),
                userId: '',
                currentWeek: 0,
              ),
          update:
              (_, repo, user, counter, __) => WeeklyEntryByCurrentWeekProvider(
                repository: repo,
                userId: user.userId,
                currentWeek: counter.getWeekNumberFromJoin(DateTime.now()),
              ),
        ),

        // AllDiaryEntriesProvider (전체 걱정일기 리스트)
        ChangeNotifierProxyProvider2<
          DiaryEntryRepository,
          UserProvider,
          AllDiaryEntriesProvider
        >(
          create:
              (_) => AllDiaryEntriesProvider(
                repository: DummyDiaryEntryRepository(),
                userId: '',
              ),
          update:
              (_, repo, user, __) => AllDiaryEntriesProvider(
                repository: repo,
                userId: user.userId,
              ),
        ),

        // AllWeeklyEntriesProvider (전체 주간일기 리스트)
        ChangeNotifierProxyProvider2<
          WeeklyEntryRepository,
          UserProvider,
          AllWeeklyEntriesProvider
        >(
          create:
              (_) => AllWeeklyEntriesProvider(
                repository: DummyWeeklyEntryRepository(),
                userId: '',
              ),
          update:
              (_, repo, user, __) => AllWeeklyEntriesProvider(
                repository: repo,
                userId: user.userId,
              ),
        ),

        // 불안 노출치료
        ChangeNotifierProvider(create: (_) => ExposureProvider()),

        // 3주차 (건강한 습관, 캘린더 매니저)
        ChangeNotifierProvider(create: (_) => CalendarManager()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),

        // 알림
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
