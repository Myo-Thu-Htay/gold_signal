class EntryZone {
  final double min;
  final double max;
  final bool isBuy;
  EntryZone(this.min, this.max, this.isBuy);

  bool contains(double price) {
    return price >= min && price <= max;
  }

  double get center => (min + max) / 2;

  Map<String, dynamic> toJson() => {'min': min, 'max': max, 'isBuy': isBuy};

  factory EntryZone.fromJson(Map<String, dynamic> json) {
    return EntryZone((json['min'] as num).toDouble(),
        (json['max'] as num).toDouble(), json['isBuy'] as bool);
  }
}

class EntryResult {
  final bool isValid;
  final bool isBuy;
  final double entry;
  final double sl;
  final double tp;
  final String reason;
  final EntryZone? zone;
  EntryResult({
    required this.isValid,
    required this.isBuy,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.reason,
    this.zone,
  });
}
