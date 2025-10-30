import 'dart:convert';

import 'package:RXrail/app/model/SafetyVideoModel.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/blog_post_model.dart';
import '../../../model/blog_update_model.dart';
import '../../../model/safety_tip_model.dart';

class BlogController extends GetxController {
  final RxList<BlogPost> featuredPosts = <BlogPost>[].obs;
  final RxList<SafetyTip> safetyTips = <SafetyTip>[].obs;
  final RxList<BlogUpdate> updates = <BlogUpdate>[].obs;
  final RxList<SafetyVideoModel> safetyVideos = <SafetyVideoModel>[].obs;
  final RxBool isLoadingVideos = false.obs;
  @override
  void onInit() {
    super.onInit();
    loadData();
    loadSafetyVideos();
  }

  void loadData() {
    // Load featured posts
    featuredPosts.value = [
      BlogPost(
        title: "Railway Safety Awareness",
        description: "Learn about the importance of railway safety and how to stay safe around train tracks.",
        author: "Sarah Miller",
        imageUrl: "assets/images/railway_main.jpg",
      ),
    ];

    // Load safety tips
    safetyTips.value = [
      SafetyTip(
        title: "Crossing Safety",
        description: "Always look both ways before crossing railway tracks, even if the signals are not active.",
        imageUrl: "assets/images/railway_crossing.jpg",
      ),
      SafetyTip(
        title: "Emergency Procedures",
        description: "In case of an emergency at a railway crossing, know who to contact and what information to provide.",
        imageUrl: "assets/images/railway_emergency.jpg",
      ),
    ];

    // Load updates
    updates.value = [
      BlogUpdate(
        title: "New Crossing Alerts",
        description: "We've added new railway crossing alerts in your area. Stay informed and stay safe.",
        imageUrl: "assets/images/railway_alerts.jpg",
      ),
    ];
  }

  Future<void> loadSafetyVideos() async {
    try {
      isLoadingVideos.value = true;

      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/data/rail_safety_videos.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      // Parse JSON data to SafetyVideo objects
      safetyVideos.value = jsonData
          .map((json) => SafetyVideoModel.fromJson(json))
          .toList();

      isLoadingVideos.value = false;
    } catch (e) {
      print('Error loading safety videos: $e');
      isLoadingVideos.value = false;
    }
  }
  Future<void> openVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void onBackPressed() {
    Get.back();
  }
}
