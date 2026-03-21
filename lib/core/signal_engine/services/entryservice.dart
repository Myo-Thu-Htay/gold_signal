import 'package:gold_signal/core/signal_engine/model/srzone_model.dart';

import '../model/candle.dart';
import '../model/entry_zone_model.dart';

class EntrySignal {
  final double entryPrice;
  final bool isBuy;
  final String type; // "retest" or "pullback"
  EntrySignal({
    required this.entryPrice,
    required this.isBuy,
    required this.type,
  });
}

class EntryZoneservice {
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

  bool confirmEntry({required List<Candle> candles, required EntryZone zone}) {
    final last = candles.last;
    final prev = candles[candles.length - 2];
    // For buy signals, we want the price to dip into the zone and then close above the previous candle's close.
    if (zone.isBuy) {
      return zone.contains(last.low) && last.close > prev.close;
    }
    // For sell signals, we want the price to spike into the zone and then close below the previous candle's close.
    if (!zone.isBuy) {
      return zone.contains(last.high) && last.close < prev.close;
    }
    return false;
  }

  EntrySignal? findEntry({
    required List<Candle> candles,
    required List<SrServiceZone> zones,
    required bool isBuy,
  }) {
    final last = candles.last;
    final prev = candles[candles.length - 2];
    for (final zone in zones) {
      // For buy signals, we want to see a break and retest of a support zone
      if (zone.isSupport && isBuy) {
        bool broke = prev.close > zone.price;
        bool retest = last.low <= zone.price;
        bool rejection = last.close > zone.price;
        if (broke && retest && rejection) {
          return EntrySignal(
            entryPrice: zone.price,
            isBuy: true,
            type: 'retest',
          );
        }
      }
      // For sell signals, we want to see a break and retest of a resistance zone
      if (!zone.isSupport && !isBuy) {
        bool broke = prev.close < zone.price;
        bool retest = last.high >= zone.price;
        bool rejection = last.close < zone.price;
        if (broke && retest && rejection) {
          return EntrySignal(
            entryPrice: zone.price,
            isBuy: false,
            type: 'retest',
          );
        }
      }
    }
    return null;
  }
}
