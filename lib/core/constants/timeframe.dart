import '../../signal_engine/model/timeframe.dart';

String mapTimeFrameToBinance(Timeframe tf) {
    switch (tf) {
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
      default:
        return '1h';
    }
  }

  String mapTimeFrameForChart(Timeframe tf) {
    switch (tf) {
      case Timeframe.m5:
        return '300';
      case Timeframe.m15:
        return '900';
      case Timeframe.m30:
        return '1800';
      case Timeframe.h1:
        return '3600';
      case Timeframe.h4:
        return '14400';
      case Timeframe.d1:
        return '86400';
      default:
        return '3600';
    }
  }