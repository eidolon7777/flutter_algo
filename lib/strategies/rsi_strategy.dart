import '../models/ohlc.dart';
import 'trading_strategy.dart';

class RsiStrategy extends TradingStrategy {
  final int period; // e.g., 14
  final double oversold; // e.g., 30
  final double overbought; // e.g., 70

  RsiStrategy({this.period = 14, this.oversold = 30, this.overbought = 70})
      : assert(period > 1),
        assert(oversold < overbought);

  @override
  List<TradeSignal> generateSignals(List<OHLC> data) {
    if (data.length < period + 2) return [];
    final closes = data.map((d) => d.close).toList();
    final rsi = _computeRsi(closes, period);

    List<TradeSignal> signals = [];
    bool inPosition = false;

    for (int i = 1; i < data.length; i++) {
      final prev = rsi[i - 1];
      final curr = rsi[i];
      if (prev == null || curr == null) continue;

      final crossUpFromOversold = prev <= oversold && curr > oversold; // BUY
      final crossDownFromOverbought = prev >= overbought && curr < overbought; // SELL

      if (crossUpFromOversold && !inPosition) {
        signals.add(TradeSignal(data[i].date, 'BUY', data[i].close));
        inPosition = true;
      } else if (crossDownFromOverbought && inPosition) {
        signals.add(TradeSignal(data[i].date, 'SELL', data[i].close));
        inPosition = false;
      }
    }

    return signals;
  }

  List<double?> _computeRsi(List<double> closes, int period) {
    final List<double?> rsi = List.filled(closes.length, null);
    double gainSum = 0.0, lossSum = 0.0;
    for (int i = 1; i <= period; i++) {
      final change = closes[i] - closes[i - 1];
      if (change >= 0) {
        gainSum += change;
      } else {
        lossSum += -change;
      }
    }
    double avgGain = gainSum / period;
    double avgLoss = lossSum / period;
    rsi[period] = _rsiFromAvg(avgGain, avgLoss);

    for (int i = period + 1; i < closes.length; i++) {
      final change = closes[i] - closes[i - 1];
      final gain = change > 0 ? change : 0.0;
      final loss = change < 0 ? -change : 0.0;
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
      rsi[i] = _rsiFromAvg(avgGain, avgLoss);
    }
    return rsi;
  }

  double _rsiFromAvg(double avgGain, double avgLoss) {
    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1.0 + rs));
  }
}