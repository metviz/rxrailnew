import 'package:get/get.dart';

import '../controllers/crossing_detail_controller.dart';

class CrossingDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CrossingDetailController>(
      () => CrossingDetailController(),
    );
  }
}
