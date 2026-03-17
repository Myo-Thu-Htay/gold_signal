class EntryZone {
  final double min;
  final double max;

  EntryZone(this.min, this.max);

  bool contains(double price) {
    return price >= min && price <= max;
  }

  double get center => (min + max) / 2;

  Map<String, double> toJson() => {'min': min, 'max': max};

  factory EntryZone.fromJson(Map<String, double> json) {
    return EntryZone(json['min']!, json['max']!);
  }
}
