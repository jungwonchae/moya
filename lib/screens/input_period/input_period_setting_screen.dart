import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/services/period_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;


class InputPeriodSettingScreen extends StatefulWidget {
  const InputPeriodSettingScreen({super.key});

  @override
  State<InputPeriodSettingScreen> createState() => _InputPeriodSettingScreenState();
}

class _InputPeriodSettingScreenState extends State<InputPeriodSettingScreen> {
  final PeriodService _service = PeriodService();
  bool _loading = true;

  // 현재 설정값들
  DateTime? recentStartDate;
  int? cycleLength;
  int? periodDays;
  Map<String, dynamic>? extraData;

  String? userId;
  String? periodId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  Future<void> _loadCurrentSettings() async {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    userId = args['userId'] as String?;
    periodId = args['periodId'] as String?;

    print('[SettingScreen] Loading settings for userId: $userId, periodId: $periodId');

    try {
      // periodId 없으면 userId 기준으로 최근 데이터 찾기
      if ((periodId == null || periodId!.isEmpty) && userId != null) {
        final latest = await _service.getLatestPeriod(userId!);
        if (latest != null) {
          periodId = latest['periodId'] as String?;
          print('[SettingScreen] Found latest periodId: $periodId');
        }
      }

      if (periodId == null) {
        print('[SettingScreen] No periodId found');
        setState(() => _loading = false);
        return;
      }

      final data = await _service.getPeriodData(periodId!);
      print('[SettingScreen] Raw Firebase data: $data');
      
      if (!mounted) return;
      
      // 다양한 필드명으로 시도
      DateTime? startDate;
      int? cycle;
      int? days;
      Map<String, dynamic>? extra;
      
      // startDate 처리
      final startValue = data['startDate'];
      if (startValue is Timestamp) {
        startDate = startValue.toDate();
      } else if (startValue is DateTime) {
        startDate = startValue;
      }
      print('[SettingScreen] Parsed startDate: $startDate');
      
      // cycleLength 처리
      cycle = data['cycleLength'] as int?;
      print('[SettingScreen] Parsed cycleLength: $cycle');
      
      // periodDays/periodLength 처리
      days = data['periodDays'] as int?;
      if (days == null) {
        days = data['periodLength'] as int?;
      }
      print('[SettingScreen] Parsed periodDays/periodLength: $days');
      
      // extraData 처리
      extra = data['extraData'] as Map<String, dynamic>?;
      if (extra != null) {
        print('[SettingScreen] extraData contents: $extra');
        
        // endDate가 Timestamp일 경우 DateTime으로 변환
        if (extra.containsKey('endDate') && extra['endDate'] is Timestamp) {
          final timestamp = extra['endDate'] as Timestamp;
          extra['endDate'] = timestamp.toDate();
          print('[SettingScreen] Converted endDate to DateTime: ${extra['endDate']}');
        }
      }
      
      setState(() {
        recentStartDate = startDate;
        cycleLength = cycle;
        periodDays = days;
        extraData = extra;
        _loading = false;
      });
      
      print('[SettingScreen] State updated - startDate: $recentStartDate, cycle: $cycleLength, days: $periodDays, extraData: $extraData');
      
    } catch (e) {
      print('[SettingScreen] Error loading settings: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String formatKoreanDate(DateTime? date) {
    if (date == null) return '날짜 선택';
    return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
  }

  // 최근 시작일 수정
  void _editRecentStartDate() {
    Navigator.pushNamed(
      context,
      '/input_recent',
      arguments: {
        'userId': userId,
        'periodId': periodId,
        'isEdit': true,
      },
    ).then((_) => _loadCurrentSettings());
  }

  // 평균 주기 길이 수정
  void _editCycleLength() {
    Navigator.pushNamed(
      context,
      '/input_cycle',
      arguments: {
        'userId': userId,
        'periodId': periodId,
        'recentStartDate': recentStartDate,
        'isEdit': true,
      },
    ).then((_) => _loadCurrentSettings());
  }

  // 생리기간 수정
  void _editPeriodDays() {
    Navigator.pushNamed(
      context,
      '/input_days',
      arguments: {
        'userId': userId,
        'periodId': periodId,
        'recentStartDate': recentStartDate,
        'cycleLength': cycleLength,
        'isEdit': true,
      },
    ).then((_) => _loadCurrentSettings());
  }

  // 추가 질문 수정
  void _editExtraData() {
    Navigator.pushNamed(
      context,
      '/input_extra',
      arguments: {
        'userId': userId,
        'periodId': periodId,
        'recentStartDate': recentStartDate,
        'cycleLength': cycleLength,
        'periodDays': periodDays,
        'isEdit': true,
      },
    ).then((_) => _loadCurrentSettings());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorTheme.mainColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorTheme.mainColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorTheme.mainColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('생리 주기 정보가 저장되었습니다.'),
                  backgroundColor: ColorTheme.mainColor,
                ),
              );
            },
            child: const Text(
              '완료',
              style: TextStyle(
                color: ColorTheme.mainColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            const Text(
              '생리 주기 설정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 최근 시작일
            _buildSettingItem(
              title: '최근 시작일',
              value: formatKoreanDate(recentStartDate),
              onTap: _editRecentStartDate,
            ),
            
            const SizedBox(height: 20),
            
            // 평균 주기 길이
            _buildSettingItem(
              title: '평균 주기 길이',
              value: cycleLength != null ? '${cycleLength}일' : '주기 설정',
              onTap: _editCycleLength,
            ),
            
            const SizedBox(height: 20),
            
            // 생리 기간
            _buildSettingItem(
              title: '생리 기간',
              value: periodDays != null ? '${periodDays}일' : '기간 설정',
              onTap: _editPeriodDays,
            ),
            
            const SizedBox(height: 20),
            
            // 추가 질문 (선택사항)
            _buildSettingItem(
              title: '(선택) 추가 질문',
              value: (extraData != null && extraData!.isNotEmpty) ? '입력 완료' : '추가 정보',
              onTap: _editExtraData,
              subtitle: _getExtraDataSubtitle(),
            ),
          ],
        ),
      ),
    );
  }

  String? _getExtraDataSubtitle() {
    List<String> infos = [];
    
    try {
      // 생리 종료일 정보
      bool hasEndDate = false;
      if (extraData != null && extraData!.containsKey('endDate') && extraData!['endDate'] != null) {
        final endDate = extraData!['endDate'];
        if (endDate is DateTime) {
          infos.add('생리 종료일: ${formatKoreanDate(endDate)}');
          hasEndDate = true;
        }
      }
      
      if (!hasEndDate) {
        infos.add('생리 종료일: 없음');
      }
      
      // 호르몬 치료 정보
      bool hasMedicationInfo = false;
      if (extraData != null && extraData!.containsKey('medication') && extraData!['medication'] != null) {
        final onMedication = extraData!['medication'];
        if (onMedication is bool) {
          infos.add('호르몬 치료: ${onMedication ? "네" : "아니오"}');
          hasMedicationInfo = true;
        }
      }
      
      if (!hasMedicationInfo) {
        infos.add('호르몬 치료: 없음');
      }
      
      return infos.join(' | ');
    } catch (e) {
      print('[SettingScreen] Error in _getExtraDataSubtitle: $e');
      return '생리 종료일: 없음 | 호르몬 치료: 없음';
    }
  }
  
  Widget _buildSettingItem({
    required String title,
    required String value,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ColorTheme.subColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ColorTheme.textGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}