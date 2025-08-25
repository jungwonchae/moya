import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/screens/home/widgets/cycle_status_card.dart';
import 'package:moya_app/widgets/bluetooth_button.dart';
import 'package:moya_app/providers/bluetooth_provider.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/widgets/period_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'MOYA';
  int daysUntilNext = 5;
  bool isOnPeriod = false;

  // 예시 데이터
  int changeCount = 2;
  String lastChangeText = '0.5시간 전';

  // PeriodWidget과 동기화되는 상태
  PadStatus padStatus = PadStatus.before;

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const NavBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GreetingHeader(
                userName: userName,
                height: 190,
                dropAsset: 'assets/icons/moya.svg',
                onAiTap: () => Navigator.pushNamed(context, '/ondevice'),
                onBellTap: () => Navigator.pushNamed(context, '/notification'),
              ),

              // 상태 카드 + 블루투스 칩 (헤더에 겹치도록 위로)
              Transform.translate(
                offset: const Offset(0, -80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      CycleStatusCard(
                        isOnPeriod: isOnPeriod,
                        days: daysUntilNext,
                        dropAsset: 'assets/icons/moya.svg',
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BluetoothStatusChip(
                          isConnected: bluetooth.isConnected,
                          onTap: () => Navigator.pushNamed(context, '/setting_bluetooth'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ⬆︎ PeriodWidget 자체를 조금 더 위로 당기고 싶다면 offset 값을 더 음수로
              Transform.translate(
                offset: const Offset(0, -50), // ← 여기 숫자만 조절하면 위/아래 이동
                child: Center(
                  child: PeriodWidget(
                    status: padStatus,
                    showDemoToggle: true,
                    onStatusChanged: (s) => setState(() => padStatus = s),
                    onStartTap: () => Navigator.pushNamed(context, '/input_recent'),
                    changeCount: changeCount,
                    lastChangeText: lastChangeText,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
