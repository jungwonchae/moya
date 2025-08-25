import 'package:get/get.dart';
import '../screens/ondevice/ondevice_camera_screen.dart';
import '../screens/ondevice/ondevice_loading_screen.dart';
import '../screens/ondevice/ondevice_result_screen.dart';
import 'menstrual_controller.dart';
import 'notification_controller.dart';

class CameraController extends GetxController {
  var isProcessing = false.obs;
  var hasBloodStain = false.obs;
  var analysisResult = ''.obs;
  var confidence = 0.0.obs;
  
  // AI 분석 플로우
  void startAnalysis() {
    Get.to(() => OndeviceCameraScreen());
  }
  
  Future<void> processImage(String imagePath) async {
    isProcessing.value = true;
    Get.to(() => OndeviceLoadingScreen());
    
    try {
      // AI 분석 수행
      await Future.delayed(Duration(seconds: 3)); // 실제로는 AI 모델 실행
      
      // 결과 생성 (예시)
      hasBloodStain.value = true; // 또는 false
      confidence.value = 0.85;
      
      if (hasBloodStain.value) {
        analysisResult.value = '혈자국이 있어요!\n지금 교체가 필요해요';
        // 교체 기록 업데이트
        Get.find<MenstrualController>().recordChange();
      } else {
        analysisResult.value = '혈자국이 없어요!\n혈이 아니에요, 안심하세요';
      }
      
      // 결과 화면으로 이동
      Get.off(() => OndeviceResultScreen());
      
    } catch (e) {
      Get.snackbar('오류', '분석 중 문제가 발생했습니다.');
    } finally {
      isProcessing.value = false;
    }
  }
  
  void retryAnalysis() {
    Get.back(); // 결과 화면에서 뒤로
    Get.to(() => OndeviceCameraScreen()); // 카메라 화면으로
  }
}