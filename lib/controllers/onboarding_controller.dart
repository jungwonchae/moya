import 'package:get/get.dart';
import '../screens/input_info/input_info_name_screen.dart';
import '../screens/input_info/input_info_nick_screen.dart';
import '../screens/input_period/input_period_recent_screen.dart';
import '../screens/input_period/input_period_cycle_screen.dart';
import '../screens/input_period/input_period_days_screen.dart';
import '../screens/input_period/input_period_extra_screen.dart';
import '../screens/input_ble/input_ble_initial_screen.dart';
import '../screens/usage/usage_first_screen.dart';
import '../screens/usage/usage_second_screen.dart';
import '../screens/usage/usage_third_screen.dart';
import '../screens/home/home_screen.dart';
import 'menstrual_controller.dart';

class OnboardingController extends GetxController {
  var currentStep = 0.obs;
  var userName = ''.obs;
  var nickName = ''.obs;
  var recentPeriodDate = Rx<DateTime?>(null);
  var cycleLength = 28.obs;
  var periodDays = 5.obs;
  var extraInfo = ''.obs;
  var isBluetoothSetup = false.obs;
  
  // 온보딩 단계별 네비게이션
  void navigateToStep(int step) {
    currentStep.value = step;
    switch (step) {
      case 1:
        Get.to(() => InputInfoNameScreen());
        break;
      case 2:
        Get.to(() => InputInfoNickScreen());
        break;
      case 3:
        Get.to(() => InputPeriodRecentScreen());
        break;
      case 4:
        Get.to(() => InputPeriodCycleScreen());
        break;
      case 5:
        Get.to(() => InputPeriodDaysScreen());
        break;
      case 6:
        Get.to(() => InputPeriodExtraScreen());
        break;
      case 7:
        Get.to(() => InputBleInitialScreen());
        break;
      case 8:
        Get.to(() => UsageFirstScreen());
        break;
      case 9:
        Get.to(() => UsageSecondScreen());
        break;
      case 10:
        Get.to(() => UsageThirdScreen());
        break;
      default:
        // 온보딩 완료 -> 홈으로 이동
        completeOnboarding();
    }
  }
  
  void nextStep() {
    navigateToStep(currentStep.value + 1);
  }
  
  void completeOnboarding() {
    // 데이터 저장
    Get.find<MenstrualController>().initializeWithOnboardingData();
    Get.offAll(() => HomeScreen());
  }
}