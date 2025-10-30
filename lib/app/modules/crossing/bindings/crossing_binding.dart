import 'package:RXrail/app/modules/setting/controllers/setting_controller.dart';
import 'package:get/get.dart';

import '../controllers/crossing_controller.dart';

class CrossingBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<CrossingController>();
    Get.find<SettingController>();
  }
}
