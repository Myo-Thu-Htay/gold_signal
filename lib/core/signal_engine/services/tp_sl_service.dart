import 'package:flutter/foundation.dart';

import '../model/srzone_model.dart';

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
    required List<SrServiceZone> srZones,
    double minRR = 2.0,
  }) {
    // Buffer to avoid placing SL/TP too close to current price
    double buffer = atr * 0.3; // 30% of ATR as buffer
    SrServiceZone? nearestZone;
    if (isBuy) {
      // For buy trades, we want to find the nearest support zone below the current price
      nearestZone = srZones
          .where((zone) => zone.isSupport && zone.price > currentPrice)
          .fold<SrServiceZone?>(
              null,
              (prev, zone) =>
                  prev == null || zone.price < prev.price ? zone : prev);
    } else {
      // For sell trades, we want to find the nearest resistance zone above the current price
      nearestZone = srZones
          .where((zone) => !zone.isSupport && zone.price < currentPrice)
          .fold<SrServiceZone?>(
              null,
              (prev, zone) =>
                  prev == null || zone.price > prev.price ? zone : prev);
    }
    if (nearestZone == null) {
      // If we can't find a valid zone, return null
      if (kDebugMode) {
        print('No valid support/resistance zone found for TP/SL calculation.');
      }
      return null;
    }
    final entry = currentPrice;
    double sl, tp;
    if (isBuy) {
      sl = entry - buffer;
      tp = nearestZone.price - buffer;
    } else {
      sl = entry + buffer;
      tp = nearestZone.price + buffer;
    }
    final risk = (entry - sl).abs();
    final reward = (tp - entry).abs();
    if (kDebugMode) {
      print(
          'Calculated levels for ${isBuy ? 'BUY' : 'SELL'} signal: Entry: ${entry.toStringAsFixed(2)}, SL: ${sl.toStringAsFixed(2)}, TP: ${tp.toStringAsFixed(2)}, RR: ${reward / risk}');
    }
    if (risk == 0) return null;
    final rr = (reward / risk);
    if (rr < minRR) return null;

    return TradeLevels(
      entry: entry,
      stopLoss: sl,
      takeProfit: tp,
      rr: rr,
    );
  }
}
