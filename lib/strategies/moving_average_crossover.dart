import '../models/ohlc.dart';
import 'trading_strategy.dart';

class MovingAverageCrossoverStrategy extends TradingStrategy {
  final int shortWindow;
  final int longWindow;

  MovingAverageCrossoverStrategy(this.shortWindow, this.longWindow)
      : assert(shortWindow > 0),
        assert(longWindow > shortWindow);

  @override
  List<TradeSignal> generateSignals(List<OHLC> data) {
    if (data.length < longWindow) return [];

    // Precompute moving averages
    final List<double> shortMA = _movingAverage(data.map((d) => d.close).toList(), shortWindow);
    final List<double> longMA = _movingAverage(data.map((d) => d.close).toList(), longWindow);

    List<TradeSignal> signals = [];
    bool inPosition = false;

    // Start from longWindow index so both MAs are defined
    for (int i = longWindow; i < data.length; i++) {
      final sPrev = shortMA[i - 1];
      final lPrev = longMA[i - 1];
      final sCurr = shortMA[i];
      final lCurr = longMA[i];

      // Detect crossovers
      final crossedUp = sPrev <= lPrev && sCurr > lCurr; // BUY
      final crossedDown = sPrev >= lPrev && sCurr < lCurr; // SELL

      if (crossedUp && !inPosition) {
        signals.add(TradeSignal(data[i].date, 'BUY', data[i].close));
        inPosition = true;
      } else if (crossedDown && inPosition) {
        signals.add(TradeSignal(data[i].date, 'SELL', data[i].close));
        inPosition = false;
      }
    }

    return signals;
  }

  List<double> _movingAverage(List<double> values, int window) {
    final List<double> ma = List.filled(values.length, double.nan);
    double sum = 0;
    for (int i = 0; i < values.length; i++) {
      sum += values[i];
      if (i >= window) {
        sum -= values[i - window];
      }
      if (i >= window - 1) {
        ma[i] = sum / window;
      }
    }
    return ma;
  }
}