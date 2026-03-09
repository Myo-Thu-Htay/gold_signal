import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trade_model.dart';

final tradeHistoryProvider =
    StateNotifierProvider<TradeHistoryNotifier, List<Trade>>(
  (ref) => TradeHistoryNotifier(),
);

class TradeHistoryNotifier extends StateNotifier<List<Trade>> {
  TradeHistoryNotifier() : super([]) {
    _loadTrades();
  }

  static const _storageKey = 'trade_history';

  /* ----------------------------- STORAGE ----------------------------- */

  Future<void> _loadTrades() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? [];

    state = data.map((e) => Trade.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveTrades() async {
    final prefs = await SharedPreferences.getInstance();

    final data = state.map((e) => jsonEncode(e.toJson())).toList();

    await prefs.setStringList(_storageKey, data);
  }

  /* ----------------------------- CRUD ----------------------------- */

  Future<void> addTrade(Trade trade) async {
    state = [...state, trade];
    await _saveTrades();
  }

  Future<void> deleteTrade(int index) async {
    final updated = [...state]..removeAt(index);
    state = updated;
    await _saveTrades();
  }

  Future<void> deleteTradeByTime(DateTime entryTime) async {
    final updated = state.where((t) => t.entryTime != entryTime).toList();
    state = updated;
    await _saveTrades();
  }

  Future<void> clearTrades() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /* ----------------------------- ADD MANUAL TRADE ----------------------------- */

  Future<void> addManualTrade({
    required bool isBuy,
    required double entry,
    required double exit,
    required double sl,
    required double tp,
    required double lot,
    required DateTime entryTime,
    required DateTime exitTime,
    required bool isOpen,
  }) async {
    final pnl = _calculatePnL(isBuy, entry, exit, lot);
    final isWin = _isWinningTrade(isBuy, entry, exit);

    final trade = Trade(
      isBuy: isBuy,
      entry: entry,
      stopLoss: sl,
      takeProfit: tp,
      lotSize: lot,
      entryTime: entryTime,
      exitPrice: exit,
      exitTime: exitTime,
      pnl: pnl,
      isWin: isWin,
      type: isBuy ? "BUY" : "SELL",
      isOpen: isOpen,
    );

    await addTrade(trade);
  }

  Future<void> updateTrade(Trade updatedTrade) async {
    final index = state.indexWhere((t) => t.entryTime == updatedTrade.entryTime);
    if (index != -1) {
      final updatedList = [...state];
      updatedList[index] = updatedTrade;
      state = updatedList;
      await _saveTrades();
    }
  }

  /* ----------------------------- CALCULATIONS ----------------------------- */

  double _calculatePnL(bool isBuy, double entry, double exit, double lot) {
    return isBuy ? (exit - entry) * lot * 100 : (entry - exit) * lot * 100;
  }

  bool _isWinningTrade(bool isBuy, double entry, double exit) {
    return isBuy ? exit > entry : exit < entry;
  }

  /* ----------------------------- STATS ----------------------------- */

  double get totalPnL => state.fold(0, (sum, trade) => sum + trade.pnl);

  double get winRate {
    if (state.isEmpty) return 0;

    final wins = state.where((t) => t.isWin).length;
    return (wins / state.length) * 100;
  }

  int get totalTrades => state.length;

  /*----------2️⃣ Auto TP/SL Detection Function------------*/
  
  void checkTradeAutoClose(double currentPrice) {
    state = state.map((trade) {
      if (!trade.isOpen) return trade;

      bool hitTP = false;
      bool hitSL = false;

      if (trade.isBuy) {
        hitTP = currentPrice >= trade.takeProfit;
        hitSL = currentPrice <= trade.stopLoss;
      } else {
        hitTP = currentPrice <= trade.takeProfit;
        hitSL = currentPrice >= trade.stopLoss;
      }

      if (!hitTP && !hitSL) {
        final livePnl = trade.isBuy
            ? (currentPrice - trade.entry) * trade.lotSize * 100
            : (trade.entry - currentPrice) * trade.lotSize * 100;
        return trade.copyWith(
          pnl: livePnl,
        );
      }
      final exitPrice = hitTP ? trade.takeProfit : trade.stopLoss;
      final pnl = trade.isBuy
          ? (exitPrice - trade.entry) * trade.lotSize * 100
          : (trade.entry - exitPrice) * trade.lotSize * 100;
      return trade.copyWith(
        exitPrice: currentPrice,
        exitTime: DateTime.now(),
        pnl: pnl,
        isWin: hitTP,
        isOpen: false,
      );
    }).toList();
  }
}
