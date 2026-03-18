import 'package:gold_signal/signal_engine/model/entry_zone_model.dart';

enum SignalStatus {
  active,
  tpHit,
  slHit,
  pending,
  expired,
  invalid,
}

class TradeSignal {
  final bool isBuy;
  final EntryZone entryZone;
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double lotSize;
  final int confidence;
  SignalStatus status;
  DateTime generatedAt;
  TradeSignal({
    required this.isBuy,
    required this.entryZone,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.lotSize,
    required this.confidence,
    this.status = SignalStatus.active,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
  factory TradeSignal.fromJson(Map<String, dynamic> json) {
    return TradeSignal(
      isBuy: json['isBuy'] as bool,
      entryZone: json['entryZone'] != null
          ? EntryZone.fromJson(json['entryZone'] as Map<String, dynamic>) 
          : EntryZone(0, 0),
      entry: (json['entry'] as num).toDouble(),
      stopLoss: (json['stopLoss'] as num).toDouble(),
      takeProfit: (json['takeProfit'] as num).toDouble(),
      lotSize: (json['lotSize'] as num).toDouble(),
      confidence: json['confidence'] as int,
      status: SignalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SignalStatus.active,
      ),
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isBuy': isBuy,
      'entryZone': entryZone.toJson(),
      'entry': entry,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'lotSize': lotSize,
      'confidence': confidence,
      'status': status.toString().split('.').last,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  TradeSignal copyWith({SignalStatus? status}) {
    return TradeSignal(
      isBuy: isBuy,
      entryZone: entryZone,
      entry: entry,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      lotSize: lotSize,
      confidence: confidence,
      status: status ?? this.status,
      generatedAt: generatedAt,
    );
  }
}
