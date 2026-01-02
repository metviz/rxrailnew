import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NotificationService {
  // ✅ SINGLETON: Use factory constructor (NO .instance needed)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ✅ SINGLE PLUGIN INSTANCE ONLY (Fixes your main issue)
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final FlutterTts flutterTts = FlutterTts();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Fixed icon path

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // ✅ Initialize SINGLE plugin instance
    await notificationsPlugin.initialize(initializationSettings);

    // ✅ Create channels ONCE
    await _createNotificationChannels();
    print('✅ NotificationService initialized');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const locationChannel = AndroidNotificationChannel(
      'location_channel',
      'Location Tracking',
      description: 'Persistent location tracking notification',
      importance: Importance.low,
      playSound: false,
    );

    const alertChannel = AndroidNotificationChannel(
      'railwaycrossingalerts', // Fixed: Match your showNotifications channel
      'Railway Crossing Alerts',
      importance: Importance.high,
      playSound: true,
    );

    await androidPlugin?.createNotificationChannel(locationChannel);
    await androidPlugin?.createNotificationChannel(alertChannel);
  }

  // ✅ FIXED: Use SINGLE notificationsPlugin instance
  Future<void> showPersistentNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Tracking',
      channelDescription: 'Persistent location tracking notification',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      enableLights: false,
      enableVibration: false,
      playSound: false,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // ✅ Use notificationsPlugin (not flutterLocalNotificationsPlugin)
    await notificationsPlugin.show(0, title, body, notificationDetails);
  }

  // ✅ FIXED: Channel name matches creation + SINGLE plugin
  Future<void> showNotifications(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'railwaycrossingalerts', // Fixed: Matches channel creation
      'Railway Crossing Alerts',
      channelDescription: 'High priority alerts for nearby railway crossings',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> speak(String text) async {
    try {
      await flutterTts.stop();
      await flutterTts.speak(text);
    } catch (e) {
      print('Error in TTS: $e');
    }
  }
}
