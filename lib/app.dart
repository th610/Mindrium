import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//treatment
import 'package:gad_app_team/features/1st_treatment/week1_screen.dart'; 

import 'package:gad_app_team/features/2nd_treatment/week2_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_input_screen.dart';

import 'package:gad_app_team/features/3rd_treatment/week3_screen.dart';  
import 'package:gad_app_team/features/3rd_treatment/habit_1.dart'; 
import 'package:gad_app_team/features/3rd_treatment/habit_2.dart'; 
import 'package:gad_app_team/features/3rd_treatment/habit_3.dart';
import 'package:gad_app_team/features/3rd_treatment/habit_4.dart';  
import 'package:gad_app_team/features/3rd_treatment/habit_5.dart';
import 'package:gad_app_team/features/3rd_treatment/habit_6.dart'; 

// Feature imports
import 'package:gad_app_team/features/auth/login_screen.dart';
import 'package:gad_app_team/features/auth/signup_screen.dart';
import 'package:gad_app_team/features/auth/terms_screen.dart';
import 'package:gad_app_team/features/menu/calendar/calendar_screen.dart';
import 'package:gad_app_team/features/other/splash_screen.dart';
import 'package:gad_app_team/features/other/tutorial_screen.dart';
import 'package:gad_app_team/features/other/pretest_screen.dart';
import 'package:gad_app_team/features/settings/setting_screen.dart';

// Menu imports
import 'package:gad_app_team/features/menu/contents_screen.dart';
import 'package:gad_app_team/features/menu/education/education_screen.dart';
import 'package:gad_app_team/features/menu/education/education1.dart';
import 'package:gad_app_team/features/menu/education/education2.dart';
import 'package:gad_app_team/features/menu/education/education3.dart';
import 'package:gad_app_team/features/menu/education/education4.dart';
import 'package:gad_app_team/features/menu/education/education5.dart';
import 'package:gad_app_team/features/menu/education/education6.dart';
import 'package:gad_app_team/features/menu/relaxation/relaxation_screen.dart';
import 'package:gad_app_team/features/menu/relaxation/breathing_meditation.dart';
import 'package:gad_app_team/features/menu/relaxation/muscle_relaxation.dart';
import 'package:gad_app_team/features/menu/diary/diary_entry_screen.dart';
import 'package:gad_app_team/features/menu/diary/diary_screen.dart';
import 'package:gad_app_team/features/menu/diary/daily_diary_screen.dart';
import 'package:gad_app_team/features/menu/diary/weekly_diary_1.dart';
import 'package:gad_app_team/features/menu/diary/weekly_diary_2.dart';
import 'package:gad_app_team/features/menu/diary/weekly_diary_3.dart';
import 'package:gad_app_team/features/menu/diary/diary_record_screen.dart';
import 'package:gad_app_team/features/menu/exposure/exposure_screen.dart';

// Navigation screen imports
import 'package:gad_app_team/navigation/screen/home_screen.dart';
import 'package:gad_app_team/navigation/screen/mindrium_screen.dart';
import 'package:gad_app_team/navigation/screen/myinfo_screen.dart';
import 'package:gad_app_team/navigation/screen/report_screen.dart';
import 'package:gad_app_team/navigation/screen/treatment_screen.dart';

/// Mindrium 메인 앱 클래스
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mindrium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'), // 한국어
        Locale('en'), // 영어 (기본값)
      ],
      home: const SplashScreen(),
      routes: {
        // 인증 관련
        '/login': (context) => const LoginScreen(),
        '/terms': (context) => const TermsScreen(),
        '/signup': (context) => const SignupScreen(),

        // 네비게이션
        '/tutorial': (context) => const TutorialScreen(),
        '/pretest': (context) => const PreTestScreen(),
        '/home': (context) => const HomeScreen(),
        '/myinfo': (context) => const MyInfoScreen(),
        '/treatment': (context) => const TreatmentScreen(),
        '/report': (context) => const ReportScreen(),
        '/mindrium': (context) => const MindriumScreen(),

        // 메뉴
        '/contents': (context) => const ContentScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/calendar': (context) => const CalendarScreen(),

        '/education': (context) => const EducationScreen(),
        '/education1': (context) => const Education1Page(),
        '/education2': (context) => const Education2Page(),
        '/education3': (context) => const Education3Page(),
        '/education4': (context) => const Education4Page(),
        '/education5': (context) => const Education5Page(),
        '/education6': (context) => const Education6Page(),

        '/breath_muscle_relaxation': (context) => const RelaxationScreen(),
        '/breathing_meditation': (context) => const BreathingMeditationPage(), 
        '/muscle_relaxation': (context) => const MuscleRelaxationPage(),

        '/diary_entry': (context) => DiaryEntryScreen(),
        '/diary': (context) => DiaryScreen(),
        '/daily_diary': (context) => DailyDiaryScreen(),
        '/weekly_diary_1': (context) => WeeklyDiaryScreen1(),
        '/weekly_diary_2': (context) => WeeklyDiaryScreen2(),
        '/weekly_diary_3': (context) => WeeklyDiaryScreen3(),
        '/diary_record': (context) => DiaryRecordScreen(),

        '/exposure': (context) => ExposureScreen(),

        //treatment
        '/week1': (context) => const Week1Screen(),
        
        '/week2': (context) => const Week2Screen(),
        '/abc': (context) => const AbcInputScreen(),
        
        '/week3': (context) => const Week3Screen(),
        '/habit1': (context) => Habit1Page(),
        '/habit2': (context) => Habit2Page(),
        '/habit3': (context) => Habit3Page(),
        '/habit4': (context) => Habit4Page(),
        '/habit5': (context) => Habit5Page(),
        '/habit6': (context) => Habit6Page(),
      },
    );
  }
}