import 'package:flutter/foundation.dart';
import '../../core/constants/trading_constants.dart';
import '../model/multi_timeframe_model.dart';
import 'atr_service.dart';
import 'signal_service.dart';
import 'tp_sl_service.dart';
import '../model/trade_signal.dart';
import 'risk_service.dart';

class SignalEngine {
  final RiskService _riskService = RiskService();
  final SignalService _signalService = SignalService();
  final AtrService _atrService = AtrService();

  Future<TradeSignal> evaluate(MultiTimeFrameModel candles,
      double accountBalance, double riskPercent) async {
    int confidence = _signalService.calculateConfidence(candles);
    final signal = _signalService.generateSignal(candles, confidence);
    if (signal == 'HOLD') {
      return holdSignal(confidence);
    }
    final h1 = candles.h1;
    final m5 = candles.m5;
    final currPrice = m5.last.close;
    final atr = _atrService.calculateATR(h1, TradingConstants.atrPeriod);
    final trade = TpSlService.calculateLevels(
      currentPrice: currPrice,
      isBuy: signal.contains('Buy'),
      atr: atr,
    );
    if (trade == null) {
      // If we can't calculate valid trade levels, return a hold signal
      if (kDebugMode) {
        print('Could not calculate valid trade levels, returning HOLD signal.');
      }
      return holdSignal(confidence);
    }
    final lot = _riskService.calculateLotSize(
        balance: accountBalance,
        entry: trade.entry,
        riskPercent: riskPercent,
        stopLoss: trade.stopLoss);
    final entry = trade.entry;
    final sl = trade.stopLoss;
    final tp = trade.takeProfit;
    
    return TradeSignal(
      isBuy: signal.contains('Buy'),
      entry: entry,
      stopLoss: sl,
      takeProfit: tp,
      lotSize: lot,
      rr: trade.rr,
      confidence: confidence,
      status: SignalStatus.pending,
      generatedAt: DateTime.now(),
    );
  }

  // Helper holdSignal function
  TradeSignal holdSignal(int confidence) {
    return TradeSignal(
      isBuy: false,
      entry: 0.0,
      stopLoss: 0.0,
      takeProfit: 0.0,
      lotSize: 0.0,
      rr: 0.0,
      confidence: confidence,
      status: SignalStatus.expired,
      generatedAt: DateTime.now(),
    );
  }
}
