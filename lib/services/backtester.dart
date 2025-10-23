import '../models/ohlc.dart';
import '../strategies/trading_strategy.dart';

class TradeResult {
  final DateTime buyTime;
  final double buyPrice;
  final DateTime sellTime;
  final double sellPrice;
  final double returnRatio; // sell / buy
  TradeResult({
    required this.buyTime,
    required this.buyPrice,
    required this.sellTime,
    required this.sellPrice,
    required this.returnRatio,
  });
}

class BacktestResult {
  final double initialBalance;
  final double finalBalance;
  final double profit;
  final double roiPercent; // (final / initial - 1) * 100
  final int trades;
  final double winRatePercent; // % of trades with returnRatio > 1
  final double maxDrawdownPercent; // based on equity after each trade
  final List<TradeResult> tradeResults;
  final double buyAndHoldFinalBalance;
  final double buyAndHoldRoiPercent;

  BacktestResult({
    required this.initialBalance,
    required this.finalBalance,
    required this.profit,
    required this.roiPercent,
    required this.trades,
    required this.winRatePercent,
    required this.maxDrawdownPercent,
    required this.tradeResults,
    required this.buyAndHoldFinalBalance,
    required this.buyAndHoldRoiPercent,
  });
}

class Backtester {
  double initialBalance;
  Backtester({this.initialBalance = 10000});

  BacktestResult run(List<OHLC> data, TradingStrategy strategy) {
    final signals = strategy.generateSignals(data);
    double balance = initialBalance;
    double? positionPrice;
    DateTime? buyTime;
    final List<TradeResult> results = [];

    // Iterate signals and simulate trades
    for (final s in signals) {
      if (s.action == 'BUY' && positionPrice == null) {
        positionPrice = s.price;
        buyTime = s.time;
      } else if (s.action == 'SELL' && positionPrice != null) {
        final ratio = s.price / positionPrice;
        balance *= ratio;
        results.add(TradeResult(
          buyTime: buyTime!,
          buyPrice: positionPrice,
          sellTime: s.time,
          sellPrice: s.price,
          returnRatio: ratio,
        ));
        positionPrice = null;
        buyTime = null;
      }
    }

    // Compute metrics
    final trades = results.length;
    final wins = results.where((r) => r.returnRatio > 1.0).length;
    final winRatePercent = trades == 0 ? 0.0 : (wins / trades) * 100.0;

    // Max drawdown using equity after each completed trade
    double peak = initialBalance;
    double maxDd = 0.0;
    double eq = initialBalance;
    for (final r in results) {
      eq *= r.returnRatio;
      if (eq > peak) peak = eq;
      final dd = (peak - eq) / peak; // in fraction
      if (dd > maxDd) maxDd = dd;
    }
    final maxDrawdownPercent = maxDd * 100.0;

    // Buy-and-hold baseline from first to last close
    final firstClose = data.first.close;
    final lastClose = data.last.close;
    final buyHoldFinal = initialBalance * (lastClose / firstClose);
    final buyHoldRoi = (buyHoldFinal / initialBalance - 1.0) * 100.0;

    final finalBalance = balance;
    final profit = finalBalance - initialBalance;
    final roiPercent = (finalBalance / initialBalance - 1.0) * 100.0;

    return BacktestResult(
      initialBalance: initialBalance,
      finalBalance: finalBalance,
      profit: profit,
      roiPercent: roiPercent,
      trades: trades,
      winRatePercent: winRatePercent,
      maxDrawdownPercent: maxDrawdownPercent,
      tradeResults: results,
      buyAndHoldFinalBalance: buyHoldFinal,
      buyAndHoldRoiPercent: buyHoldRoi,
    );
  }
}