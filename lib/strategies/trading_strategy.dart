import '../models/ohlc.dart';

class TradeSignal {
  final DateTime time;
  final String action; // 'BUY' or 'SELL'
  final double price;
  TradeSignal(this.time, this.action, this.price);
}

abstract class TradingStrategy {
  List<TradeSignal> generateSignals(List<OHLC> data);
}