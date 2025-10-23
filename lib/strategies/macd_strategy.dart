import '../models/ohlc.dart';
import 'trading_strategy.dart';

class MacdStrategy extends TradingStrategy {
  final int fast; // e.g., 12
  final int slow; // e.g., 26
  final int signal; // e.g., 9

  MacdStrategy({this.fast = 12, this.slow = 26, this.signal = 9})
      : assert(fast > 0),
        assert(slow > fast),
        assert(signal > 0);

  @override
  List<TradeSignal> generateSignals(List<OHLC> data) {
    if (data.length < slow + signal + 1) return [];
    final closes = data.map((d) => d.close).toList();
    final emaFast = _ema(closes, fast);
    final emaSlow = _ema(closes, slow);
    final macd = List<double>.generate(closes.length, (i) => emaFast[i] - emaSlow[i]);
    final sig = _ema(macd, signal);

    List<TradeSignal> signals = [];
    bool inPosition = false;

    for (int i = slow + signal; i < data.length; i++) {
      final prevMacd = macd[i - 1];
      final prevSig = sig[i - 1];
      final currMacd = macd[i];
      final currSig = sig[i];

      final crossUp = prevMacd <= prevSig && currMacd > currSig; // BUY
      final crossDown = prevMacd >= prevSig && currMacd < currSig; // SELL

      if (crossUp && !inPosition) {
        signals.add(TradeSignal(data[i].date, 'BUY', data[i].close));
        inPosition = true;
      } else if (crossDown && inPosition) {
        signals.add(TradeSignal(data[i].date, 'SELL', data[i].close));
        inPosition = false;
      }
    }

    return signals;
  }

  List<double> _ema(List<double> v, int w) {
    final List<double> out = List.filled(v.length, 0.0);
    final k = 2 / (w + 1);
    out[0] = v[0];
    for (int i = 1; i < v.length; i++) {
      out[i] = v[i] * k + out[i - 1] * (1 - k);
    }
    return out;
  }
}