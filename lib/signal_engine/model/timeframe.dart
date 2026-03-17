enum Timeframe {
 
  m5,
  m15,
  m30,
  h1,
  h4,
  d1,
  w1,
}
extension TimeframeExtension on Timeframe {
  String get label => name.toUpperCase();
  String get apiValue {
    switch (this) {
      case Timeframe.m5:
        return '5';
      case Timeframe.m15:
        return '15';
      case Timeframe.m30:
        return '30';
      case Timeframe.h1:
        return '1';
      case Timeframe.h4:
        return '4';
      case Timeframe.d1:
        return '1';
      case Timeframe.w1:
        return '1';
    }
  }
  String get displayName {
    switch (this) {
      case Timeframe.m5:
        return 'minute';
      case Timeframe.m15:
        return 'minute';
      case Timeframe.m30:
        return 'minute';
      case Timeframe.h1:
        return 'hour';
      case Timeframe.h4:
        return 'hour';
      case Timeframe.d1:
        return 'day';
      case Timeframe.w1:
        return 'week';
    }
  }
  String get name {
    switch (this) {
      case Timeframe.m5:
        return '5m';
      case Timeframe.m15:
        return '15m';
      case Timeframe.m30:
        return '30m';
      case Timeframe.h1:
        return '1h';
      case Timeframe.h4:
        return '4h';
      case Timeframe.d1:
        return '1d';
      case Timeframe.w1:
        return '1w';
    }
  }
}