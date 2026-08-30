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

  /// Max news articles shown (count-based, like a search results page).
  static const int _maxNewsItems = 12;

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

    // Official FRA incident records are ALWAYS kept — they're authoritative and
    // their reporting lags weeks/months, so a recency window would hide them
    // entirely. The dataset query already returns only the 10 most recent for
    // the state, newest first.
    final official = all.where((c) => c.type == 'Official').toList();

    // News articles: show the latest N (newest-first), like a Google results
    // page — a fixed count reads better than a date window, which left the
    // feed nearly empty when there was little recent coverage. Google News RSS
    // fuzzy-matches across regions and returns the same story twice, so drop
    // out-of-state items and de-duplicate by title.
    final seenTitles = <String>{};
    final news = all
        .where((c) => c.type != 'Official')
        .where((c) => _isForState(c.title, state))
        .where((c) => seenTitles.add(c.title.trim().toLowerCase()))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentNews = news.take(_maxNewsItems).toList();

    // Combine official records with the latest news, newest first.
    final filtered = [...official, ...recentNews]
      ..sort((a, b) => b.date.compareTo(a.date));

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

  /// Keeps an article if it names our state, or names no state at all (local
  /// outlets often cite only the city). Drops it only if it names a DIFFERENT
  /// state — that's how the "Iowa derailment" slipped into the NC feed.
  static bool _isForState(String title, String stateName) {
    final t = title.toLowerCase();
    if (t.contains(stateName.toLowerCase())) return true;
    for (final s in _stateNames) {
      if (s != stateName && t.contains(s.toLowerCase())) return false;
    }
    return true;
  }

  static const List<String> _stateNames = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming',
  ];

  void openLink(String url) {
    final uri = Uri.parse(url);
    launchUrl(uri);
  }
  var feedTitle = ''.obs; // <-- Add this line
}
class RailCrashService {
  /// FRA "Highway-Rail Grade Crossing Accident/Incident Source Data" dataset.
  /// The old `8vuj-3vzp` was removed by FRA (returns 404 "dataset.missing");
  /// this is the current resource (`icqf-xf4w`, updated daily). It filters by
  /// numeric state FIPS code (not 2-letter abbr) and has no single date or
  /// `cause` column — the date is built from year4/month/day and the title
  /// comes from the incident narrative.
  static const String _fraResource = 'icqf-xf4w';

  static Future<List<RailCrash>> fetchFRA(String stateAbbr) async {
    final fips = _stateFips[stateAbbr.toUpperCase()];
    if (fips == null) return [];

    final uri = Uri.parse(
      'https://data.transportation.gov/resource/$_fraResource.json'
      '?state=$fips&\$limit=10&\$order=year4 DESC, month DESC, day DESC',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    final List<RailCrash> crashes = [];
    for (final item in data) {
      crashes.add(RailCrash(
        title: _fraTitle(item, stateAbbr),
        link: 'https://data.transportation.gov/d/$_fraResource',
        source: 'FRA',
        date: _fraDate(item),
        state: stateAbbr,
        type: 'Official',
      ));
    }
    return crashes;
  }

  /// Builds a clean, readable title — severity + place — instead of the raw
  /// ALL-CAPS FRA narrative (e.g. "WTRY-J1600 CREWS WERE SERVICING…").
  static String _fraTitle(Map<String, dynamic> item, String stateAbbr) {
    num n(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;
    final killed = n(item['totkld']);
    final injured = n(item['totinj']);
    final city = _titleCase((item['city'] as String? ?? '').trim());
    final place = city.isNotEmpty ? ' in $city, $stateAbbr' : '';

    final severity = killed > 0
        ? 'Fatal railroad crossing incident'
        : injured > 0
            ? 'Injury railroad crossing incident'
            : 'Railroad crossing incident';
    return '$severity$place';
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// The dataset has no date column; reconstruct it from year4/month/day.
  static DateTime _fraDate(Map<String, dynamic> item) {
    int? p(dynamic v) =>
        v == null ? null : int.tryParse(v.toString().split('.').first);
    final y = p(item['year4']);
    final m = p(item['month']);
    final d = p(item['day']);
    if (y == null) return DateTime.now();
    return DateTime(y, (m ?? 1).clamp(1, 12), (d ?? 1).clamp(1, 28));
  }

  /// 2-letter state abbreviation → numeric FIPS code (icqf-xf4w `state` field).
  static const Map<String, String> _stateFips = {
    'AL': '1', 'AK': '2', 'AZ': '4', 'AR': '5', 'CA': '6', 'CO': '8',
    'CT': '9', 'DE': '10', 'DC': '11', 'FL': '12', 'GA': '13', 'HI': '15',
    'ID': '16', 'IL': '17', 'IN': '18', 'IA': '19', 'KS': '20', 'KY': '21',
    'LA': '22', 'ME': '23', 'MD': '24', 'MA': '25', 'MI': '26', 'MN': '27',
    'MS': '28', 'MO': '29', 'MT': '30', 'NE': '31', 'NV': '32', 'NH': '33',
    'NJ': '34', 'NM': '35', 'NY': '36', 'NC': '37', 'ND': '38', 'OH': '39',
    'OK': '40', 'OR': '41', 'PA': '42', 'RI': '44', 'SC': '45', 'SD': '46',
    'TN': '47', 'TX': '48', 'UT': '49', 'VT': '50', 'VA': '51', 'WA': '53',
    'WV': '54', 'WI': '55', 'WY': '56',
  };

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
    // Keep the state name to scope geographically, but loosen the phrasing:
    // the previous exact-phrase AND query ("$state" "railroad accident") matched
    // so little that the newest result was months old. Grouped OR terms surface
    // recent articles while the rail keywords keep out plane/car crashes.
    final q = '"$state" (train OR railroad OR railway) '
        '(accident OR derailment OR crossing OR collision OR struck)';
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