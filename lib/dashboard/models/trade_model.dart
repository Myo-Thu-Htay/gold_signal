class Trade {
  final bool isBuy;
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double lotSize;
  final double? exitPrice;
  final DateTime entryTime;
  final DateTime? exitTime;
  double pnl;
  bool isWin;
  final String type;
  bool isOpen;

  Trade({
    required this.isBuy,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.lotSize,
    required this.entryTime,
    this.exitPrice,
    this.exitTime,
    this.pnl = 0.0,
    this.isWin = false,
    required this.type,
    this.isOpen = true,
  });
  Trade copyWith({
    double? exitPrice,
    DateTime? exitTime,
    double? pnl,
    bool? isWin,
    bool? isOpen,
  }) {
    return Trade(
      isBuy: isBuy,
      entry: entry,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      lotSize: lotSize,
      entryTime: entryTime,
      exitPrice: exitPrice ?? this.exitPrice,
      exitTime: exitTime ?? this.exitTime,
      pnl: pnl ?? this.pnl,
      isWin: isWin ?? this.isWin,
      type: type,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  Map<String, dynamic> toJson() => {
        "isBuy": isBuy,
        "entry": entry,
        "stopLoss": stopLoss,
        "takeProfit": takeProfit,
        "lotSize": lotSize,
        "entryTime": entryTime.toIso8601String(),
        "exitPrice": exitPrice,
        "exitTime": exitTime?.toIso8601String(),
        "pnl": pnl,
        "isWin": isWin,
        "type": type,
        "isOpen": isOpen,
      };

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      isBuy: json["isBuy"],
      entry: json["entry"],
      stopLoss: json["stopLoss"],
      takeProfit: json["takeProfit"],
      lotSize: json["lotSize"],
      entryTime: DateTime.parse(json["entryTime"]),
      exitPrice: json["exitPrice"],
      exitTime:
          json["exitTime"] != null ? DateTime.parse(json["exitTime"]) : null,
      pnl: json["pnl"],
      isWin: json["isWin"],
      type: json["type"],
      isOpen: json["isOpen"],
    );
  }
}
