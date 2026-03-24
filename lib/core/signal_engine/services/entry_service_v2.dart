import '../model/candle.dart';
import '../model/entry_zone_model.dart';

class EntryServiceV2 {
  EntryResult evaluate({
    required List<Candle> m5,
    required double zoneMin,
    required double zoneMax,
    required int confidence,
  }) {
    final price = m5.last.close;
    final confidenceConfirmed = (confidence.abs() / 20 * 100).clamp(0, 100);
    // Sell Methods:
    bool isLiquiditySweepSell(List<Candle> m5) {
      final last = m5.last;
      final prev = m5[m5.length - 2];
      return last.high > prev.high && last.close < prev.high;
    }

    bool isFakeBreakOutSell(List<Candle> m5, double zoneMax) {
      final last = m5.last;
      final prev = m5[m5.length - 2];
      bool brokeAbove = prev.high > zoneMax;
      bool closedBelow = prev.close < zoneMax;
      bool bearishFollow = last.close < prev.close;
      return brokeAbove && closedBelow && bearishFollow;
    }

    bool isStructureShiftSell(List<Candle> m5) {
      final last = m5.last;
      final prev = m5[m5.length - 2];
      return last.close < prev.low && prev.close > prev.open;
    }

    EntryResult buildSell(List<Candle> m5, double entry, String reason) {
      final last10 = m5.sublist(m5.length - 10);
      double sl = last10.map((c) => c.high).reduce((a, b) => a > b ? a : b) + 2;
      double tp = entry - ((sl - entry) * 2);
      return EntryResult(
        isValid: true,
        isBuy: false,
        entry: entry,
        sl: sl,
        tp: tp,
        reason: reason,
      );
    }

    // Sell Logic
   if (confidenceConfirmed >= 60 && isFakeBreakOutSell(m5, zoneMax)) {
      return buildSell(m5, price, 'Fake Breakout Detected');
    }
    if (confidenceConfirmed >= 60 &&isLiquiditySweepSell(m5) && isStructureShiftSell(m5)) {
      return buildSell(m5, price, 'Liquidity Sweep and Structure Shift Detected');
    }

    // Buy Methods:
    bool isLiquiditySweepBuy(List<Candle> m5) {
      final last = m5.last;
      final prev = m5[m5.length - 2];
      return last.low < prev.low && last.close > prev.low;
    }

    bool isFakeBreakOutBuy(List<Candle> m5, double zoneMin) {
      final last = m5.last;
      final prev = m5[m5.length - 2];
      bool brokeBelow = prev.low < zoneMin;
      bool closedAbove = prev.close > zoneMin;
      bool bullishFollow = last.close > prev.close;
      return brokeBelow && closedAbove && bullishFollow;
    }

    bool isStructureShiftBuy(List<Candle> m5) {
      final last = m5.last;
      final prev = m5[m5.length - 2];
      return last.close > prev.high && prev.close < prev.open;
    }

    EntryResult buildBuy(List<Candle> m5, double entry, String reason) {
      final last10 = m5.sublist(m5.length - 10);
      double sl = last10.map((c) => c.low).reduce((a, b) => a > b ? a : b) + 2;
      double tp = entry + ((entry - sl) * 2);
      return EntryResult(
        isValid: true,
        isBuy: true,
        entry: entry,
        sl: sl,
        tp: tp,
        reason: reason,
      );
    }

    // Buy Logic
   if (confidenceConfirmed >= 60 && isFakeBreakOutBuy(m5, zoneMin)) {
      return buildBuy(m5, price, 'Fake Breakout Detected');
    }
    if (confidenceConfirmed >= 60 && isLiquiditySweepBuy(m5) && isStructureShiftBuy(m5)) {
      return buildBuy(m5, price, 'Liquidity Sweep and Structure Shift Detected');
    }

    return EntryResult(
        isValid: false,
        isBuy: false,
        entry: 0.0,
        sl: 0.0,
        tp: 0.0,
        reason: 'No valid entry pattern detected',
        zone: EntryZone(zoneMin, zoneMax, true));
  }
}
