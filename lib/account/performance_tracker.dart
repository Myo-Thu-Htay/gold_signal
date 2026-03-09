import 'package:shared_preferences/shared_preferences.dart';

import '../dashboard/models/trade_model.dart';


class PerformanceTracker {
  final List<Trade> trades = [];

  void addTrade(Trade trade) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    trades.add(trade);
    prefs.setStringList(
        'trade_history', trades.map((t) => t.toJson().toString()).toList());
  }

  int get totalTrades => trades.length;
  int get win => trades.where((t) => t.isWin).length;
  int get losses => trades.where((t) => !t.isWin).length;

  double get winRate => totalTrades == 0 ? 0 : (win / totalTrades) * 100;
  double get totalPnL => trades.fold(0, (sum, trade) => sum + trade.pnl);
}
