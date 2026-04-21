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
  late String stateAbbr;

  @override
  void onInit() {
    super.onInit();
    final raw = Get.arguments?['state'] ?? 'North Carolina';
    state = raw;
    stateAbbr = _toStateAbbr(raw);
    fetchCrashes();
  }

  Future<void> fetchCrashes() async {
    loading.value = true;
    final result = await RailCrashService.fetchCombinedWithTitle(state, stateAbbr);
    final all = result['crashes'] as List<RailCrash>;
    feedTitle.value = result['feedTitle'] as String;

    final now = DateTime.now();

    List<RailCrash> filtered = all
        .where((c) => now.difference(c.date).inDays <= 14)
        .toList();

    // Extend to 30 days if nothing in the past 2 weeks
    if (filtered.isEmpty) {
      filtered = all
          .where((c) => now.difference(c.date).inDays <= 30)
          .toList();
    }

    // If still nothing, show all available results
    if (filtered.isEmpty) {
      filtered = List.of(all);
    }

    // Sort latest first
    filtered.sort((a, b) => b.date.compareTo(a.date));

    crashes.assignAll(filtered);
    loading.value = false;
  }

  /// Convert full state name OR 2-letter abbreviation to 2-letter abbreviation.
  static String _toStateAbbr(String input) {
    const map = {
      'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR',
      'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT',
      'Delaware': 'DE', 'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI',
      'Idaho': 'ID', 'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA',
      'Kansas': 'KS', 'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME',
      'Maryland': 'MD', 'Massachusetts': 'MA', 'Michigan': 'MI',
      'Minnesota': 'MN', 'Mississippi': 'MS', 'Missouri': 'MO',
      'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
      'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM',
      'New York': 'NY', 'North Carolina': 'NC', 'North Dakota': 'ND',
      'Ohio': 'OH', 'Oklahoma': 'OK', 'Oregon': 'OR', 'Pennsylvania': 'PA',
      'Rhode Island': 'RI', 'South Carolina': 'SC', 'South Dakota': 'SD',
      'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT', 'Vermont': 'VT',
      'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
      'Wisconsin': 'WI', 'Wyoming': 'WY',
    };
    if (input.length == 2) return input.toUpperCase();
    return map[input] ?? input.toUpperCase().substring(0, 2);
  }

  void openLink(String url) {
    final uri = Uri.parse(url);
    launchUrl(uri);
  }
  var feedTitle = ''.obs; // <-- Add this line
}
class RailCrashService {
  /// FRA open dataset — uses 2-letter state abbreviation
  static Future<List<RailCrash>> fetchFRA(String stateAbbr) async {
    final uri = Uri.parse(
      'https://data.transportation.gov/resource/8vuj-3vzp.json?\$limit=10&state_ab=${Uri.encodeComponent(stateAbbr)}',
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
        state: item['state_ab'] ?? stateAbbr,
        type: 'Official',
      ));
    }
    return crashes;
  }

  static Future<Map<String, dynamic>> fetchCombinedWithTitle(String state, String stateAbbr) async {
    final fra = await fetchFRA(stateAbbr);
    final newsResult = await fetchGoogleNewsWithTitle(state);
    final combined = [...fra, ...newsResult['crashes'] as List<RailCrash>];

    return {
      'crashes': combined,
      'feedTitle': newsResult['feedTitle'],
    };
  }

  static Future<Map<String, dynamic>> fetchGoogleNewsWithTitle(String state) async {
    // Use Uri constructor so queryParameters are properly encoded.
    // Quoted state name requires it to appear; "railroad accident" OR "train derailment"
    // avoids matching plane/car crashes.
    final q = '"$state" "railroad accident" OR "$state" "train derailment" OR "$state" "railroad crossing"';
    final uri = Uri(
      scheme: 'https',
      host: 'news.google.com',
      path: '/rss/search',
      queryParameters: {'q': q, 'hl': 'en-US', 'gl': 'US', 'ceid': 'US:en'},
    );
    print('📰 News URL: $uri');
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
        parsedDate = HttpDate.parse(pubDate).toLocal();
      } catch (_) {}

      // Client-side filter: skip articles unrelated to railroads
      if (!_isRailroadArticle(title)) continue;

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

  static bool _isRailroadArticle(String title) {
    final t = title.toLowerCase();
    return t.contains('train') ||
        t.contains('railroad') ||
        t.contains('railway') ||
        t.contains('derail') ||
        t.contains('freight') ||
        t.contains('amtrak') ||
        t.contains('rail crossing') ||
        t.contains('crossing gate');
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