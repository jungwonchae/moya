import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/menstrual_controller.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/camera_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/setting_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // 앱 전체에서 사용되는 컨트롤러들
    Get.put(AuthController(), permanent: true);
    Get.lazyPut(() => OnboardingController(), fenix: true);
    Get.lazyPut(() => MenstrualController(), fenix: true);
    Get.lazyPut(() => BluetoothController(), fenix: true);
    Get.lazyPut(() => CameraController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);
    Get.lazyPut(() => SettingController(), fenix: true);
  }
}