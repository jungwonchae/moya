import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/period_data.dart';

enum PeriodPhase {
  beforePeriod,  // 시작 전
  onPeriod,      // 생리중
  safe,          // 보송보송
  warning,       // 곧 교체 시간
  needChange     // 교체 필요
}

class MenstrualController extends GetxController {
  // 사용자 기본 정보
  var userName = ''.obs;
  var nickName = ''.obs;
  
  // 생리 주기 데이터
  var recentStartDate = Rx<DateTime?>(null);
  var cycleLength = 28.obs;
  var periodDays = 5.obs;
  var currentDay = 0.obs;
  var daysUntilNext = 0.obs;
  
  // 실시간 상태
  var currentPhase = PeriodPhase.beforePeriod.obs;
  var changeCount = 0.obs;
  var lastChangeTime = Rx<DateTime?>(null);
  var timeSinceLastChange = ''.obs;
  var statusMessage = '아직은 시작 전이에요!'.obs;
  
  // 생리 데이터 히스토리
  var periodHistory = <PeriodData>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUserData();
    startRealTimeUpdates();
  }
  
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    userName.value = prefs.getString('userName') ?? '';
    nickName.value = prefs.getString('nickName') ?? '';
    cycleLength.value = prefs.getInt('cycleLength') ?? 28;
    periodDays.value = prefs.getInt('periodDays') ?? 5;
    changeCount.value = prefs.getInt('todayChangeCount') ?? 0;
    
    String? startDateStr = prefs.getString('recentStartDate');
    if (startDateStr != null) {
      recentStartDate.value = DateTime.parse(startDateStr);
    }
    
    String? lastChangeStr = prefs.getString('lastChangeTime');
    if (lastChangeStr != null) {
      lastChangeTime.value = DateTime.parse(lastChangeStr);
    }
    
    calculateCurrentStatus();
  }
  
  Future<void> saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('userName', userName.value);
    await prefs.setString('nickName', nickName.value);
    await prefs.setInt('cycleLength', cycleLength.value);
    await prefs.setInt('periodDays', periodDays.value);
    await prefs.setInt('todayChangeCount', changeCount.value);
    
    if (recentStartDate.value != null) {
      await prefs.setString('recentStartDate', recentStartDate.value!.toIso8601String());
    }
    
    if (lastChangeTime.value != null) {
      await prefs.setString('lastChangeTime', lastChangeTime.value!.toIso8601String());
    }
  }
  
  void calculateCurrentStatus() {
    if (recentStartDate.value == null) return;
    
    DateTime now = DateTime.now();
    DateTime startDate = recentStartDate.value!;
    
    // 현재 주기 내에서 몇일째인지 계산
    currentDay.value = now.difference(startDate).inDays;
    
    if (currentDay.value < 0) {
      // 아직 시작 전
      currentPhase.value = PeriodPhase.beforePeriod;
      daysUntilNext.value = -currentDay.value;
      statusMessage.value = '아직은 시작 전이에요!';
    } else if (currentDay.value < periodDays.value) {
      // 생리 중
      currentPhase.value = PeriodPhase.onPeriod;
      daysUntilNext.value = periodDays.value - currentDay.value;
      updatePeriodStatusMessage();
    } else {
      // 생리 후
      int daysSinceEnd = currentDay.value - periodDays.value;
      int daysUntilNextPeriod = cycleLength.value - currentDay.value;
      
      if (daysUntilNextPeriod <= 0) {
        // 다음 주기 시작
        currentPhase.value = PeriodPhase.onPeriod;
        daysUntilNext.value = periodDays.value;
      } else {
        currentPhase.value = PeriodPhase.beforePeriod;
        daysUntilNext.value = daysUntilNextPeriod;
        statusMessage.value = '곧 생리주기가 돌아와요!';
      }
    }
  }
  
  void updatePeriodStatusMessage() {
    if (lastChangeTime.value == null) {
      statusMessage.value = '교체 기록이 없어요';
      timeSinceLastChange.value = '';
      return;
    }
    
    DateTime now = DateTime.now();
    Duration difference = now.difference(lastChangeTime.value!);
    
    if (difference.inMinutes < 60) {
      timeSinceLastChange.value = '${difference.inMinutes}분 전';
      if (difference.inMinutes <= 30) {
        statusMessage.value = '아직은 보송보송 해요';
        currentPhase.value = PeriodPhase.safe;
      } else {
        statusMessage.value = '곧 교체할 시간이 다가와요';
        currentPhase.value = PeriodPhase.warning;
      }
    } else if (difference.inHours < 24) {
      timeSinceLastChange.value = '${difference.inHours}시간 전';
      if (difference.inHours <= 3) {
        statusMessage.value = '곧 교체할 시간이 다가와요';
        currentPhase.value = PeriodPhase.warning;
      } else {
        statusMessage.value = '교체가 필요해요';
        currentPhase.value = PeriodPhase.needChange;
      }
    } else {
      timeSinceLastChange.value = '${difference.inDays}일 전';
      statusMessage.value = '교체가 필요해요';
      currentPhase.value = PeriodPhase.needChange;
    }
  }
  
  void recordChange() {
    changeCount.value++;
    lastChangeTime.value = DateTime.now();
    updatePeriodStatusMessage();
    saveUserData();
    
    Get.snackbar(
      '교체 기록',
      '교체가 기록되었습니다. (${changeCount.value}회)',
      snackPosition: SnackPosition.TOP,
    );
  }
  
  void startRealTimeUpdates() {
    // 1분마다 상태 업데이트
    Stream.periodic(Duration(minutes: 1)).listen((_) {
      calculateCurrentStatus();
      if (currentPhase.value == PeriodPhase.onPeriod) {
        updatePeriodStatusMessage();
      }
    });
  }
  
  void initializeWithOnboardingData() {
    final onboarding = Get.find<OnboardingController>();
    userName.value = onboarding.userName.value;
    nickName.value = onboarding.nickName.value;
    recentStartDate.value = onboarding.recentPeriodDate.value;
    cycleLength.value = onboarding.cycleLength.value;
    periodDays.value = onboarding.periodDays.value;
    
    calculateCurrentStatus();
    saveUserData();
  }
  
  // 데이터 분석용 메서드들
  List<PeriodData> getPeriodHistory() {
    return periodHistory.toList();
  }
  
  double getAverageCycleLength() {
    if (periodHistory.length < 2) return cycleLength.value.toDouble();
    
    double total = 0;
    for (int i = 1; i < periodHistory.length; i++) {
      total += periodHistory[i].startDate.difference(periodHistory[i-1].startDate).inDays;
    }
    return total / (periodHistory.length - 1);
  }
  
  int getAveragePeriodDays() {
    if (periodHistory.isEmpty) return periodDays.value;
    
    double total = periodHistory.map((p) => p.durationDays).reduce((a, b) => a + b).toDouble();
    return (total / periodHistory.length).round();
  }
}