import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

import '../controllers/disclaimer_controller.dart';

class DisclaimerView extends GetView<DisclaimerController> {
  const DisclaimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left:16.w,right: 16.w,top: 16.w),
              child: Text(
                'Disclaimer & Terms of Use',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal:16.w),
                child: SingleChildScrollView(
                  child: Text(
                    'The RXRail App uses publicly available, community-sourced data from OpenStreetMap and OpenRailwayMap to provide information on railroad crossings and track locations. '
                    'While every effort is made to ensure accuracy, RXRail does not guarantee that the data is fully current or error-free.\n\n'
                    'By using this application, you agree that RXRail and its contributors assume no liability for any loss, injury, or damage—whether direct, indirect, incidental, consequential, special, or exemplary—arising from the use of the app or the information it provides.\n\n'
                    'In the event of an emergency near a railroad crossing, users should immediately contact the railroad emergency number posted at the crossing site or local emergency services.',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // ✅ Checkbox Row
            Obx(
              () => Row(
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: controller.isChecked.value,
                      activeColor: Colors.amberAccent,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        controller.isChecked.value = val ?? false;
                      },
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Terms and Conditions.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ✅ Next Button (disabled until checked)
            Obx(
              () => Padding(
                padding:  EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.isChecked.value
                            ? controller.acceptTerms
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          controller.isChecked.value
                              ? Colors.green
                              : Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color:
                            controller.isChecked.value
                                ? Colors.white
                                : Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
