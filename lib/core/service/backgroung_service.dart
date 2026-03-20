import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:gold_signal/core/api/binance_api_service.dart';
import 'package:gold_signal/core/api/market_repository_impl.dart';
import 'package:gold_signal/signal_engine/model/trade_signal.dart';
import 'package:gold_signal/signal_engine/services/signal_engine.dart';
import 'package:gold_signal/signal_engine/services/signal_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/service/notification_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: 'gold_signal_channel',
      initialNotificationTitle: 'Gold Signal Service',
      initialNotificationContent: 'Analyzing market data in the background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final prefs = await SharedPreferences.getInstance();
  double accountBalance = prefs.getDouble('account_balance') ?? 10000;
  final riskPercent = prefs.getDouble('account_risk') ?? 1;
  final engine = SignalEngine();
  final api = BinanceApiService();
  final repo = MarketRepositoryImpl(binanceApiService: api);
  DateTime? lastCandleTime;
  Timer.periodic(const Duration(seconds: 20), (timer) async {
    try {
      final candles = await repo.getBinanceCandles();
      final latestCandle = candles.m5.last;
      final latestTime = latestCandle.time;
      final lastTIme = lastCandleTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (lastCandleTime != null && !latestTime.isAfter(lastTIme)) {
        return; // No new candle, skip processing
      }
      lastCandleTime = latestTime;
      final signal =
          await engine.evaluate(candles, accountBalance, riskPercent);
      final validSignal =
          SignalValidator.validateSignal(signal, candles.m5.last.close);
      if (validSignal.status != SignalStatus.expired) {
        if (kDebugMode) {
          print('Pending signal detected, waiting for confirmation...');
        }
        await prefs
            .setStringList('valid_signals', [jsonEncode(validSignal.toJson())]);
      }
      if (validSignal.status == SignalStatus.active) {
        service.invoke('update_signal', {
          'signal': validSignal.toJson(),
        }); // Send signal to the main app
        await prefs.setString(
            'active_signals',
            jsonEncode(validSignal
                .toJson())); // Store or update the signal in local storage
        final newId =
            "${validSignal.isBuy}_${validSignal.stopLoss.round()}_${validSignal.takeProfit.round()}";
        final exits = prefs.getString('signal_ids');
        if (newId != exits) {
          bool isOn = prefs.getBool('notificationsEnabled') ?? true;
          prefs.setString('signal_ids', newId); // Update the stored signal ID
          if (isOn) {
            NotificationService.showNotification(
                title: "New ${signal.isBuy ? 'Buy' : 'Sell'} Signal",
                body:
                    "Entry: ${signal.entry.toStringAsFixed(2)}, SL: ${signal.stopLoss.toStringAsFixed(2)}, TP: ${signal.takeProfit.toStringAsFixed(2)},Lot: ${signal.lotSize.toStringAsFixed(2)},Confidence: ${(signal.confidence.abs() / 20 * 100).clamp(0, 100).toStringAsFixed(0)}%, RR: 1:${((signal.takeProfit - signal.entry).abs() / (signal.entry - signal.stopLoss).abs()).toStringAsFixed(0)}");
          }
        }
      } else {
        final lastStatus = prefs.getString('latest_signal_status');
        if (validSignal.status.toString() != SignalStatus.active.toString()) {
          final newStatus = validSignal.status.toString();
          if (lastStatus != newStatus) {
            bool isOn = prefs.getBool('notificationsEnabled') ?? true;
            if (isOn) {
              NotificationService.showNotification(
                  title:
                      "Signal ${validSignal.status.toString().split('.').last.toUpperCase()}",
                  body:
                      "Status: ${validSignal.status.toString().split('.').last.toUpperCase()} ${validSignal.isBuy ? 'BUY' : 'SELL'} at ${validSignal.entry.toStringAsFixed(2)} with confidence ${(validSignal.confidence.abs() / 20 * 100).clamp(0, 100).toStringAsFixed(0)}%");
            }
            await prefs.setString('latest_signal_status',
                newStatus); // Update the stored signal status
          }
        }
        await prefs.remove('active_signals'); // Remove expired/invalid signal
      }
      if (kDebugMode) {
        print(
            'Signal status: ${validSignal.status.toString().split('.').last.toUpperCase()} ${validSignal.isBuy ? 'BUY' : 'SELL'} at  Entry: ${validSignal.entry.toStringAsFixed(2)}  SL: ${validSignal.stopLoss.toStringAsFixed(2)} TP: ${validSignal.takeProfit.toStringAsFixed(2)} Lot: ${validSignal.lotSize.toStringAsFixed(2)} with confidence ${(validSignal.confidence.abs() / 20 * 100).clamp(0, 100).toStringAsFixed(0)}%');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in background service: $e');
        print('Stack trace: $stackTrace');
      }
    }
  });
}
