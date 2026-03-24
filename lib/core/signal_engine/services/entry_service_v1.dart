import 'package:gold_signal/core/signal_engine/model/candle.dart';
import 'package:gold_signal/core/signal_engine/model/entry_zone_model.dart';
import 'package:gold_signal/core/signal_engine/services/atr_service.dart';
import 'package:gold_signal/core/signal_engine/services/signal_service.dart';
import 'package:gold_signal/core/signal_engine/services/trend_service.dart';
import '../model/srzone_model.dart';

class EntryServiceV1 {
  final TrendService _trendService = TrendService();
  final SignalService _signalService = SignalService();
  final AtrService _atrService = AtrService();
  EntryZone? buildZone({
    required double currPrice,
    required bool isBuy,
    required double atr,
    required List<SrServiceZone> srZones,
  }) {
    double zoneSize = atr * 0.5;
    SrServiceZone? baseZone;

    if (isBuy) {
      baseZone = srZones
          .where((zone) => zone.isSupport && zone.price < currPrice)
          .fold<SrServiceZone?>(
              null,
              (prev, zone) =>
                  prev == null || zone.price > prev.price ? zone : prev);
    } else {
      baseZone = srZones
          .where((zone) => !zone.isSupport && zone.price > currPrice)
          .fold<SrServiceZone?>(
              null,
              (prev, zone) =>
                  prev == null || zone.price < prev.price ? zone : prev);
    }
    if (baseZone == null) return null;
    if (isBuy) {
      return EntryZone(
        baseZone.price - zoneSize,
        baseZone.price,
        true,
      );
    } else {
      return EntryZone(
        baseZone.price,
        baseZone.price + zoneSize,
        false,
      );
    }
  }

  EntryResult evaluate({
    required List<Candle> h1,
    required List<Candle> m15,
    required List<Candle> m5,
  }) {
    if (h1.length < 50 || m15.length < 50 || m5.length < 10) {
      return EntryResult(
          isValid: false,
          reason: 'Insufficient Data',
          isBuy: false,
          entry: 0.0,
          sl: 0.0,
          tp: 0.0);
    }
    final currPrice = m5.last.close;
    final atr = _atrService.calculateATR(m15, 14);

    // 1. BIAS (Trend Layer)
    final trend = _trendService.analyzeTrend(h1);
    if (trend.direction == TrendDirection.sideways) {
      return EntryResult(
          isValid: false,
          reason: 'Neutral trend',
          isBuy: false,
          entry: 0.0,
          sl: 0.0,
          tp: 0.0);
    }

    // 2. Location (Entry Zone Layer)
    final ema = _signalService.calculateEMA(m15, 50);
    final zoneMin = ema - atr * 2;
    final zoneMax = ema + atr * 2;

    final zone =
        EntryZone(zoneMin, zoneMax, trend.direction == TrendDirection.up);

    if (!zone.contains(currPrice)) {
      return EntryResult(
          isValid: false,
          reason: 'Price outside entry zone',
          zone: zone,
          isBuy: false,
          entry: 0.0,
          sl: 0.0,
          tp: 0.0);
    }

    // 2.5 Optional Momentum Check (Filter Layer)
    // For buy signals, we want to see strong bullish momentum (e.g., a recent break above the zone with a close above the open)
    bool isMomentumBuy(List<Candle> candles, double atr) {
      final last = candles.last;
      final prev = candles[candles.length - 2];
      double move = (prev.close - last.close).abs();
      return last.close > prev.high && move < (atr * 0.3);
    }

    if (trend.direction == TrendDirection.up && isMomentumBuy(m5, atr)) {
      final last10 = m5.sublist(m5.length - 10);
      double entry = currPrice;
      double sl = last10.map((c) => c.low).reduce((a, b) => a > b ? a : b) + 2;
      double tp = entry + ((entry - sl) * 2);
      return EntryResult(
          isValid: true,
          reason: 'Bullish Momentum Detected',
          zone: zone,
          isBuy: true,
          entry: entry,
          sl: sl,
          tp: tp);
    }

    // For sell signals, we want to see strong bearish momentum (e.g., a recent break below the zone with a close below the open)
    bool isMomentumSell(List<Candle> candles, double atr) {
      final last = candles.last;
      final prev = candles[candles.length - 2];
      double move = (prev.close - last.close).abs();
      return last.close < prev.low && move > (atr * 0.3);
    }

    if (trend.direction == TrendDirection.down && isMomentumSell(m5, atr)) {
      final last10 = m5.sublist(m5.length - 10);
      double entry = currPrice;
      double sl = last10.map((c) => c.high).reduce((a, b) => a > b ? a : b) + 2;
      double tp = entry - ((sl - entry) * 2);
      return EntryResult(
          isValid: true,
          reason: 'Bearish Momentum Detected',
          zone: zone,
          isBuy: false,
          entry: entry,
          sl: sl,
          tp: tp);
    }

    // 3. Trigger (Execution Layer)
    final last = m5.last;
    final prev = m5[m5.length - 2];
    bool bullishTrigger = trend.direction == TrendDirection.up &&
        last.close > prev.high &&
        last.close > last.open;
    bool bearishTrigger = trend.direction == TrendDirection.down &&
        last.close < prev.low &&
        last.close < last.open;

    // 4 Confirmation (Trigger Layer)
    if (trend.isHealthy) {
      if (trend.direction == TrendDirection.up && bullishTrigger) {
        final last10 = m5.sublist(m5.length - 10);
        double entry = currPrice;
        double sl =
            last10.map((c) => c.low).reduce((a, b) => a > b ? a : b) + 2;
        double tp = entry + ((entry - sl) * 2);
        return EntryResult(
            isValid: true,
            reason: 'Bullish Trigger Confirmed',
            zone: zone,
            isBuy: true,
            entry: entry,
            sl: sl,
            tp: tp);
      }
      if (trend.direction == TrendDirection.down && bearishTrigger) {
        final last10 = m5.sublist(m5.length - 10);
        double entry = currPrice;
        double sl =
            last10.map((c) => c.high).reduce((a, b) => a > b ? a : b) + 2;
        double tp = entry - ((sl - entry) * 2);
        return EntryResult(
            isValid: true,
            reason: 'Bearish Trigger Confirmed',
            zone: zone,
            isBuy: false,
            entry: entry,
            sl: sl,
            tp: tp);
      }
    }
    return EntryResult(
        isValid: false,
        reason: 'Entry not Confirmed',
        zone: zone,
        isBuy: false,
        entry: currPrice,
        sl: 0.0,
        tp: 0.0);
  }
}
