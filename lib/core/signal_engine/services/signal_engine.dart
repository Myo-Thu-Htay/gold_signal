import 'package:flutter/foundation.dart';
import 'package:gold_signal/core/signal_engine/model/entry_zone_model.dart';
import 'package:gold_signal/core/signal_engine/services/entry_service_v2.dart';
import '../../constants/trading_constants.dart';
import '../model/multi_timeframe_model.dart';
import 'atr_service.dart';
import 'entry_service_v1.dart';
import 'signal_service.dart';
import 'sr_service.dart';
import '../model/trade_signal.dart';
import 'risk_service.dart';

class SignalEngine {
  final RiskService _riskService = RiskService();
  final SignalService _signalService = SignalService();
  final AtrService _atrService = AtrService();
  final EntryServiceV1 _entryServiceV1 = EntryServiceV1();
  final EntryServiceV2 _entryServiceV2 = EntryServiceV2();
  Future<TradeSignal> evaluate(MultiTimeFrameModel candles,
      double accountBalance, double riskPercent) async {
    int confidence = _signalService.calculateConfidence(candles);
    final signal = _signalService.generateSignal(candles, confidence);
    if (signal == 'HOLD') {
      return holdSignal(confidence, reason: 'Generated HOLD signal');
    }
    final h1 = candles.h1;
    //final m15 = candles.m15;
    final m5 = candles.m5;
    final currPrice = m5.last.close;
    final atr = _atrService.calculateATR(h1, TradingConstants.atrPeriod);
    final zone = SrService.calculateZones(h1);
    final entryZone = _entryServiceV1.buildZone(
      currPrice: currPrice,
      isBuy: signal.contains('Buy'),
      atr: atr,
      srZones: zone,
    );
    if (kDebugMode) {
      print('Generated signal: $signal with confidence: $confidence');
      print('Current Price: $currPrice, ATR: $atr');
      print(
          'Calculated SR Zones: ${zone.length}, SrZone: ${entryZone != null ? 'Max: ${entryZone.max.toStringAsFixed(2)} - Min: ${entryZone.min.toStringAsFixed(2)}' : 'None'}');
    }
    if (entryZone == null) {
      // If we can't build a valid entry zone, return a hold signal
      if (kDebugMode) {
        print('Could not build a valid entry zone, returning HOLD signal.');
      }
      return holdSignal(confidence, reason: 'Invalid entry zone');
    }
    if ((signal == 'Strong Buy' && confidence > 10) ||
        (signal == 'Strong Sell' && confidence > -10)) {
      final EntryResult entryResult = _entryServiceV2.evaluate(
        m5: candles.m5,
        zoneMin: entryZone.min,
        zoneMax: entryZone.max,
        confidence: confidence,
      );
      if (!entryResult.isValid) {
        if (kDebugMode) {
          print(
              'EntryServiceV2 did not confirm the signal, reason: ${entryResult.reason}, returning HOLD signal.');
        }
        return holdSignal(confidence, reason: entryResult.reason);
      }
      if (entryResult.isValid) {
        confidence += entryResult.isBuy
            ? 4
            : -4; // Adjust confidence based on V2 confirmation
      }
      final entry = entryResult.entry != 0.0
          ? entryResult.entry
          : currPrice; // Use entry price if provided, otherwise use current price
      final sl = entryResult.sl;
      final tp = entryResult.tp;
      final minRR = 2.0; // Minimum acceptable Risk-Reward ratio
      final lot = _riskService.calculateLotSize(
          balance: accountBalance,
          entry: entry,
          riskPercent: riskPercent,
          stopLoss: entryResult.sl);
      final rr = signal.contains('Strong Buy')
          ? ((tp - entry) / (entry - sl)).abs()
          : ((entry - tp) / (sl - entry)).abs();
      if (rr < minRR) {
        if (kDebugMode) {
          print(
              'Calculated RR ($rr) is below minimum threshold ($minRR), returning HOLD signal.');
        }
        return holdSignal(confidence, reason: 'RR below minimum threshold');
      }
      // Use the entry result from V2
      return TradeSignal(
        isBuy: entryResult.isBuy,
        entry: entry,
        stopLoss: sl,
        takeProfit: tp,
        lotSize: lot,
        rr: rr,
        confidence: confidence,
        status: SignalStatus.pending,
        generatedAt: DateTime.now(),
        reason: entryResult.reason,
      );
    }
    final entrySignal = _entryServiceV1.evaluate(
      h1: candles.h1,
      m15: candles.m15,
      m5: candles.m5,
    );
    if (!entrySignal.isValid) {
      // If the entry is not Valid, return a hold signal
      if (kDebugMode) {
        print(
            '${entrySignal.reason},EmaZone: ${entrySignal.zone != null ? 'Min: ${entrySignal.zone!.min.toStringAsFixed(2)} - Max: ${entrySignal.zone!.max.toStringAsFixed(2)}' : 'Invalid'}, returning HOLD signal.');
      }
      return holdSignal(confidence, reason: entrySignal.reason);
    }
    if (entrySignal.isValid) {
      confidence += entrySignal.isBuy ? 4 : -4; // Increase confidence if entry is confirmed
      if (kDebugMode) {
        print('Entry Valid, proceeding to calculate trade levels.');
        print(
            'Entry evaluation result: ${entrySignal.reason}, Entry Confirmed: ${entrySignal.isValid} EmaZone: Min: ${entrySignal.zone!.min.toStringAsFixed(2)} - Max: ${entrySignal.zone!.max.toStringAsFixed(2)}');
      }
    }
    final minRR = 2.0; // Minimum acceptable Risk-Reward ratio
    final entry = entrySignal.entry != 0.0
        ? entrySignal.entry
        : currPrice; // Use entry price if provided, otherwise use current price
    final sl = entrySignal.sl;
    final tp = entrySignal.tp;
    final lot = _riskService.calculateLotSize(
        balance: accountBalance,
        entry: entry,
        riskPercent: riskPercent,
        stopLoss: entrySignal.sl);
    final rr = signal.contains('Buy')
        ? ((tp - entry) / (entry - sl)).abs()
        : ((entry - tp) / (sl - entry)).abs();
    if (rr < minRR) {
      if (kDebugMode) {
        print(
            'Calculated RR ($rr) is below minimum threshold ($minRR), returning HOLD signal.');
      }
      return holdSignal(confidence, reason: 'RR below minimum threshold');
    }
    return TradeSignal(
      isBuy: signal.contains('Buy'),
      entry: entry,
      stopLoss: sl,
      takeProfit: tp,
      lotSize: lot,
      rr: rr,
      confidence: confidence,
      status: SignalStatus.pending,
      generatedAt: DateTime.now(),
      reason: entrySignal.reason,
    );
  }

  // Helper holdSignal function
  TradeSignal holdSignal(int confidence, {String? reason}) {
    return TradeSignal(
      isBuy: false,
      entry: 0.0,
      stopLoss: 0.0,
      takeProfit: 0.0,
      lotSize: 0.0,
      rr: 0.0,
      confidence: confidence,
      status: SignalStatus.pending,
      generatedAt: DateTime.now(),
      reason: reason,
    );
  }
}
