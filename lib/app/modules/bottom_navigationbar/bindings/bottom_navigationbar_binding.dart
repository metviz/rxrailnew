
import 'package:get/get.dart';
import '../../crossing/controllers/crossing_controller.dart';
import '../../setting/controllers/setting_controller.dart';
import '../controllers/bottom_navigationbar_controller.dart';

class BottomNavigationbarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomNavigationbarController>(
          () => BottomNavigationbarController(),
    );
    Get.find<CrossingController>(
    );
    Get.find<SettingController>(

    );
  }
}