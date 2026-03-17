import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/core/theme/app_theme.dart';
import 'package:gold_signal/dashboard/provider/controller_provider.dart';
import 'package:gold_signal/dashboard/provider/setting_provider.dart';
import 'package:gold_signal/signal_engine/provider/signal_provider.dart';
import 'package:gold_signal/signal_engine/provider/signal_validator_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/routing/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dashboard/provider/market_stream_provider.dart';
import 'signal_engine/model/trade_signal.dart';
import 'signal_engine/provider/market_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  StreamSubscription? service;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    service = FlutterBackgroundService().on('update_signal').listen((event) {
      if (event != null && event['signal'] != null) {
        final signalData = event['signal'] as Map<String, dynamic>;
        final signal = TradeSignal.fromJson(signalData);
        ref.read(signalProvider.notifier).state = signal;
        ref.read(signalValidatorProvider.notifier).addSignal(signal);
      }
    });
    _loadInitialSignal();
    Future.microtask(() {
      ref.read(marketStreamProvider);
      ref.read(signalValidatorProvider);
    });
  }

  Future<void> _loadInitialSignal() async {
    final prefs = await SharedPreferences.getInstance();
    final signalJson = prefs.getString('latest_signal');
    if (signalJson != null) {
      final signalMap = jsonDecode(signalJson) as Map<String, dynamic>;
      final signal = TradeSignal.fromJson(signalMap);
      ref.read(signalProvider.notifier).state = signal;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    service?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(selectedTimeframeProvider);
        ref.read(binanceCandlesProvider);
        ref.read(getBinanceCandles);
        ref.read(marketStreamProvider);
        ref.read(controllerProvider);
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        cleanupResources();
        break;
      default:
        break;
    }
  }

  void cleanupResources() {
    // Clean up any resources or subscriptions here
    ref.invalidate(marketStreamProvider);
    ref.invalidate(binanceCandlesProvider);
    ref.invalidate(getBinanceCandles);
    ref.invalidate(selectedTimeframeProvider);
    ref.invalidate(controllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settingAsync = ref.watch(settingsProvider);
    return settingAsync.when(
      data: (setting) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          themeMode: setting.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: Locale(setting.languageCode),
          supportedLocales: const [
            Locale('en'),
            Locale('my'),
          ],
          localizationsDelegates: const [
            // AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerDelegate: AppRouter.delegate,
          routeInformationParser: AppRouter.parser,
        );
      },
      error: (error, stackTrace) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Text('Error loading settings'),
            ),
          ),
        );
      },
      loading: () {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
