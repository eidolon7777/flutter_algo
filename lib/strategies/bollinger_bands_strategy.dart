import 'dart:math' as math;
import '../models/ohlc.dart';
import 'trading_strategy.dart';

class BollingerBandsStrategy extends TradingStrategy {
  final int window; // e.g., 20
  final double k; // e.g., 2 standard deviations

  BollingerBandsStrategy({this.window = 20, this.k = 2.0}) : assert(window > 1), assert(k > 0);

  @override
  List<TradeSignal> generateSignals(List<OHLC> data) {
    if (data.length < window + 1) return [];
    final closes = data.map((d) => d.close).toList();
    final sma = _sma(closes, window);
    final std = _stddev(closes, window);

    List<TradeSignal> signals = [];
    bool inPosition = false;

    for (int i = window; i < data.length; i++) {
      final m = sma[i];
      final s = std[i];
      if (m.isNaN || s.isNaN) continue;
      final upper = m + k * s;
      final lower = m - k * s;
      final price = closes[i];

      final touchLower = price < lower; // BUY
      final touchUpper = price > upper; // SELL

      if (touchLower && !inPosition) {
        signals.add(TradeSignal(data[i].date, 'BUY', data[i].close));
        inPosition = true;
      } else if (touchUpper && inPosition) {
        signals.add(TradeSignal(data[i].date, 'SELL', data[i].close));
        inPosition = false;
      }
    }

    return signals;
  }

  List<double> _sma(List<double> v, int w) {
    final List<double> out = List.filled(v.length, double.nan);
    double sum = 0;
    for (int i = 0; i < v.length; i++) {
      sum += v[i];
      if (i >= w) sum -= v[i - w];
      if (i >= w - 1) out[i] = sum / w;
    }
    return out;
  }

  List<double> _stddev(List<double> v, int w) {
    final List<double> out = List.filled(v.length, double.nan);
    double sum = 0, sumSq = 0;
    for (int i = 0; i < v.length; i++) {
      sum += v[i];
      sumSq += v[i] * v[i];
      if (i >= w) {
        sum -= v[i - w];
        sumSq -= v[i - w] * v[i - w];
      }
      if (i >= w - 1) {
        final mean = sum / w;
        final meanSq = sumSq / w;
        final variance = meanSq - mean * mean;
        out[i] = variance <= 0 ? 0 : math.sqrt(variance);
      }
    }
    return out;
  }
}