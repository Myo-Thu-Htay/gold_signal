import 'package:gold_signal/signal_engine/model/trade_signal.dart';

class SignalValidator {
  static const int expiryMinutes = 60; // Example expiry time for signals
  static TradeSignal validateSignal(TradeSignal signal, double currentPrice) {
    
    double maxMove = (signal.takeProfit - signal.entry).abs() * 0.5; // 50% of expected move
    
    // Trigger entry
    if (signal.status == SignalStatus.pending && signal.entryZone.contains(currentPrice)) {
      return signal.copyWith(status: SignalStatus.active);
    }

    // Active signal validation
    if (signal.status == SignalStatus.active) {
      if (signal.isBuy) {
        if (currentPrice >= signal.takeProfit) {
          return signal.copyWith(status: SignalStatus.tpHit);
        } else if (currentPrice <= signal.stopLoss) {
          return signal.copyWith(status: SignalStatus.slHit);
        }
      } else {
        if (currentPrice <= signal.takeProfit) {
          return signal.copyWith(status: SignalStatus.tpHit);
        } else if (currentPrice >= signal.stopLoss) {
          return signal.copyWith(status: SignalStatus.slHit);
        }
      }
    }
    //Missed Entry Validation
    if (signal.isBuy && currentPrice > signal.entry + maxMove) {
      return signal.copyWith(status: SignalStatus.invalid); // Missed buy entry
    } 
    if (!signal.isBuy && currentPrice < signal.entry - maxMove) { 
      return signal.copyWith(status: SignalStatus.invalid); // Missed sell entry
    }
     if (DateTime.now().difference(signal.generatedAt).inMinutes >
          expiryMinutes) {
        signal = signal.copyWith(status: SignalStatus.expired);
      } // Expiry Validation
    return signal;
  }
}