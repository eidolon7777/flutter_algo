import '../models/ohlc.dart';
import 'trading_strategy.dart';

class BuyAndHoldStrategy extends TradingStrategy {
  @override
  List<TradeSignal> generateSignals(List<OHLC> data) {
    if (data.isEmpty) return [];
    return [
      TradeSignal(data.first.date, 'BUY', data.first.close),
      TradeSignal(data.last.date, 'SELL', data.last.close),
    ];
  }
}