import 'package:flutter/material.dart';
import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/widgets/period_calendar.dart'; // ⬅️ 새 위젯
import 'package:moya_app/themes/colortheme.dart';

class DataPeriodScreen extends StatefulWidget {
  const DataPeriodScreen({super.key});

  @override
  State<DataPeriodScreen> createState() => _DataPeriodScreenState();
}

class _DataPeriodScreenState extends State<DataPeriodScreen> {
  String userName = 'MOYA';

  /// 데모 이벤트(날짜 → 로그)
  final Map<DateTime, List<DayLog>> _events = {};

  @override
  void initState() {
    super.initState();
    _seedDemo();
  }

  void _seedDemo() {
    final today = PeriodCalendar.normalize(DateTime.now());
    _events[today] = const [
      DayLog(time: TimeOfDay(hour: 3, minute: 56), title: '생리대 교체'),
      DayLog(time: TimeOfDay(hour: 8, minute: 53), title: '생리대 교체'),
    ];

    final startDay = PeriodCalendar.normalize(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    _events[startDay] = const [
      DayLog(time: TimeOfDay(hour: 9, minute: 0), title: '생리 시작'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const NavBar(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 인사 헤더 (데이터 화면은 조금 더 낮게)
              GreetingHeader(
                userName: userName,
                height: 120,
                dropAsset: 'assets/icons/moya.svg',
                onAiTap: () => Navigator.pushNamed(context, '/ondevice'),
                onBellTap: () => Navigator.pushNamed(context, '/notification'),
              ),

              // 달력 패널 (월/선택/로그까지 한 번에)
              PeriodCalendar(
                events: _events,
                onSelected: (d) {
                  // 필요하면 여기서 선택된 날짜에 따라 추가 액션
                },
                // padding 기본이 좌우 24라서 별도 지정 안 해도 됨
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
