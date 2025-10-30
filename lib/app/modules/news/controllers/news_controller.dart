import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../../../model/news_items.dart';

class NewsController extends GetxController {
  final RxList<NewsItem> newsItems = <NewsItem>[
    NewsItem(
      title: "Train Derailment Near Willow Creek",
      description: "A freight train derailed near Willow Creek, causing significant delays. No injuries reported.",
      imageAsset: "assets/images/train1.png",
      alertType: "Safety Alert",
    ),
    NewsItem(
      title: "Crossing Malfunction in Maplewood",
      description: "A crossing gate malfunctioned in Maplewood, leading to a temporary road closure. Repairs are underway.",
      imageAsset: "assets/images/train2.png",
      alertType: "Safety Alert",
    ),
    NewsItem(
      title: "Increased Train Traffic in Riverbend",
      description: "Expect increased train traffic in Riverbend due to track maintenance. Plan for potential delays.",
      imageAsset: "assets/images/train3.png",
      alertType: "Safety Alert",
    ),
  ].obs;

  // final String state;
  // NewsController(this.state);

  var crashes = <RailCrash>[].obs;
  var loading = true.obs;

  late String state;
  @override
  void onInit() {
    super.onInit();
    // ✅ Get state argument
    state = Get.arguments?['state'] ?? 'CA'; // default fallback
    fetchCrashes();
  }

  Future<void> fetchCrashes() async {
    loading.value = true;
    final data = await RailCrashService.fetchCombined(state);
    // Fetch combined crashes and feed title
    final result = await RailCrashService.fetchCombinedWithTitle(state);
    crashes.assignAll(data);
    feedTitle.value = result['feedTitle']; // <-- set it here
    print("result['feedTitle']-----------${result['feedTitle']}");
    loading.value = false;
  }

  void openLink(String url) {
    final uri = Uri.parse(url);
    launchUrl(uri);
  }
  var feedTitle = ''.obs; // <-- Add this line
}
class RailCrashService {
  /// FRA open dataset: https://data.transportation.gov/resource/8vuj-3vzp.json
  /// (Railroad Equipment Accident/Incident Source Data)
  static Future<List<RailCrash>> fetchFRA(String state) async {
    final uri = Uri.parse(
      'https://data.transportation.gov/resource/8vuj-3vzp.json?\$limit=10&state_ab=${Uri.encodeComponent(state)}',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final List<RailCrash> crashes = [];

    for (final item in data) {
      crashes.add(RailCrash(
        title: item['cause'] ?? 'Railroad Incident',
        link: 'https://data.transportation.gov/resource/8vuj-3vzp.json',
        source: 'FRA',
        date: DateTime.tryParse(item['accidentdate'] ?? '') ?? DateTime.now(),
        state: item['state_ab'] ?? state,
        type: 'Official',
      ));
    }
    return crashes;
  }

  static Future<List<RailCrash>> fetchGoogleNews(String state) async {
    final query =
        'train+derailment+OR+train+crash+OR+railroad+accident+$state+when:24h';
        // 'train+derailment+$state';
    final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$query&hl=en-US&gl=US&ceid=US:en');

    print("URL--------------------${uri.toString()}");
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    final List<RailCrash> crashes = [];

    for (final item in items) {
      final title = item.getElement('title')?.text ?? 'Untitled';
      final link = item.getElement('link')?.text ?? '';
      final pubDate = item.getElement('pubDate')?.text ?? '';
      final source = item.getElement('source')?.text ?? 'Google News';

      // ✅ Try to extract thumbnail URL
      // final mediaThumb =
      //     item.findElements('media:thumbnail').firstOrNull?.getAttribute('url') ??
      //         item.findElements('media:content').firstOrNull?.getAttribute('url') ??
      //         '';

      DateTime parsedDate = DateTime.now();

      try {
        parsedDate = HttpDate.parse(pubDate).toLocal(); // converts to local time
      } catch (_) {
        parsedDate = DateTime.now();
      }

      crashes.add(RailCrash(
        title: title,
        link: link,
        source: source,
        date: parsedDate,
        state: state,
        type: 'News',
        // imageUrl: mediaThumb, // ✅ add this
      ));
    }

    return crashes;
  }

  /// Combine both sources
  static Future<List<RailCrash>> fetchCombined(String state) async {
    final fra = await fetchFRA(state);
    final news = await fetchGoogleNews(state);
    return [...fra, ...news];
  }

  static Future<Map<String, dynamic>> fetchCombinedWithTitle(String state) async {
    final fra = await fetchFRA(state);
    final newsResult = await fetchGoogleNewsWithTitle(state);
    final combined = [...fra, ...newsResult['crashes']];

    return {
      'crashes': combined,
      'feedTitle': newsResult['feedTitle'],
    };
  }
  static Future<Map<String, dynamic>> fetchGoogleNewsWithTitle(String state) async {
    final query =
        'train+derailment+OR+train+crash+OR+railroad+accident+$state'
        ''
        ''
        '';
        // 'train+derailment+$state';
    final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$query&hl=en-US&gl=US&ceid=US:en');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return {'crashes': [], 'feedTitle': ''};
    }

    final document = XmlDocument.parse(response.body);
    final feedTitle = document.getElement('rss')?.getElement('channel')?.getElement('title')?.text ?? '';
    final items = document.findAllElements('item');
    final List<RailCrash> crashes = [];

    for (final item in items) {
      final title = item.getElement('title')?.text ?? 'Untitled';
      final link = item.getElement('link')?.text ?? '';
      final pubDate = item.getElement('pubDate')?.text ?? '';
      final source = item.getElement('source')?.text ?? 'Google News';

      final mediaThumb =
          item.findElements('media:thumbnail').firstOrNull?.getAttribute('url') ??
              item.findElements('media:content').firstOrNull?.getAttribute('url') ??
              '';

      DateTime parsedDate = DateTime.now();
      try {
        parsedDate = DateTime.parse(pubDate);
      } catch (_) {}

      crashes.add(RailCrash(
        title: title,
        link: link,
        source: source,
        date: parsedDate,
        state: state,
        type: 'News',






        imageUrl: mediaThumb,
      ));
    }

    return {'crashes': crashes, 'feedTitle': feedTitle};
  }
}

class RailCrash {
  final String title;
  final String link;
  final String source;
  final DateTime date;
  final String state;
  final String type;
  final String imageUrl; // ✅ new field

  RailCrash({
    required this.title,
    required this.link,
    required this.source,
    required this.date,
    required this.state,
    required this.type,
    this.imageUrl = '', // optional
  });
}