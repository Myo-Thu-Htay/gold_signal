import 'package:gold_signal/signal_engine/model/entry_zone_model.dart';

class Entryservice {

  static EntryZone emaZone(double ema50,{double tolerance = 0.5}) {
    double lower = ema50 - tolerance;
    double upper = ema50 + tolerance;
    return EntryZone(lower, upper);
  }

  static EntryZone mergeZones(EntryZone zone1, EntryZone zone2) {
    double lower = zone1.min > zone2.min ? zone1.min : zone2.min;
    double upper = zone1.max < zone2.max ? zone1.max : zone2.max;
    return EntryZone(lower, upper);
  }
}