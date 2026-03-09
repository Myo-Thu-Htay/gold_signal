import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/trade_history_provider.dart';
import 'account_provider.dart';

final equityCurveProvider = Provider<List<double>>((ref) {
  final trades = ref.watch(tradeHistoryProvider);
  double balance = ref.read(accountProvider).balance;
  List<double> curve = [balance];
  for (var t in trades) {
    balance += t.pnl;
    curve.add(balance);
  }
  return curve;
});