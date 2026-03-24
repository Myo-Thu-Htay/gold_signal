import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'account_provider.dart';
import 'trade_history_provider.dart';

class EquityData {
  final DateTime time;
  final double equity;
  final Color color;

  EquityData(this.time, this.equity, this.color);
}

final equityChartProvider = Provider<List<EquityData>>((ref) {
  final trades = ref.watch(tradeHistoryProvider);
  final initialBalance = ref.read(accountProvider).initialBalance;
  double balance = initialBalance;
  List<EquityData> data = [];

  for (int i = 0; i < trades.length; i++) {
    final trade = trades[i];
    if (!trade.isOpen && trade.pnl != 0) {
      balance += trade.pnl;
    }
    Color color;
    if (data.isEmpty) {
      color = Colors.blue;
    } else {
      color = data.first.equity < data.last.equity ? Colors.red : Colors.green;
    }
    data.add(EquityData(
      trade.exitTime!,
      balance,
      color,
    ));
  }
  return data.length > 10 ? data.sublist(data.length - 10) : data;
});
