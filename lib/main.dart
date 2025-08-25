import 'package:flutter/material.dart';
import 'package:provider/provider.dart';   // provider import
import 'providers/bluetooth_provider.dart';  //만든 provider import

import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
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
void main() {
  runApp(
    MultiProvider(   // Provider들을 묶어서 주입
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        // 앞으로 다른 Provider 추가할 때 여기에등록 
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOYA',
      theme: ThemeData(
        useMaterial3: true,                  // 머티리얼3 활성화
        fontFamily: 'Pretendard',            // pubspec.yaml에 등록한 폰트 패밀리 이름
        primaryColor: const Color(0xFFFF85B4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF85B4),
        ),
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
      home: LoginScreen(),
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
        '/setting_nick': (context) => InputInfoNickScreen(),
        '/setting_period': (context) => InputPeriodSettingScreen(),
        '/setting_bluetooth': (context) => InputBleSettingScreen(),

<<<<<<< Updated upstream
        '/usage_guide': (context) => UsageFirstScreen(),
        '/usage_first': (context) => UsageFirstScreen(),
        '/usage_second': (context) => UsageSecondScreen(), 
        '/usage_third': (context) => UsageThirdScreen(),
=======
        
        '/usage_container': (context) => UsageScreensContainer(),
>>>>>>> Stashed changes
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
