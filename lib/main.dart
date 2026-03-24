import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/core/signal_engine/services/backgroung_service.dart';
import 'core/error/global_error_handler.dart';
import 'core/config/app_config.dart';
import 'dashboard/app.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    AppConfig.initialize();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gold_signal_channel', // id
      'Gold Signal Notifications', // title
      description:
          'This channel is used for Gold Signal notifications.', // description
      importance: Importance.low, // Set to low to avoid sound and vibration
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await initializeService();
    runApp(const ProviderScope(child: MyApp()));
  }, GlobalErrorHandler.handle);
}
