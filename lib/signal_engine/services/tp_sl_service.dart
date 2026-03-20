import 'package:flutter/foundation.dart';

class TradeLevels {
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double rr;

  TradeLevels({
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.rr,
  });
}

class TpSlService {
  static TradeLevels? calculateLevels({
    required double currentPrice,
    required bool isBuy,
    required double atr,
    double minRR = 2.0,
  }) {
    // Buffer to avoid placing SL/TP too close to current price
    if (isBuy) {
      final entry = currentPrice; // Entry at the upper boundary of the zone
      final sl = entry - atr; // Subtracting a small buffer to the support level
      final tp = entry +
          (atr * 2); // Subtracting a small buffer from the resistance level
      final risk = (entry - sl).abs();
      final reward = (tp - entry).abs();

      if (risk == 0) return null;

      final rr = (reward / risk).roundToDouble();
      if (kDebugMode) {
        print(
            'Calculated levels for ${isBuy ? 'BUY' : 'SELL'} signal: Entry: ${entry.toStringAsFixed(2)}, SL: ${sl.toStringAsFixed(2)}, TP: ${tp.toStringAsFixed(2)}, RR: ${rr.toStringAsFixed(2)}');
      }
      if (rr < minRR) return null;

      return TradeLevels(
        entry: entry,
        stopLoss: sl,
        takeProfit: tp,
        rr: rr,
      );
    } else {
      final entry = currentPrice; // Entry at the lower boundary of the zone
      final sl = entry + atr; // Adding a small buffer to the resistance level
      final tp =
          entry - (atr * 2); // Adding a small buffer to the support level

      final risk = (sl - entry).abs();
      final reward = (entry - tp).abs();
      if (kDebugMode) {
        print(
            'Calculated levels for ${isBuy ? 'BUY' : 'SELL'} signal: Entry: ${entry.toStringAsFixed(2)}, SL: ${sl.toStringAsFixed(2)}, TP: ${tp.toStringAsFixed(2)}, RR: ${reward / risk}');
      }
      if (risk == 0) return null;
      final rr = (reward / risk).roundToDouble();
      if (rr < minRR) return null;

      return TradeLevels(
        entry: entry,
        stopLoss: sl,
        takeProfit: tp,
        rr: rr,
      );
    }
  }
}
