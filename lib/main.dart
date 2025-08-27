import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ 추가

import 'providers/bluetooth_provider.dart';
import 'firebase_options.dart';

import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/ondevice/ondevice_screen.dart';
import 'screens/ondevice/ondevice_camera_screen.dart';
import 'screens/ondevice/ondevice_loading_screen.dart';
import 'screens/ondevice/ondevice_result_screen.dart';
import 'screens/data_period/data_period_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/setting/setting_screen.dart';
import 'screens/input_info/input_info_name_screen.dart';
import 'screens/input_info/input_info_nick_screen.dart';
import 'screens/input_info/input_info_name_setting_screen.dart';
import 'screens/input_info/input_info_nick_setting_screen.dart';
import 'screens/input_period/input_period_recent_screen.dart';
import 'screens/input_period/input_period_cycle_screen.dart';
import 'screens/input_period/input_period_days_screen.dart';
import 'screens/input_period/input_period_extra_screen.dart';
import 'screens/input_period/input_period_setting_screen.dart';
import 'screens/input_ble/input_ble_initial_screen.dart';
import 'screens/input_ble/input_ble_setting_screen.dart';
import 'screens/usage/usage_screens_container.dart';

import 'services/user_service.dart';
import 'services/period_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ 익명 로그인 (비회원)
  // final userCred = await FirebaseAuth.instance.signInAnonymously();
  // final String uid = userCred.user!.uid;
  // // ignore: avoid_print
  // print('[Auth] Anonymous signed in: $uid');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<PeriodService>(create: (_) => PeriodService()),
        // 원하면 Provider<String>(value: uid) 로 전역 제공도 가능
      ],
      // child: MyApp(userId: uid), // ✅ uid 전달
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // final String userId;
  // const MyApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOYA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        primaryColor: const Color(0xFFFF85B4),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF85B4)),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium:TextStyle(fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(fontWeight: FontWeight.w600),
          bodyLarge:  TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall:  TextStyle(fontWeight: FontWeight.w400),
          labelLarge:  TextStyle(fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall:  TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      initialRoute: '/login',

      // 정적 route들
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/input_name': (context) => InputInfoNameScreen(),
        '/input_nick': (context) => InputInfoNickScreen(),
        '/input_recent': (context) => InputPeriodRecentScreen(),
        '/input_cycle': (context) => InputPeriodCycleScreen(),
        '/input_days': (context) => InputPeriodDaysScreen(),
        '/input_extra': (context) => InputPeriodExtraScreen(),
        '/ondevice': (context) => OndeviceScreen(),
        '/ondevice_camera': (context) => OndeviceCameraScreen(),
        '/ondevice_loading': (context) => OndeviceLoadingScreen(),
        '/ondevice_result': (context) => OndeviceResultScreen(),
        '/data': (context) => DataPeriodScreen(),
        '/notification': (context) => NotificationScreen(),
        '/input_ble': (context) => InputBleInitialScreen(),
        '/setting': (context) => SettingScreen(),
        '/setting_name': (context) => InputInfoNameSettingScreen(),
        '/setting_nick': (context) => InputInfoNickSettingScreen(),
        '/setting_period': (context) => InputPeriodSettingScreen(),
        '/setting_bluetooth': (context) => InputBleSettingScreen(),
        '/usage_container': (context) => UsageScreensContainer(),
      },

      // // ✅ 첫 진입(/home) 때 userId를 arguments로 주입
      // onGenerateRoute: (settings) {
      //   if (settings.name == '/home') {
      //     // 기존 args와 merge
      //     final prevArgs = (settings.arguments as Map?) ?? {};
      //     return MaterialPageRoute(
      //       builder: (_) => HomeScreen(),
      //       settings: RouteSettings(arguments: {...prevArgs, 'userId': userId}),
      //     );
      //   }
      //   return null; // 나머지는 routes 테이블 사용
      // },
    );
  }
}