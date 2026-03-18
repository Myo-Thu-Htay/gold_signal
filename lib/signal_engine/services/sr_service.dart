import 'dart:math';
import 'package:gold_signal/signal_engine/model/entry_zone_model.dart';

import '../model/candle.dart';
import '../model/srzone_model.dart';

class SrService {
  static List<SrServiceZone> calculateZones(
    List<Candle> candles, {
    int lookback = 300,
    double zoneTolerance = 0.5, // for XAUUSD
    int minTouches = 2,
  }) {
    final zones = <SrServiceZone>[];
    final recent = candles.sublist(max(0, candles.length - lookback));

    final swingHighs = <double>[];
    final swingLows = <double>[];

    for (int i = 2; i < recent.length - 2; i++) {
      final current = recent[i];

      // Swing High
      if (current.high > recent[i - 1].high &&
          current.high > recent[i - 2].high &&
          current.high > recent[i + 1].high &&
          current.high > recent[i + 2].high) {
        swingHighs.add(current.high);
      }

      // Swing Low
      if (current.low < recent[i - 1].low &&
          current.low < recent[i - 2].low &&
          current.low < recent[i + 1].low &&
          current.low < recent[i + 2].low) {
        swingLows.add(current.low);
      }
    }

    zones.addAll(_clusterZones(swingHighs, false, zoneTolerance, minTouches));
    zones.addAll(_clusterZones(swingLows, true, zoneTolerance, minTouches));

    return zones;
  }

  static List<SrServiceZone> _clusterZones(
    List<double> prices,
    bool isSupport,
    double tolerance,
    int minTouches,
  ) {
    final zones = <SrServiceZone>[];

    for (final price in prices) {
      bool found = false;

      for (int i = 0; i < zones.length; i++) {
        if ((zones[i].price - price).abs() <= tolerance) {
          zones[i] = SrServiceZone(
            price: (zones[i].price + price) / 2,
            touches: zones[i].touches + 1,
            isSupport: isSupport,
          );
          found = true;
          break;
        }
      }

      if (!found) {
        zones.add(SrServiceZone(
          price: price,
          touches: 1,
          isSupport: isSupport,
        ));
      }
    }

    return zones.where((z) => z.touches >= minTouches).toList();
  }

  static EntryZone getNearestZone(double price, List<SrServiceZone> zones) {
    if (zones.isEmpty) {
      return EntryZone(
          price - 0.5, price + 0.5); // Default zone if no zones found
    }
    final supports =
        zones.where((z) => z.isSupport && z.price < price).toList();
    //print('Supports: ${supports.map((s) => s.price).toList()}');
    final resistances =
        zones.where((z) => !z.isSupport && z.price > price).toList();
    //print('Resistances: ${resistances.map((r) => r.price).toList()}');
    if (supports.isEmpty && resistances.isEmpty) {
      return EntryZone(
          price - 0.5, price + 0.5); // Default zone if no zones found
    } else if (supports.isEmpty) {
      final nearestResistance = resistances.reduce(
          (a, b) => (price - a.price).abs() < (price - b.price).abs() ? a : b);
      return EntryZone(
          nearestResistance.price - 0.5, nearestResistance.price + 0.5);
    } else if (resistances.isEmpty) {
      final nearestSupport = supports.reduce(
          (a, b) => (price - a.price).abs() < (price - b.price).abs() ? a : b);
      return EntryZone(nearestSupport.price - 0.5, nearestSupport.price + 0.5);
    } else {
      final nearestSupport = supports.reduce(
          (a, b) => (price - a.price).abs() < (price - b.price).abs() ? a : b);

      final nearestResistance = resistances.reduce(
          (a, b) => (price - a.price).abs() < (price - b.price).abs() ? a : b);

      final minPrice = min(nearestSupport.price, nearestResistance.price);
      final maxPrice = max(nearestSupport.price, nearestResistance.price);
      return EntryZone(minPrice, maxPrice);
    }
  }
}
