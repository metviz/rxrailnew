// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotifications(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'crossing_alerts_channel', // Changed from 'location_channel'
      'Crossing Alerts',
      channelDescription: 'Alerts for nearby railway crossings',
      importance: Importance.high, // Changed from low
      priority: Priority.high, // Changed from low
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'crossing_alert',
    );
  }
  final FlutterTts flutterTts = FlutterTts();
  Future<void> speak(String text) async {
    try {
      await flutterTts.stop();
      await flutterTts.speak(text);
    } catch (e) {
      print('Error in TTS: $e');
    }
  }
}