import 'package:flutter/foundation.dart';
import '../../constants/trading_constants.dart';
import '../model/multi_timeframe_model.dart';
import 'atr_service.dart';
import 'entryservice.dart';
import 'signal_service.dart';
import 'sr_service.dart';
import 'tp_sl_service.dart';
import '../model/trade_signal.dart';
import 'risk_service.dart';

class SignalEngine {
  final RiskService _riskService = RiskService();
  final SignalService _signalService = SignalService();
  final AtrService _atrService = AtrService();
  final EntryZoneservice _entryZoneService = EntryZoneservice();
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
    final zone = SrService.calculateZones(h1);
    final entryZone = _entryZoneService.buildZone(
      currPrice: currPrice,
      isBuy: signal.contains('Buy'),
      atr: atr,
      srZones: zone,
    );
    if (entryZone == null) {
      // If we can't build a valid entry zone, return a hold signal
      if (kDebugMode) {
        print('Could not build a valid entry zone, returning HOLD signal.');
      }
      return holdSignal(confidence);
    }
    bool entryConfirmed =
        _entryZoneService.confirmEntry(candles: m5, zone: entryZone);
    if (!entryConfirmed) {
      // If the entry is not confirmed, return a hold signal
      if (kDebugMode) {
        print('Entry not confirmed, returning HOLD signal.');
      }
      return holdSignal(confidence);
    }
    if(entryConfirmed){
      if (kDebugMode) {
        print('Entry confirmed, proceeding to calculate trade levels.');
      }
      confidence += 4; // Increase confidence if entry is confirmed
    }
    final entrySignal = _entryZoneService.findEntry(
        candles: m5, zones: zone, isBuy: entryZone.isBuy);
    if (entrySignal == null) {
      // If we can't find a valid entry signal, return a hold signal
      if (kDebugMode) {
        print('Could not find a valid entry signal, returning HOLD signal.');
      }
      return holdSignal(confidence);
    }
    final entryPrice = entrySignal.entryPrice;
    final trade = TpSlService.calculateLevels(
      currentPrice: entryPrice,
      isBuy: entrySignal.isBuy,
      atr: atr,
      srZones: zone,
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
