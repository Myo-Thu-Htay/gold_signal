import 'dart:math';
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

      for (final zone in zones) {
        if ((price >= zone.price - tolerance && price <= zone.price + tolerance)) {
          // Update existing zone
          final newMin = min(zone.price - tolerance, price);
          final newMax = max(zone.price + tolerance, price);
          final newCenter = (newMin + newMax) / 2;
          zones.remove(zone);
          zones.add(SrServiceZone(
            price: newCenter,
            touches: zone.touches + 1,
            isSupport: isSupport,
          ));
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
}
