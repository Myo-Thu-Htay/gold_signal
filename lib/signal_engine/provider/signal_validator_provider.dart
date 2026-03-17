import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gold_signal/dashboard/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/trade_signal.dart';
import '../services/signal_validator.dart';

final signalValidatorProvider =
    StateNotifierProvider<SignalValidatorNotifier, List<TradeSignal>>((ref) {
  return SignalValidatorNotifier();
});

class SignalValidatorNotifier extends StateNotifier<List<TradeSignal>> {
  SignalValidatorNotifier() : super([]) {
    loadSignals();
  } // Initialize with an empty list of signals

  static const _storageKey = 'trade_signals';

  void loadSignals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? [];
    state = data.map((e) => TradeSignal.fromJson(jsonDecode(e))).toList();
  }

  Future<void> saveSignals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> addSignal(TradeSignal signal) async {
    final prefs = await SharedPreferences.getInstance();
    final newId =
        "${signal.entry}_${signal.stopLoss}_${signal.takeProfit}_${signal.generatedAt.millisecondsSinceEpoch}";
    final exits = state.any((s) {
      final id =
          "${s.entry}_${s.stopLoss}_${s.takeProfit}_${s.generatedAt.millisecondsSinceEpoch}";
      return id == newId;
    });
    if (exits) {
      return; // Skip adding duplicate signal
    }
    state = [...state, signal];
    bool isOn = prefs.getBool('notificationsEnabled') ?? true;
    if (isOn) {
      NotificationService.showNotification(
          title: "New ${signal.isBuy ? 'Buy' : 'Sell'} Signal",
          body:
              "Entry: ${signal.entry}, SL: ${signal.stopLoss}, TP: ${signal.takeProfit},Lot: ${signal.lotSize},Confidence: ${signal.confidence}");
    }
    await saveSignals();
  }

  void validateSignal(double currentPrice) {
    final updatedSignal = state.map((signal) {
      return SignalValidator.validateSignal(signal, currentPrice);
    }).toList();
    state =
        updatedSignal.where((s) => s.status == SignalStatus.active).toList();
    saveSignals();
  }
}
