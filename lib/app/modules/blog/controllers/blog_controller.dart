import 'dart:convert';

import 'package:RXrail/app/model/SafetyVideoModel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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

  // Targeted queries — use quoted phrases + official source names to avoid news clips
  static const List<String> _searchQueries = [
    '"Operation Lifesaver" "railroad crossing safety"',
    '"FRA" "railroad safety" education',
    '"USDOT" "train safety" PSA',
    '"railroad crossing" safety awareness training',
  ];

  // Only keep videos from official/educational channels
  static bool _isOfficialSafetyVideo(String title, String channelTitle) {
    final t = title.toLowerCase();
    final c = channelTitle.toLowerCase();

    // Drop news channels
    final newsKeywords = ['news', 'wlox', ' abc ', 'cbs', ' nbc ', 'fox news',
        'cnn', 'reporter', 'breaking', 'herald', 'tribune', 'wsoc', 'wral'];
    if (newsKeywords.any((k) => c.contains(k))) return false;

    // Drop clickbait / incident titles that aren't educational
    final dropTitles = ['arrested', 'shocking', 'you won\'t believe',
        'this happened in seconds', 'caught on camera', 'dashcam'];
    if (dropTitles.any((k) => t.contains(k))) return false;

    // Must mention rail AND safety/awareness/education/training
    final hasRail = t.contains('train') || t.contains('railroad') ||
        t.contains('railway') || t.contains('rail') || t.contains('crossing');
    final hasSafety = t.contains('safety') || t.contains('awareness') ||
        t.contains('education') || t.contains('training') ||
        t.contains('psa') || t.contains('prevent') || t.contains('lifesaver') ||
        c.contains('lifesaver') || c.contains('fra') || c.contains('dot') ||
        c.contains('usdot') || c.contains('ntsb') || c.contains('railroad');

    return hasRail && hasSafety;
  }

  Future<void> loadSafetyVideos() async {
    try {
      isLoadingVideos.value = true;

      // Load static curated videos from assets
      final String jsonString = await rootBundle.loadString('assets/data/rail_safety_videos.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final staticVideos = jsonData.map((j) => SafetyVideoModel.fromJson(j)).toList();

      // Fetch latest from YouTube API in parallel
      final futures = _searchQueries.map(_fetchYouTubeSearch);
      final results = await Future.wait(futures);
      final liveVideos = results.expand((v) => v).toList();

      // Deduplicate live results by videoId
      final seenIds = <String>{};
      final dedupedLive = liveVideos.where((v) => seenIds.add(v.videoId)).toList();

      // Remove any live video already in static list
      final staticIds = staticVideos.map((v) => v.videoId).toSet();
      final newLive = dedupedLive.where((v) => !staticIds.contains(v.videoId)).toList();

      // Sort live videos newest first
      newLive.sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });

      // Live videos first, then curated static list
      safetyVideos.value = [...newLive, ...staticVideos];
    } catch (e) {
      print('Error loading safety videos: $e');
    } finally {
      isLoadingVideos.value = false;
    }
  }

  static Future<List<SafetyVideoModel>> _fetchYouTubeSearch(String query) async {
    final apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    if (apiKey.isEmpty) return [];

    final uri = Uri(
      scheme: 'https',
      host: 'www.googleapis.com',
      path: '/youtube/v3/search',
      queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'order': 'date',
        'maxResults': '10',
        'relevanceLanguage': 'en',
        'regionCode': 'US',
        'key': apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        print('YouTube API error ${response.statusCode}: ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];
      final List<SafetyVideoModel> videos = [];
      int idBase = query.hashCode.abs() % 9000 + 1000;

      for (final item in items) {
        final videoId = item['id']?['videoId'] as String? ?? '';
        if (videoId.isEmpty) continue;

        final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
        final title = snippet['title'] as String? ?? '';
        final channelTitle = snippet['channelTitle'] as String? ?? '';

        // Drop news clips and non-educational content
        if (!_isOfficialSafetyVideo(title, channelTitle)) continue;
        final publishedAt = snippet['publishedAt'] as String? ?? '';
        final thumbnail =
            snippet['thumbnails']?['high']?['url'] as String? ??
            snippet['thumbnails']?['default']?['url'] as String? ??
            'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

        videos.add(SafetyVideoModel(
          id: idBase++,
          title: title,
          source: channelTitle,
          duration: '',
          url: 'https://www.youtube.com/watch?v=$videoId',
          embed: 'https://www.youtube.com/embed/$videoId',
          thumbnail: thumbnail,
          publishedAt: DateTime.tryParse(publishedAt),
        ));
      }
      return videos;
    } catch (e) {
      print('Error fetching YouTube search "$query": $e');
      return [];
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
