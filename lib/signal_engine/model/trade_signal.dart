
enum SignalStatus {
  active,
  tpHit,
  slHit,
  pending,
  expired,
}

class TradeSignal {
  final bool isBuy;
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double lotSize;
  final double rr;
  final int confidence;
  SignalStatus status;
  DateTime generatedAt;
  TradeSignal({
    required this.isBuy,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.lotSize,
    required this.rr,
    required this.confidence,
    this.status = SignalStatus.active,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
  factory TradeSignal.fromJson(Map<String, dynamic> json) {
    return TradeSignal(
      isBuy: json['isBuy'] as bool,
      entry: (json['entry'] as num).toDouble(),
      stopLoss: (json['stopLoss'] as num).toDouble(),
      takeProfit: (json['takeProfit'] as num).toDouble(),
      lotSize: (json['lotSize'] as num).toDouble(),
      rr: (json['rr'] as num).toDouble(),
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
      'entry': entry,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'lotSize': lotSize,
      'rr': rr,
      'confidence': confidence,
      'status': status.toString().split('.').last,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  TradeSignal copyWith({SignalStatus? status}) {
    return TradeSignal(
      isBuy: isBuy,
      entry: entry,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      lotSize: lotSize,
      rr: rr,
      confidence: confidence,
      status: status ?? this.status,
      generatedAt: generatedAt,
    );
  }
}
