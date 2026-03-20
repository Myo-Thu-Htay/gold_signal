import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/trade_signal.dart';

final signalProvider =
    StateNotifierProvider<SignalProviderNotifier, TradeSignal?>(
        (ref) => SignalProviderNotifier());

class SignalProviderNotifier extends StateNotifier<TradeSignal?> {
  SignalProviderNotifier() : super(null){
    loadSignals();
  }

  static const _storageKey = 'active_signals';

  Future<TradeSignal> loadSignals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    state = data != null
        ? TradeSignal.fromJson(jsonDecode(data))
        : TradeSignal(
            status: SignalStatus.expired,
            entry: 0,
            stopLoss: 0,
            takeProfit: 0,
            isBuy: false,
            lotSize: 0,
            confidence: 0,
            rr: 0);
    return state!;
  }

  Future<void> saveSignal(TradeSignal signal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(signal.toJson()));
    state = signal;
  }

  Future<void> updateSignal(TradeSignal signal) async {
    await saveSignal(signal);
  }

  Future<void> clearSignal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = null;
  }
}
