import 'package:gold_signal/signal_engine/model/trade_signal.dart';

class SignalValidator {
  //static const int expiryMinutes = 60; // Example expiry time for signals
  static TradeSignal validateSignal(TradeSignal signal, double currentPrice) {
    double buyMaxMove =
        (signal.takeProfit - signal.entry).abs() * 0.7; // 70% of expected move
    double sellMaxMove =
        (signal.entry - signal.takeProfit).abs() * 0.7; // 70% of expected move
    // Trigger entry
    if (signal.status == SignalStatus.pending &&
        (signal.isBuy ? signal.entry <= currentPrice : signal.entry >= currentPrice)) {
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
    if (signal.isBuy && currentPrice > signal.entry + buyMaxMove) {
      return signal.copyWith(status: SignalStatus.expired); // Missed buy entry
    }
    if (!signal.isBuy && currentPrice < signal.entry - sellMaxMove) {
      return signal.copyWith(status: SignalStatus.expired); // Missed sell entry
    }

    return signal;
  }
}
